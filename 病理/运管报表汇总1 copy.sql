---- create view m1.om_bl_report as  


select * from (
-- 病理收入统计报表 - 多期对比分析

WITH last_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

last_last_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

last_year_same_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

-- 本月检查治疗人次/项次
current_month_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_month_range
  WHERE f_blk IN ('锦江冰冻','冰冻','普通外检','加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'

),

-- 上月检查治疗人次/项次
last_month_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_last_month_range
  WHERE f_blk IN ('锦江冰冻','冰冻','普通外检','加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'

),

-- 去年同期检查治疗人次/项次
last_year_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_year_same_month_range
  WHERE f_blk IN ('锦江冰冻','冰冻','普通外检','加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'

),

-- 本月检查治疗收入
current_month_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName IN ('病理科','锦江病理科','温江病理科','天府病理科')
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM')
),

-- 上月检查治疗收入
last_month_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName IN ('病理科','锦江病理科','温江病理科','天府病理科')
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH), 'yyyy-MM')
),

-- 去年同期检查治疗收入
last_year_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName IN ('病理科','锦江病理科','温江病理科','天府病理科')
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH), 'yyyy-MM')
),

-- 本月穿刺中心收入
current_month_puncture AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName IN ('穿刺诊疗中心', '锦江穿刺诊疗中心')
    AND OrderName IN (
        '淋巴结细针穿刺检查','皮下包块细针穿刺检查','乳腺肿物穿刺活检术(细针)',
        '脱落细胞学检查与诊断(涂片)','细针穿刺细胞学检查与诊断(细胞块)',
        '细针穿刺细胞学检查与诊断(涂片)'
    )
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM')
),

-- 上月穿刺中心收入
last_month_puncture AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName IN ('穿刺诊疗中心', '锦江穿刺诊疗中心')
    AND OrderName IN (
        '淋巴结细针穿刺检查','皮下包块细针穿刺检查','乳腺肿物穿刺活检术(细针)',
        '脱落细胞学检查与诊断(涂片)','细针穿刺细胞学检查与诊断(细胞块)',
        '细针穿刺细胞学检查与诊断(涂片)'
    )
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH), 'yyyy-MM')
),

-- 去年同期穿刺中心收入
last_year_puncture AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName IN ('穿刺诊疗中心', '锦江穿刺诊疗中心')
    AND OrderName IN (
        '淋巴结细针穿刺检查','皮下包块细针穿刺检查','乳腺肿物穿刺活检术(细针)',
        '脱落细胞学检查与诊断(涂片)','细针穿刺细胞学检查与诊断(细胞块)',
        '细针穿刺细胞学检查与诊断(涂片)'
    )
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH), 'yyyy-MM')
),

-- 本月体检收入
current_month_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -1, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0101')
  ) t1
),

-- 上月体检收入
last_month_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -2, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0101')
  ) t2
),

-- 去年同期体检收入
last_year_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -13, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0101')
  ) t3
),

