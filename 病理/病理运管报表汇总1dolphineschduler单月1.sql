---- create view m1.om_bl_report_single_month as  
-- 病理运管报表汇总 - 单月查询版本
-- 使用说明：将 ${month} 替换为需要查询的月份，格式为 'yyyy-MM'，如 '2024-11'
-- 
-- ==================== 血缘依赖说明 ====================
-- 数据来源表：
-- 1. hid0101_mssql_bl_rep.t_jcxx - 检查信息表（主院区、上锦院区检查治疗人次）
--    关键字段：f_blk(病理类型), f_bgzt(报告状态), f_sdrq(送达日期), isdeleted
-- 2. m1.mdr_income_20251113 - 收入表（各院区检查治疗收入、穿刺中心收入）
--    关键字段：TotalFee(费用), RecDeptName(执行科室), chargedttm(计费时间), OrderName(项目名称)
-- 3. m1.mdr_peisincome - 体检收入表（各院区体检病理收入）
--    关键字段：qty(数量), FactPrice(实际价格), examfeeitem_name(项目名称), dateregister(登记日期), medorgcode(机构编码)
-- 4. datacenter_db.inventory_del_dets - 材料领用表（主院区材料试剂费）
--    关键字段：amountmoney(金额), hosp_code(医院编码), dept_name(科室名称), del_date(领用日期)
-- 5. hid0117_mysql_bl_pis.pathology - 天府病理系统表（天府院区检查治疗人次）
--    关键字段：receive_at(接收时间), library_detail_id(病理类型ID), library_id, deleted_at

-- WITH month_range AS (
--   SELECT
--     '${month}' AS month_label,
--     '${month}' || '-01 00:00:00' AS start_date,
--     FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_PARSE('${month}' || '-01', '%Y-%m-%d')), 'yyyy-MM-dd') || ' 23:59:59' AS end_date,
--     '${month}' AS month_label_presto
-- ),
WITH month_range AS (
  SELECT
    '$[yyyy-MM-1]' AS month_label,
    '$[yyyy-MM-1]' || '-01 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_PARSE('$[yyyy-MM-1]' || '-01', '%Y-%m-%d')), 'yyyy-MM-dd') || ' 23:59:59' AS end_date,
    '$[yyyy-MM-1]' AS month_label_presto
),

-- ==================== 主院区部分 ====================

-- 检查治疗人次/项次（主院区）
-- 来源：hid0101_mssql_bl_rep.t_jcxx
-- 筛选：f_blk 为主院区/锦江相关病理类型, f_bgzt='已审核'
main_count AS (
  SELECT COUNT(1) AS count_value 
  FROM hid0101_mssql_bl_rep.t_jcxx, month_range
  WHERE f_blk IN ('普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规','锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规') 
    AND f_bgzt = '已审核' 
    AND f_sdrq >= start_date 
    AND f_sdrq <= end_date
    AND isdeleted = '0'
),

-- 检查治疗收入（主院区）
-- 来源：m1.mdr_income
-- 筛选：RecDeptName IN ('病理科','锦江病理科','温江病理科','天府病理科')
main_income AS (
  SELECT SUM(TotalFee) AS income_value 
  FROM m1.mdr_income_20251113, month_range
  WHERE RecDeptName IN ('病理科','锦江病理科','温江病理科','天府病理科')
    AND SUBSTRING(chargedttm, 1, 7) = month_label
),

-- 穿刺中心收入（主院区）
-- 来源：m1.mdr_income
-- 筛选：RecDeptName IN ('穿刺诊疗中心', '锦江穿刺诊疗中心'), OrderName为指定穿刺项目
main_puncture AS (
  SELECT SUM(TotalFee) AS income_value 
  FROM m1.mdr_income_20251113, month_range
  WHERE RecDeptName IN ('穿刺诊疗中心', '锦江穿刺诊疗中心')
    AND OrderName IN (
        '淋巴结细针穿刺检查','皮下包块细针穿刺检查','乳腺肿物穿刺活检术(细针)',
        '脱落细胞学检查与诊断(涂片)','细针穿刺细胞学检查与诊断(细胞块)',
        '细针穿刺细胞学检查与诊断(涂片)'
    )
    AND SUBSTRING(chargedttm, 1, 7) = month_label
),

