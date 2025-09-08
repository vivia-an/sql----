

  -- 患者入院8小时内查房率指标（按月统计）
  -- 计算公式：入院8小时内开具检查或治疗医嘱的患者人次数/同期入院患者总人次数×100%
  -- 分子：入院8小时内开具医嘱的患者
  -- 分母：所有出院患者

  WITH
  -- 基础住院患者数据（分母）
  base_inpatients AS (
      SELECT
          DATE_FORMAT(CAST(Visit_IPReg_InHospDtTm AS TIMESTAMP), '%Y-%m') AS "统计月份",
          Visit_IPReg_VisitID,
          CAST(Visit_IPReg_InHospDtTm AS TIMESTAMP) AS "入院时间",
          CAST(Visit_IPReg_OutHospDtTm AS TIMESTAMP) AS "出院时间",
          Visit_IPReg_InHospDeptName AS "入院科室名称"
      FROM datacenter_db.Visit_IPReg
      WHERE Visit_IPReg_OutHospDtTm IS NOT NULL  -- 已出院患者
          AND Visit_IPReg_IsDeleted = '0'        -- 逻辑删除筛选
          AND Visit_IPReg_InHospDtTm IS NOT NULL -- 入院时间不为空
  ),

  -- 医嘱数据（检查或治疗医嘱）
  order_records AS (
      SELECT
          Order_Main_VisitID,
          CAST(Order_Main_OrderDtTm AS TIMESTAMP) AS "开医嘱时间",
          Order_Main_OrderPClassName AS "医嘱大类名称",
          Order_Main_OrderTypeName AS "医嘱类型名称",
          Order_Main_ApplyTypeName AS "申请单类型名称"
      FROM datacenter_db.Order_Main
      WHERE Order_Main_IsDeleted = '0'
          AND Order_Main_OrderDtTm IS NOT NULL
          -- 筛选检查或治疗医嘱（排除药品医嘱）
          AND (
              Order_Main_OrderPClassName LIKE '%检查%'
              OR Order_Main_OrderPClassName LIKE '%治疗%'
              OR Order_Main_OrderTypeName LIKE '%检查%'
              OR Order_Main_OrderTypeName LIKE '%治疗%'
              OR Order_Main_ApplyTypeName IN (
                  '拍片申请单', '病理科申请单', '内镜室申请单', '心电图室申请单',
                  '肺功能申请单', '检验科申请单', 'MRI申请单', 'CT申请单',
                  '细胞室申请单', '核医学申请单', '钼靶申请单', '超声波申请单'
              )
          )
  ),

  -- 8小时内开具医嘱的患者（分子）
  orders_within_8h AS (
      SELECT DISTINCT
          b."统计月份",
          b.Visit_IPReg_VisitID
      FROM base_inpatients b
      INNER JOIN order_records o ON b.Visit_IPReg_VisitID = o.Order_Main_VisitID
      WHERE
          -- 8小时内开具医嘱：开医嘱时间-入院时间 <= 8小时
          DATE_DIFF('hour', b."入院时间", o."开医嘱时间") <= 8
          AND DATE_DIFF('hour', b."入院时间", o."开医嘱时间") >= 0  -- 开医嘱时间不能早于入院时间      
  ),

  -- 按月统计
  monthly_stats AS (
      SELECT
          b."统计月份",
          COUNT(DISTINCT b.Visit_IPReg_VisitID) AS "同期入院患者总人次数",
          COUNT(DISTINCT o8.Visit_IPReg_VisitID) AS "入院8小时内开具医嘱患者人次数"
      FROM base_inpatients b
      LEFT JOIN orders_within_8h o8 ON b."统计月份" = o8."统计月份"
                                    AND b.Visit_IPReg_VisitID = o8.Visit_IPReg_VisitID
      GROUP BY b."统计月份"
  )

  -- 最终结果
  SELECT
      "统计月份",
      "入院8小时内开具医嘱患者人次数" AS "分子",
      "同期入院患者总人次数" AS "分母",
      CASE
          WHEN "同期入院患者总人次数" > 0 THEN
              ROUND(
                  CAST("入院8小时内开具医嘱患者人次数" AS DOUBLE) /
                  CAST("同期入院患者总人次数" AS DOUBLE) * 100,
                  2
              )
          ELSE 0
      END AS "患者入院8小时内查房率(%)"
  FROM monthly_stats
  ORDER BY "统计月份" DESC;


   SQL说明

  核心逻辑：
  1. 分母计算：统计每月所有出院患者总人次数（与转科指标相同基准）
  2. 分子计算：统计每月入院8小时内开具检查或治疗医嘱的患者人次数

  关键技术要点：
  - 使用DATE_DIFF('hour', 入院时间, 开医嘱时间) <= 8计算8小时内开具医嘱
  - 通过医嘱大类名称、医嘱类型名称、申请单类型名称筛选检查和治疗医嘱
  - 排除纯药品医嘱，专注于检查和治疗相关医嘱
  - 中文字段名使用双引号包围适配Presto语法

  数据血缘来源：
  - Visit_IPReg: 入院时间、出院时间、就诊ID（分母数据）
  - Order_Main: 开医嘱时间、医嘱分类、申请单类型（分子数据）
  - 筛选条件: 检查/治疗医嘱类型，8小时时间窗口

  医嘱类型识别逻辑：
  - 通过医嘱大类/类型名称包含"检查"、"治疗"关键字
  - 通过申请单类型识别具体检查项目（CT、MRI、超声、检验等）
  - 确保统计的是查房相关的医疗活动，体现查房及时性