-- 最终结果汇总
final_results AS (
  -- 1. 检查治疗人次/项次
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '主院区' AS "单位",
    '检查治疗人次/项次' AS "项目",
    COALESCE((SELECT count_value FROM current_month_count), 0) AS "本月",
    COALESCE((SELECT count_value FROM last_month_count), 0) AS "上月",
    COALESCE((SELECT count_value FROM last_year_count), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT count_value FROM last_month_count), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT count_value FROM current_month_count), 0) - COALESCE((SELECT count_value FROM last_month_count), 0)) / COALESCE((SELECT count_value FROM last_month_count), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT count_value FROM last_year_count), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT count_value FROM current_month_count), 0) - COALESCE((SELECT count_value FROM last_year_count), 0)) / COALESCE((SELECT count_value FROM last_year_count), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 2. 检查治疗收入(元)
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '主院区' AS "单位",
    '检查治疗收入(元)' AS "项目",
    COALESCE((SELECT income_value FROM current_month_income), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_income), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_income), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_month_income), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_income), 0) - COALESCE((SELECT income_value FROM last_month_income), 0)) / COALESCE((SELECT income_value FROM last_month_income), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_year_income), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_income), 0) - COALESCE((SELECT income_value FROM last_year_income), 0)) / COALESCE((SELECT income_value FROM last_year_income), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 3. 穿刺中心细胞病理收入(元)
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '主院区' AS "单位",
    '穿刺中心细胞病理收入(元)' AS "项目",
    COALESCE((SELECT income_value FROM current_month_puncture), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_puncture), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_puncture), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_month_puncture), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_puncture), 0) - COALESCE((SELECT income_value FROM last_month_puncture), 0)) / COALESCE((SELECT income_value FROM last_month_puncture), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_year_puncture), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_puncture), 0) - COALESCE((SELECT income_value FROM last_year_puncture), 0)) / COALESCE((SELECT income_value FROM last_year_puncture), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 4. 本部温江第三方体检病理收入(元)
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '主院区' AS "单位",
    '本部温江第三方体检病理收入(元)' AS "项目",
    COALESCE((SELECT income_value FROM current_month_physical), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_physical), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_physical), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_month_physical), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_physical), 0) - COALESCE((SELECT income_value FROM last_month_physical), 0)) / COALESCE((SELECT income_value FROM last_month_physical), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_year_physical), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_physical), 0) - COALESCE((SELECT income_value FROM last_year_physical), 0)) / COALESCE((SELECT income_value FROM last_year_physical), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 5. 其他收入(元)
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '主院区' AS "单位",
    '其他收入(元)' AS "项目",
    0 AS "本月",
    0 AS "上月",
    0 AS "去年同期",
    NULL AS "与上月差异%",
    NULL AS "与同期差异%"
  
  UNION ALL
  
  -- 6. 本部收入合计
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '主院区' AS "单位",
    '本部收入合计' AS "项目",
    COALESCE((SELECT income_value FROM current_month_income), 0) + 
    COALESCE((SELECT income_value FROM current_month_puncture), 0) + 
    COALESCE((SELECT income_value FROM current_month_physical), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_income), 0) + 
    COALESCE((SELECT income_value FROM last_month_puncture), 0) + 
    COALESCE((SELECT income_value FROM last_month_physical), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_income), 0) + 
    COALESCE((SELECT income_value FROM last_year_puncture), 0) + 
    COALESCE((SELECT income_value FROM last_year_physical), 0) AS "去年同期",
    CASE 
      WHEN (COALESCE((SELECT income_value FROM last_month_income), 0) + 
            COALESCE((SELECT income_value FROM last_month_puncture), 0) + 
            COALESCE((SELECT income_value FROM last_month_physical), 0)) = 0 THEN NULL
      ELSE ROUND(((
        (COALESCE((SELECT income_value FROM current_month_income), 0) + 
         COALESCE((SELECT income_value FROM current_month_puncture), 0) + 
         COALESCE((SELECT income_value FROM current_month_physical), 0)) - 
        (COALESCE((SELECT income_value FROM last_month_income), 0) + 
         COALESCE((SELECT income_value FROM last_month_puncture), 0) + 
         COALESCE((SELECT income_value FROM last_month_physical), 0))
      ) / (COALESCE((SELECT income_value FROM last_month_income), 0) + 
           COALESCE((SELECT income_value FROM last_month_puncture), 0) + 
           COALESCE((SELECT income_value FROM last_month_physical), 0))) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN (COALESCE((SELECT income_value FROM last_year_income), 0) + 
            COALESCE((SELECT income_value FROM last_year_puncture), 0) + 
            COALESCE((SELECT income_value FROM last_year_physical), 0)) = 0 THEN NULL
      ELSE ROUND(((
        (COALESCE((SELECT income_value FROM current_month_income), 0) + 
         COALESCE((SELECT income_value FROM current_month_puncture), 0) + 
         COALESCE((SELECT income_value FROM current_month_physical), 0)) - 
        (COALESCE((SELECT income_value FROM last_year_income), 0) + 
         COALESCE((SELECT income_value FROM last_year_puncture), 0) + 
         COALESCE((SELECT income_value FROM last_year_physical), 0))
      ) / (COALESCE((SELECT income_value FROM last_year_income), 0) + 
           COALESCE((SELECT income_value FROM last_year_puncture), 0) + 
           COALESCE((SELECT income_value FROM last_year_physical), 0))) * 100, 2)
    END AS "与同期差异%"
)