-- 体检收入（主院区）
-- 来源：m1.mdr_peisincome
-- 筛选：medorgcode IN ('HID0101','HID0118','F0017','F0002')
main_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome, month_range
    WHERE f_feecharged IN ('AQ==','true','1')  
      AND (f_regreturned = 'false' OR f_regreturned = 'AA==' OR f_regreturned IS NULL) 
      AND f_registered IN ('AQ==','true','ARRIVED') 
      AND examfeeitem_name IN (
        '宫颈刮片病理细胞学检查','宫颈刮片病理细胞学检查【HPV】','液基薄层细胞学检查',
        '液基薄层细胞学检查【加HPV】','尿液基细胞学检测','液基薄层细胞制片术',
        '肠癌无创脱落细胞多靶点基因检测','液基薄层细胞学检查【加HPV，加白带常规】',
        '两癌筛查【HPV+白带】','两癌筛查液基薄层细胞制片术','两癌筛查组织病理学检查',
        '两癌筛查妇科','两癌筛查妇科【HPV+白带】','两癌筛查妇科【液基】',
        '两癌筛查组织病理学检查【需取组织检查才用条码】','液基薄层细胞学检查【加白带常规】',
        '体检液基薄层细胞制片术','液基薄层细胞制片术','液基薄层细胞学检查（HPV）（体检）'
      )
      AND SUBSTRING(dateregister, 1, 7) = month_label_presto
      AND medorgcode IN ('HID0101','HID0118','F0017','F0002')
  ) t1
),

-- 领用材料试剂费（主院区）
-- 来源：datacenter_db.inventory_del_dets
-- 筛选：hosp_code = 'HID0101', dept_name LIKE '%病理科%'
main_material AS (
  SELECT SUM(CAST("amountmoney" AS DOUBLE)) AS cost_value 
  FROM datacenter_db.inventory_del_dets, month_range
  WHERE "hosp_code" = 'HID0101' 
    AND "dept_name" LIKE '%病理科%'
    AND SUBSTRING("del_date", 1, 7) = month_label
    AND isdeleted = '0'
),

-- ==================== 上锦院区部分 ====================

-- 检查治疗人次/项次（上锦）
-- 来源：hid0101_mssql_bl_rep.t_jcxx
-- 筛选：f_blk 为上锦相关病理类型
sj_count AS (
  SELECT COUNT(1) AS count_value 
  FROM hid0101_mssql_bl_rep.t_jcxx, month_range
  WHERE f_blk IN ('上锦普通外检','上锦加快','上锦冰冻','上锦术后石蜡','上锦尸解','上锦细胞学','上锦细针','上锦体检','上锦外院会诊','上锦肝穿','上锦肾穿','上锦骨髓','上锦淋巴结','上锦眼科','上锦肌肉','上锦前列腺','上锦ESD','上锦电镜','上锦心肌','上锦普通会诊加急','上锦普通会诊常规')  
    AND f_bgzt = '已审核' 
    AND f_sdrq >= start_date 
    AND f_sdrq <= end_date
    AND isdeleted = '0'
),

-- 检查治疗收入（上锦）
-- 来源：m1.mdr_income
-- 筛选：RecDeptName = '病理科(上锦)'
sj_income AS (
  SELECT SUM(TotalFee) AS income_value 
  FROM m1.mdr_income_20251113, month_range
  WHERE RecDeptName = '病理科(上锦)'
    AND SUBSTRING(chargedttm, 1, 7) = month_label
),

-- 体检收入（上锦）
-- 来源：m1.mdr_peisincome
-- 筛选：medorgcode IN ('HID0103')
sj_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome, month_range
    WHERE ((f_feecharged = 'AQ==') OR f_feecharged = 'true')
      AND examfeeitem_name IN (
        '宫颈刮片病理细胞学检查','宫颈刮片病理细胞学检查【HPV】','液基薄层细胞学检查',
        '液基薄层细胞学检查【加HPV】','尿液基细胞学检测','液基薄层细胞制片术',
        '肠癌无创脱落细胞多靶点基因检测','液基薄层细胞学检查【加HPV，加白带常规】',
        '两癌筛查【HPV+白带】','两癌筛查液基薄层细胞制片术','两癌筛查组织病理学检查',
        '两癌筛查妇科','两癌筛查妇科【HPV+白带】','两癌筛查妇科【液基】',
        '两癌筛查组织病理学检查【需取组织检查才用条码】','液基薄层细胞学检查【加白带常规】',
        '体检液基薄层细胞制片术','液基薄层细胞制片术','液基薄层细胞学检查（HPV）（体检）'
      )
      AND SUBSTRING(dateregister, 1, 7) = month_label_presto
      AND medorgcode IN ('HID0103')
  ) t1
),

-- ==================== 天府院区部分 ====================

