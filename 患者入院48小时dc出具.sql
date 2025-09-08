● 基于您的澄清，我现在生成满足需求的Presto SQL：

  -- 患者入院48小时内转科比例指标（按月统计）
  -- 计算公式：入院48小时内转科患者人次数/同期入院患者总人次数×100%
  -- 排除：1.转入/转出ICU的情况 2.同科室内病区转移

  WITH
  -- 基础住院患者数据（分母）
  base_inpatients AS (
      SELECT
          DATE_FORMAT(CAST(Visit_IPReg_InHospDtTm AS TIMESTAMP), '%Y-%m') AS "统计月份",
          Visit_IPReg_VisitID,
          Visit_IPReg_InHospDtTm AS "入院时间",
          Visit_IPReg_OutHospDtTm AS "出院时间",
          Visit_IPReg_InHospDeptName AS "入院科室名称"
      FROM datacenter_db.Visit_IPReg
      WHERE Visit_IPReg_OutHospDtTm IS NOT NULL  -- 已出院患者
          AND Visit_IPReg_IsDeleted = '0'        -- 逻辑删除筛选
          AND Visit_IPReg_InHospDtTm IS NOT NULL -- 入院时间不为空
  ),

  -- 转科记录数据
  transdept_records AS (
      SELECT
          Visit_TransDept_VisitID,
          Visit_TransDept_TransInDeptDtTm AS "转入科室时间",
          Visit_TransDept_TransOutDeptName AS "转出科室名称",
          Visit_TransDept_DeptName AS "转入科室名称"
      FROM datacenter_db.Visit_TransDept
      WHERE Visit_TransDept_IsDeleted = '0'
          AND Visit_TransDept_TransInDeptDtTm IS NOT NULL
          AND Visit_TransDept_TransOutDeptName IS NOT NULL
          AND Visit_TransDept_DeptName IS NOT NULL
          -- 排除转入/转出ICU的情况
          AND Visit_TransDept_TransOutDeptName NOT LIKE '%重症%'
          AND Visit_TransDept_DeptName NOT LIKE '%重症%'
          -- 排除同科室转移（科室名称相同）
          AND Visit_TransDept_TransOutDeptName != Visit_TransDept_DeptName
  ),

  -- 48小时内转科患者（分子）
  transdept_within_48h AS (
      SELECT DISTINCT
          b."统计月份",
          b.Visit_IPReg_VisitID
      FROM base_inpatients b
      INNER JOIN transdept_records t ON b.Visit_IPReg_VisitID = t.Visit_TransDept_VisitID
      WHERE
          -- 48小时内转科：转科时间-入院时间 <= 48小时
          DATE_DIFF('hour', CAST(b."入院时间" AS TIMESTAMP), CAST(t."转入科室时间" AS TIMESTAMP)) <= 48
          AND DATE_DIFF('hour', CAST(b."入院时间" AS TIMESTAMP), CAST(t."转入科室时间" AS TIMESTAMP)) >= 0  -- 转科时间不能早于入院时间      
  ),

  -- 按月统计
  monthly_stats AS (
      SELECT
          b."统计月份",
          COUNT(DISTINCT b.Visit_IPReg_VisitID) AS "同期入院患者总人次数",
          COUNT(DISTINCT t48.Visit_IPReg_VisitID) AS "入院48小时内转科患者人次数"
      FROM base_inpatients b
      LEFT JOIN transdept_within_48h t48 ON b."统计月份" = t48."统计月份"
                                         AND b.Visit_IPReg_VisitID = t48.Visit_IPReg_VisitID
      GROUP BY b."统计月份"
  )

  -- 最终结果
  SELECT
      "统计月份",
      "入院48小时内转科患者人次数" AS "分子",
      "同期入院患者总人次数" AS "分母",
      CASE
          WHEN "同期入院患者总人次数" > 0 THEN
              ROUND(
                  CAST("入院48小时内转科患者人次数" AS DOUBLE) /
                  CAST("同期入院患者总人次数" AS DOUBLE) * 100,
                  2
              )
          ELSE 0
      END AS "患者入院48小时内转科比例(%)"
  FROM monthly_stats
  ORDER BY "统计月份" DESC;

● SQL说明

  核心逻辑：
  1. 分母计算：统计每月所有出院患者总人次数
  2. 分子计算：统计每月入院48小时内转科的患者人次数，排除以下情况：
    - 转入/转出包含"重症"关键字的科室
    - 同科室内转移（科室名称相同）

  关键技术要点：
  - 使用DATE_DIFF('hour', 入院时间, 转科时间) <= 48计算48小时内转科
  - 中文字段名使用双引号包围适配Presto语法
  - 使用CTE分步构建逻辑，提高可读性
  - 结果按统计月份降序排列，最新月份在前

  数据血缘来源：
  - Visit_IPReg: 入院时间、出院时间、就诊ID
  - Visit_TransDept: 转科时间、转出科室名称、转入科室名称
  - 过滤条件: IsDeleted = '0' 确保数据有效性