-- 最终输出结果
SELECT * FROM final_results
ORDER BY 
  CASE "项目"
    WHEN '检查治疗人次/项次' THEN 1
    WHEN '检查治疗收入(元)' THEN 2
    WHEN '穿刺中心细胞病理收入(元)' THEN 3
    WHEN '本部温江第三方体检病理收入(元)' THEN 4
    WHEN '其他收入(元)' THEN 5
    WHEN '本部收入合计' THEN 6
    ELSE 7
  END


)

union all 


select * from (


-- 上锦病理收入统计报表 - 多期对比分析

WITH last_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

last_last_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

last_year_same_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

-- 本月检查治疗人次/项次（上锦）
current_month_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_month_range
  WHERE f_blk IN ('上锦锦江冰冻','上锦冰冻','上锦普通外检','上锦加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'
),

-- 上月检查治疗人次/项次（上锦）
last_month_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_last_month_range
  WHERE f_blk IN ('上锦锦江冰冻','上锦冰冻','上锦普通外检','上锦加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'
),

-- 去年同期检查治疗人次/项次（上锦）
last_year_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_year_same_month_range
  WHERE f_blk IN ('上锦锦江冰冻','上锦冰冻','上锦普通外检','上锦加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'
),

-- 本月检查治疗收入（上锦）
current_month_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName = '病理科(上锦)'
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM')
),

-- 上月检查治疗收入（上锦）
last_month_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName = '病理科(上锦)'
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH), 'yyyy-MM')
),

-- 去年同期检查治疗收入（上锦）
last_year_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName = '病理科(上锦)'
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH), 'yyyy-MM')
),

-- 本月体检收入（上锦）
current_month_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -1, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0103')
  ) t1
),

-- 上月体检收入（上锦）
last_month_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -2, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0103')
  ) t2
),

-- 去年同期体检收入（上锦）
last_year_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -13, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0103')
  ) t3
),

-- 最终结果汇总
final_results AS (
  -- 1. 检查治疗人次/项次（上锦）
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '上锦院区' AS "单位",
    '检查治疗人次/项次' AS "项目",
    COALESCE((SELECT count_value FROM current_month_count), 0) AS "本月",
    COALESCE((SELECT count_value FROM last_month_count), 0) AS "上月",
    COALESCE((SELECT count_value FROM last_year_count), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT count_value FROM last_month_count), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT count_value FROM current_month_count), 0) - COALESCE((SELECT count_value FROM last_month_count), 0)) / COALESCE((SELECT count_value FROM last_month_count), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT count_value FROM last_year_count), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT count_value FROM current_month_count), 0) - COALESCE((SELECT count_value FROM last_year_count), 0)) / COALESCE((SELECT count_value FROM last_year_count), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 2. 上锦检查治疗收入(元)
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '上锦院区' AS "单位",
    '上锦检查治疗收入(元)' AS "项目",
    COALESCE((SELECT income_value FROM current_month_income), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_income), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_income), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_month_income), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_income), 0) - COALESCE((SELECT income_value FROM last_month_income), 0)) / COALESCE((SELECT income_value FROM last_month_income), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_year_income), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_income), 0) - COALESCE((SELECT income_value FROM last_year_income), 0)) / COALESCE((SELECT income_value FROM last_year_income), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 3. 上锦体检病理收入(元)
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '上锦院区' AS "单位",
    '上锦体检病理收入(元)' AS "项目",
    COALESCE((SELECT income_value FROM current_month_physical), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_physical), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_physical), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_month_physical), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_physical), 0) - COALESCE((SELECT income_value FROM last_month_physical), 0)) / COALESCE((SELECT income_value FROM last_month_physical), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_year_physical), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_physical), 0) - COALESCE((SELECT income_value FROM last_year_physical), 0)) / COALESCE((SELECT income_value FROM last_year_physical), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 4. 上锦收入合计
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '上锦院区' AS "单位",
    '上锦收入合计' AS "项目",
    COALESCE((SELECT income_value FROM current_month_income), 0) + 
    COALESCE((SELECT income_value FROM current_month_physical), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_income), 0) + 
    COALESCE((SELECT income_value FROM last_month_physical), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_income), 0) + 
    COALESCE((SELECT income_value FROM last_year_physical), 0) AS "去年同期",
    CASE 
      WHEN (COALESCE((SELECT income_value FROM last_month_income), 0) + 
            COALESCE((SELECT income_value FROM last_month_physical), 0)) = 0 THEN NULL
      ELSE ROUND(((
        (COALESCE((SELECT income_value FROM current_month_income), 0) + 
         COALESCE((SELECT income_value FROM current_month_physical), 0)) - 
        (COALESCE((SELECT income_value FROM last_month_income), 0) + 
         COALESCE((SELECT income_value FROM last_month_physical), 0))
      ) / (COALESCE((SELECT income_value FROM last_month_income), 0) + 
           COALESCE((SELECT income_value FROM last_month_physical), 0))) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN (COALESCE((SELECT income_value FROM last_year_income), 0) + 
            COALESCE((SELECT income_value FROM last_year_physical), 0)) = 0 THEN NULL
      ELSE ROUND(((
        (COALESCE((SELECT income_value FROM current_month_income), 0) + 
         COALESCE((SELECT income_value FROM current_month_physical), 0)) - 
        (COALESCE((SELECT income_value FROM last_year_income), 0) + 
         COALESCE((SELECT income_value FROM last_year_physical), 0))
      ) / (COALESCE((SELECT income_value FROM last_year_income), 0) + 
           COALESCE((SELECT income_value FROM last_year_physical), 0))) * 100, 2)
    END AS "与同期差异%"
)