-- 检查治疗人次/项次（天府）
-- 来源：hid0117_mysql_bl_pis.pathology
-- 筛选：deleted_at IS NULL, library_id NOT IN 排除类型
tf_count AS (
  SELECT COUNT(1) AS count_value FROM (
    SELECT "pathology"."receive_at" AS "接收时间"
    FROM hid0117_mysql_bl_pis."pathology", month_range
    WHERE "pathology"."deleted_at" IS NULL
      AND "pathology"."library_id" NOT IN ('39', '40', '41', '60', '67', '68', '69', '77', '18')
      AND "pathology"."receive_at" >= start_date
      AND "pathology"."receive_at" <= end_date
  ) sub
),

-- 检查治疗收入（天府）
-- 来源：m1.mdr_income
-- 筛选：RecDeptName = '病理科(天府)'
tf_income AS (
  SELECT SUM(TotalFee) AS income_value 
  FROM m1.mdr_income_20251113, month_range
  WHERE RecDeptName = '病理科(天府)'
    AND SUBSTRING(chargedttm, 1, 7) = month_label
),

-- 体检收入（天府）
-- 来源：m1.mdr_peisincome
-- 筛选：medorgcode IN ('HID0117')
tf_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome, month_range
    WHERE ((f_feecharged = 'AQ==') OR f_feecharged = 'true')
      AND examfeeitem_name IN (
        '宫颈刮片病理细胞学检查','宫颈刮片病理细胞学检查【HPV】','液基薄层细胞学检查',
        '液基薄层细胞学检查【加HPV】','尿液基细胞学检测','液基薄层细胞制片术',
        '肠癌无创脱落细胞多靶点基因检测','液基薄层细胞学检查【加HPV，加白带常规】',
        '两癌筛查【HPV+白带】','两癌筛查液基薄层细胞制片术','两癌筛查组织病理学检查',
        '两癌筛查妇科','两癌筛查妇科【HPV+白带】','两癌筛查妇科【液基】',
        '两癌筛查组织病理学检查【需取组织检查才用条码】','液基薄层细胞学检查【加白带常规】',
        '体检液基薄层细胞制片术','液基薄层细胞制片术','液基薄层细胞学检查（HPV）（体检）'
      )
      AND SUBSTRING(dateregister, 1, 7) = month_label_presto
      AND medorgcode IN ('HID0117')
  ) t1
),

-- ==================== 各院区汇总数据 ====================