-- 最终输出结果
SELECT * FROM final_results
ORDER BY 
  CASE "项目"
    WHEN '检查治疗人次/项次' THEN 1
    WHEN '上锦检查治疗收入(元)' THEN 2
    WHEN '上锦体检病理收入(元)' THEN 3
    WHEN '上锦收入合计' THEN 4
    ELSE 5
  END



)

union all

select * from (


-- 天府病理收入统计报表 - 多期对比分析

WITH last_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

last_last_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

last_year_same_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date
),

-- 本月检查治疗人次/项次（天府）
current_month_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_month_range
  WHERE f_blk IN ('天府锦江冰冻','天府冰冻','天府普通外检','天府加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'
),

-- 上月检查治疗人次/项次（天府）
last_month_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_last_month_range
  WHERE f_blk IN ('天府锦江冰冻','天府冰冻','天府普通外检','天府加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'
),

-- 去年同期检查治疗人次/项次（天府）
last_year_count AS (
  SELECT COUNT(1) AS count_value FROM hid0101_mssql_bl_rep.t_jcxx, last_year_same_month_range
  WHERE f_blk IN ('天府锦江冰冻','天府冰冻','天府普通外检','天府加快') 
    AND f_bgzt = '已审核' 
    AND f_bgrq >= start_date 
    AND f_bgrq <= end_date
    AND isdeleted = '0'
),

-- 本月检查治疗收入（天府）
current_month_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName = '病理科(天府)'
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM')
),

-- 上月检查治疗收入（天府）
last_month_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName = '病理科(天府)'
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH), 'yyyy-MM')
),

-- 去年同期检查治疗收入（天府）
last_year_income AS (
  SELECT SUM(TotalFee) AS income_value FROM m1.mdr_income
  WHERE IsDeleted = '0' 
    AND RecDeptName = '病理科(天府)'
    AND SUBSTRING(chargedttm, 1, 7) = 
        FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '13' MONTH), 'yyyy-MM')
),

-- 本月体检收入（天府）
current_month_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -1, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0117')
  ) t1
),

-- 上月体检收入（天府）
last_month_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -2, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0117')
  ) t2
),

-- 去年同期体检收入（天府）
last_year_physical AS (
  SELECT SUM("计算金额") AS income_value FROM (
    SELECT
      CASE
        WHEN "qty" IS NULL THEN CAST("FactPrice" AS DECIMAL(10, 2))
        ELSE CAST(CAST("qty" AS DECIMAL(10, 2)) AS INTEGER) * CAST("FactPrice" AS DECIMAL(10, 2))
      END AS "计算金额"
    FROM m1.mdr_peisincome
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
      AND SUBSTRING(dateregister, 1, 7) = DATE_FORMAT(DATE_ADD('month', -13, CURRENT_DATE), '%Y-%m')
      AND medorgcode IN ('HID0117')
  ) t3
),

-- 最终结果汇总
final_results AS (
  -- 1. 检查治疗人次/项次（天府）
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '天府院区' AS "单位",
    '检查治疗人次/项次' AS "项目",
    COALESCE((SELECT count_value FROM current_month_count), 0) AS "本月",
    COALESCE((SELECT count_value FROM last_month_count), 0) AS "上月",
    COALESCE((SELECT count_value FROM last_year_count), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT count_value FROM last_month_count), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT count_value FROM current_month_count), 0) - COALESCE((SELECT count_value FROM last_month_count), 0)) / COALESCE((SELECT count_value FROM last_month_count), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT count_value FROM last_year_count), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT count_value FROM current_month_count), 0) - COALESCE((SELECT count_value FROM last_year_count), 0)) / COALESCE((SELECT count_value FROM last_year_count), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 2. 天府检查治疗收入(元)
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '天府院区' AS "单位",
    '天府检查治疗收入(元)' AS "项目",
    COALESCE((SELECT income_value FROM current_month_income), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_income), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_income), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_month_income), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_income), 0) - COALESCE((SELECT income_value FROM last_month_income), 0)) / COALESCE((SELECT income_value FROM last_month_income), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_year_income), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_income), 0) - COALESCE((SELECT income_value FROM last_year_income), 0)) / COALESCE((SELECT income_value FROM last_year_income), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 3. 天府体检病理收入(元)
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '天府院区' AS "单位",
    '天府体检病理收入(元)' AS "项目",
    COALESCE((SELECT income_value FROM current_month_physical), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_physical), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_physical), 0) AS "去年同期",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_month_physical), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_physical), 0) - COALESCE((SELECT income_value FROM last_month_physical), 0)) / COALESCE((SELECT income_value FROM last_month_physical), 0)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN COALESCE((SELECT income_value FROM last_year_physical), 0) = 0 THEN NULL
      ELSE ROUND(((COALESCE((SELECT income_value FROM current_month_physical), 0) - COALESCE((SELECT income_value FROM last_year_physical), 0)) / COALESCE((SELECT income_value FROM last_year_physical), 0)) * 100, 2)
    END AS "与同期差异%"
  
  UNION ALL
  
  -- 4. 天府收入合计
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '天府院区' AS "单位",
    '天府收入合计' AS "项目",
    COALESCE((SELECT income_value FROM current_month_income), 0) + 
    COALESCE((SELECT income_value FROM current_month_physical), 0) AS "本月",
    COALESCE((SELECT income_value FROM last_month_income), 0) + 
    COALESCE((SELECT income_value FROM last_month_physical), 0) AS "上月",
    COALESCE((SELECT income_value FROM last_year_income), 0) + 
    COALESCE((SELECT income_value FROM last_year_physical), 0) AS "去年同期",
    CASE 
      WHEN (COALESCE((SELECT income_value FROM last_month_income), 0) + 
            COALESCE((SELECT income_value FROM last_month_physical), 0)) = 0 THEN NULL
      ELSE ROUND(((
        (COALESCE((SELECT income_value FROM current_month_income), 0) + 
         COALESCE((SELECT income_value FROM current_month_physical), 0)) - 
        (COALESCE((SELECT income_value FROM last_month_income), 0) + 
         COALESCE((SELECT income_value FROM last_month_physical), 0))
      ) / (COALESCE((SELECT income_value FROM last_month_income), 0) + 
           COALESCE((SELECT income_value FROM last_month_physical), 0))) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN (COALESCE((SELECT income_value FROM last_year_income), 0) + 
            COALESCE((SELECT income_value FROM last_year_physical), 0)) = 0 THEN NULL
      ELSE ROUND(((
        (COALESCE((SELECT income_value FROM current_month_income), 0) + 
         COALESCE((SELECT income_value FROM current_month_physical), 0)) - 
        (COALESCE((SELECT income_value FROM last_year_income), 0) + 
         COALESCE((SELECT income_value FROM last_year_physical), 0))
      ) / (COALESCE((SELECT income_value FROM last_year_income), 0) + 
           COALESCE((SELECT income_value FROM last_year_physical), 0))) * 100, 2)
    END AS "与同期差异%"
)