-- 主院区结果
main_results AS (
  SELECT (SELECT month_label FROM month_range) AS "统计月", '主院区' AS "单位", '检查治疗人次/项次' AS "项目", 
    COALESCE((SELECT count_value FROM main_count), 0) AS "本月",
    CAST(0 AS DOUBLE) AS "上月",
    CAST(0 AS DOUBLE) AS "去年同期",
    CAST(0 AS DECIMAL(10,2)) AS "与上月差异%",
    CAST(0 AS DECIMAL(10,2)) AS "与同期差异%"
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '主院区', '检查治疗收入(元)', 
    COALESCE((SELECT income_value FROM main_income), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '主院区', '穿刺中心细胞病理收入(元)', 
    COALESCE((SELECT income_value FROM main_puncture), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '主院区', '本部温江第三方体检病理收入(元)', 
    COALESCE((SELECT income_value FROM main_physical), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '主院区', '其他收入(元)', 0, 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '主院区', '本部收入合计', 
    COALESCE((SELECT income_value FROM main_income), 0) + 
    COALESCE((SELECT income_value FROM main_puncture), 0) + 
    COALESCE((SELECT income_value FROM main_physical), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '主院区', '领用材料试剂费(元)', 
    COALESCE((SELECT cost_value FROM main_material), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '主院区', '领用材料试剂费占收入比例(%)',
    CASE 
      WHEN (COALESCE((SELECT income_value FROM main_income), 0) + 
            COALESCE((SELECT income_value FROM main_puncture), 0) + 
            COALESCE((SELECT income_value FROM main_physical), 0)) = 0 THEN 0
      ELSE ROUND((COALESCE((SELECT cost_value FROM main_material), 0) / 
                 (COALESCE((SELECT income_value FROM main_income), 0) + 
                  COALESCE((SELECT income_value FROM main_puncture), 0) + 
                  COALESCE((SELECT income_value FROM main_physical), 0))) * 100, 2)
    END, 0, 0, 0, 0
),

-- 上锦院区结果
sj_results AS (
  SELECT (SELECT month_label FROM month_range) AS "统计月", '上锦院区' AS "单位", '检查治疗人次/项次' AS "项目", 
    COALESCE((SELECT count_value FROM sj_count), 0) AS "本月",
    CAST(0 AS DOUBLE) AS "上月",
    CAST(0 AS DOUBLE) AS "去年同期",
    CAST(0 AS DECIMAL(10,2)) AS "与上月差异%",
    CAST(0 AS DECIMAL(10,2)) AS "与同期差异%"
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '上锦院区', '上锦检查治疗收入(元)', 
    COALESCE((SELECT income_value FROM sj_income), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '上锦院区', '上锦体检病理收入(元)', 
    COALESCE((SELECT income_value FROM sj_physical), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '上锦院区', '上锦收入合计', 
    COALESCE((SELECT income_value FROM sj_income), 0) + 
    COALESCE((SELECT income_value FROM sj_physical), 0), 0, 0, 0, 0
),

-- 天府院区结果
tf_results AS (
  SELECT (SELECT month_label FROM month_range) AS "统计月", '天府院区' AS "单位", '检查治疗人次/项次' AS "项目", 
    COALESCE((SELECT count_value FROM tf_count), 0) AS "本月",
    CAST(0 AS DOUBLE) AS "上月",
    CAST(0 AS DOUBLE) AS "去年同期",
    CAST(0 AS DECIMAL(10,2)) AS "与上月差异%",
    CAST(0 AS DECIMAL(10,2)) AS "与同期差异%"
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '天府院区', '天府检查治疗收入(元)', 
    COALESCE((SELECT income_value FROM tf_income), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '天府院区', '天府体检病理收入(元)', 
    COALESCE((SELECT income_value FROM tf_physical), 0), 0, 0, 0, 0
  UNION ALL
  SELECT (SELECT month_label FROM month_range), '天府院区', '天府收入合计', 
    COALESCE((SELECT income_value FROM tf_income), 0) + 
    COALESCE((SELECT income_value FROM tf_physical), 0), 0, 0, 0, 0
),

-- 合并所有院区数据
all_results AS (
  SELECT * FROM main_results
  UNION ALL
  SELECT * FROM sj_results
  UNION ALL
  SELECT * FROM tf_results
),

-- ==================== 合计部分 ====================

-- 检查治疗人次/项次总合计
total_count AS (
  SELECT 
    (SELECT month_label FROM month_range) AS "统计月",
    '合计' AS "单位",
    '检查治疗人次/项次合计' AS "项目",
    SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "本月" ELSE 0 END) AS "本月",
    CAST(0 AS DOUBLE) AS "上月",
    CAST(0 AS DOUBLE) AS "去年同期",
    CAST(0 AS DECIMAL(10,2)) AS "与上月差异%",
    CAST(0 AS DECIMAL(10,2)) AS "与同期差异%"
  FROM all_results
),

-- 总收入合计
total_income AS (
  SELECT 
    (SELECT month_label FROM month_range) AS "统计月",
    '合计' AS "单位",
    '总收入合计(元)' AS "项目",
    SUM(CASE 
          WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') 
          THEN "本月" 
          ELSE 0 
        END) AS "本月",
    CAST(0 AS DOUBLE) AS "上月",
    CAST(0 AS DOUBLE) AS "去年同期",
    CAST(0 AS DECIMAL(10,2)) AS "与上月差异%",
    CAST(0 AS DECIMAL(10,2)) AS "与同期差异%"
  FROM all_results
)

-- ==================== 最终输出 ====================
SELECT * FROM (
  SELECT 
    "统计月",
    "单位",
    "项目", 
    "本月",
    "上月",
    "去年同期",
    "与上月差异%",
    "与同期差异%",
    CASE "单位"
      WHEN '主院区' THEN 1
      WHEN '上锦院区' THEN 2
      WHEN '天府院区' THEN 3
      WHEN '合计' THEN 4
      ELSE 5
    END AS unit_order,
    CASE "项目"
      WHEN '检查治疗人次/项次' THEN 1
      WHEN '检查治疗收入(元)' THEN 2
      WHEN '穿刺中心细胞病理收入(元)' THEN 3
      WHEN '本部温江第三方体检病理收入(元)' THEN 4
      WHEN '其他收入(元)' THEN 5
      WHEN '本部收入合计' THEN 6
      WHEN '领用材料试剂费(元)' THEN 7
      WHEN '领用材料试剂费占收入比例(%)' THEN 8
      WHEN '上锦检查治疗收入(元)' THEN 2
      WHEN '上锦体检病理收入(元)' THEN 3
      WHEN '上锦收入合计' THEN 6
      WHEN '天府检查治疗收入(元)' THEN 2
      WHEN '天府体检病理收入(元)' THEN 3
      WHEN '天府收入合计' THEN 6
      WHEN '检查治疗人次/项次合计' THEN 9
      WHEN '总收入合计(元)' THEN 10
      ELSE 11
    END AS item_order
  FROM (
    SELECT * FROM all_results
    UNION ALL
    SELECT * FROM total_count
    UNION ALL
    SELECT * FROM total_income
  ) t
) result
ORDER BY unit_order, item_order