-- 最终输出结果
SELECT * FROM final_results
ORDER BY 
  CASE "项目"
    WHEN '检查治疗人次/项次' THEN 1
    WHEN '天府检查治疗收入(元)' THEN 2
    WHEN '天府体检病理收入(元)' THEN 3
    WHEN '天府收入合计' THEN 4
    ELSE 5
  END
  
)




====================total query 


WITH base_report AS (
  -- 原始视图数据，添加统计月字段以匹配其他查询
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    "单位",
    "项目", 
    "本月",
    "上月",
    "去年同期",
    "与上月差异%",
    "与同期差异%"
  FROM m1.om_bl_report
),

-- 计算检查治疗人次/项次总合计
total_count AS (
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '合计' AS "单位",
    '检查治疗人次/项次合计' AS "项目",
    SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "本月" ELSE 0 END) AS "本月",
    SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "上月" ELSE 0 END) AS "上月",
    SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "去年同期" ELSE 0 END) AS "去年同期",
    CASE 
      WHEN SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "上月" ELSE 0 END) = 0 THEN NULL
      ELSE ROUND(((SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "本月" ELSE 0 END) - 
                   SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "上月" ELSE 0 END)) / 
                  SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "上月" ELSE 0 END)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "去年同期" ELSE 0 END) = 0 THEN NULL
      ELSE ROUND(((SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "本月" ELSE 0 END) - 
                   SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "去年同期" ELSE 0 END)) / 
                  SUM(CASE WHEN "项目" = '检查治疗人次/项次' THEN "去年同期" ELSE 0 END)) * 100, 2)
    END AS "与同期差异%"
  FROM base_report
),

-- 计算总收入合计
total_income AS (
  SELECT 
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM') AS "统计月",
    '合计' AS "单位",
    '总收入合计(元)' AS "项目",
    SUM(CASE 
          WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') 
          THEN "本月" 
          ELSE 0 
        END) AS "本月",
    SUM(CASE 
          WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') 
          THEN "上月" 
          ELSE 0 
        END) AS "上月",
    SUM(CASE 
          WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') 
          THEN "去年同期" 
          ELSE 0 
        END) AS "去年同期",
    CASE 
      WHEN SUM(CASE WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') THEN "上月" ELSE 0 END) = 0 THEN NULL
      ELSE ROUND(((SUM(CASE WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') THEN "本月" ELSE 0 END) - 
                   SUM(CASE WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') THEN "上月" ELSE 0 END)) / 
                  SUM(CASE WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') THEN "上月" ELSE 0 END)) * 100, 2)
    END AS "与上月差异%",
    CASE 
      WHEN SUM(CASE WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') THEN "去年同期" ELSE 0 END) = 0 THEN NULL
      ELSE ROUND(((SUM(CASE WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') THEN "本月" ELSE 0 END) - 
                   SUM(CASE WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') THEN "去年同期" ELSE 0 END)) / 
                  SUM(CASE WHEN "项目" IN ('本部收入合计', '上锦收入合计', '天府收入合计') THEN "去年同期" ELSE 0 END)) * 100, 2)
    END AS "与同期差异%"
  FROM base_report
)

-- 合并原始报表和总计行，并按单位和项目排序
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
      WHEN '上锦检查治疗收入(元)' THEN 2
      WHEN '上锦体检病理收入(元)' THEN 3
      WHEN '上锦收入合计' THEN 6
      WHEN '天府检查治疗收入(元)' THEN 2
      WHEN '天府体检病理收入(元)' THEN 3
      WHEN '天府收入合计' THEN 6
      WHEN '检查治疗人次/项次合计' THEN 7
      WHEN '总收入合计(元)' THEN 8
      ELSE 9
    END AS item_order
  FROM (
    SELECT * FROM base_report
    UNION ALL
    SELECT * FROM total_count
    UNION ALL
    SELECT * FROM total_income
  ) t
) result
ORDER BY "统计月", unit_order, item_order