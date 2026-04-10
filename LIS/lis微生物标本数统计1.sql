







-- 临床微生物实验室统计（完全对齐运管科报表逻辑，含同比环比）
-- GROUP_ID: G999, G998, G014, G022
-- 统计期间：动态（上个月）

WITH date_ranges AS (
    -- 获取动态日期范围
   SELECT 
        -- 统计月份标签
        CAST(YEAR(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR) || '年-' || 
        LPAD(CAST(MONTH(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), 2, '0') || '月' as stat_month_label,
        -- 当月（实际是上个月）日期范围
        REPLACE(CAST(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), '-', '') as current_month_start,
        REPLACE(CAST(LAST_DAY_OF_MONTH(CURRENT_DATE - INTERVAL '1' MONTH) AS VARCHAR), '-', '') as current_month_end,
        -- 上月（实际是上上个月）日期范围
        REPLACE(CAST(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '2' MONTH) AS VARCHAR), '-', '') as last_month_start,
        REPLACE(CAST(LAST_DAY_OF_MONTH(CURRENT_DATE - INTERVAL '2' MONTH) AS VARCHAR), '-', '') as last_month_end,
        -- 去年同期（实际是去年同期的上个月）日期范围
        REPLACE(CAST(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' YEAR - INTERVAL '1' MONTH) AS VARCHAR), '-', '') as last_year_start,
        REPLACE(CAST(LAST_DAY_OF_MONTH(CURRENT_DATE - INTERVAL '1' YEAR - INTERVAL '1' MONTH) AS VARCHAR), '-', '') as last_year_end
),
-- ========== 当月数据（动态：上个月） ==========
workload_stat AS (
    SELECT COUNT(DISTINCT t."inspection_id") as "标本数", SUM(COALESCE(CAST(C."workload" AS DOUBLE), 0)) as "项目数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample t
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b ON t."inspection_id" = b."inspection_id" AND b."isdeleted" = '0'
    LEFT JOIN HID0101_ORCL_LIS_XHSYSTEM1.lis_charge_item C ON b."charge_item_id" = C."charge_item_id" AND C."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE t."inspection_date" BETWEEN d.current_month_start AND d.current_month_end AND t."isdeleted" = '0' AND t."CHECK_TIME" IS NOT NULL
        AND t."GROUP_ID" IN ('G999', 'G998', 'G014', 'G022')
),
income_stat AS (
    SELECT SUM(COALESCE(CAST(A."SAMPLE_CHARGE" AS DOUBLE), 0)) as "总收入"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    CROSS JOIN date_ranges d
    WHERE A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end AND A."isdeleted" = '0' AND A."CHECK_TIME" IS NOT NULL
        AND A."GROUP_ID" IN ('G999', 'G998', 'G014', 'G022')
),
wb_bufe AS (
    SELECT COUNT(A."inspection_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge B ON A."inspection_id" = B."inspection_id" AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE STRPOS(B."his_id", '||') > 0 AND A."patient_type" IN ('1','2','3','4','5','8','12') AND A."GROUP_ID" IN ('G999','G998')
        AND A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end AND A."isdeleted" = '0'
),
keshi_stat AS (
    SELECT COUNT(DISTINCT A."requisition_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_requisition_item B ON A."requisition_id" = B."requisition_id" AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE A."patient_type" IN ('1','2','3','4','5','8','12') AND A."GROUP_ID" IN ('G999','G998','G014','G022')
        AND A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end AND A."isdeleted" = '0'
),
-- ========== 上月数据（动态：上上个月） ==========
workload_stat_lm AS (
    SELECT COUNT(DISTINCT t."inspection_id") as "标本数", SUM(COALESCE(CAST(C."workload" AS DOUBLE), 0)) as "项目数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample t
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b ON t."inspection_id" = b."inspection_id" AND b."isdeleted" = '0'
    LEFT JOIN HID0101_ORCL_LIS_XHSYSTEM1.lis_charge_item C ON b."charge_item_id" = C."charge_item_id" AND C."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE t."inspection_date" BETWEEN d.last_month_start AND d.last_month_end AND t."isdeleted" = '0' AND t."CHECK_TIME" IS NOT NULL
        AND t."GROUP_ID" IN ('G999', 'G998', 'G014', 'G022')
),
income_stat_lm AS (
    SELECT SUM(COALESCE(CAST(A."SAMPLE_CHARGE" AS DOUBLE), 0)) as "总收入"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    CROSS JOIN date_ranges d
    WHERE A."inspection_date" BETWEEN d.last_month_start AND d.last_month_end AND A."isdeleted" = '0' AND A."CHECK_TIME" IS NOT NULL
        AND A."GROUP_ID" IN ('G999', 'G998', 'G014', 'G022')
),
wb_bufe_lm AS (
    SELECT COUNT(A."inspection_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge B ON A."inspection_id" = B."inspection_id" AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE STRPOS(B."his_id", '||') > 0 AND A."patient_type" IN ('1','2','3','4','5','8','12') AND A."GROUP_ID" IN ('G999','G998')
        AND A."inspection_date" BETWEEN d.last_month_start AND d.last_month_end AND A."isdeleted" = '0'
),
keshi_stat_lm AS (
    SELECT COUNT(DISTINCT A."requisition_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_requisition_item B ON A."requisition_id" = B."requisition_id" AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE A."patient_type" IN ('1','2','3','4','5','8','12') AND A."GROUP_ID" IN ('G999','G998','G014','G022')
        AND A."inspection_date" BETWEEN d.last_month_start AND d.last_month_end AND A."isdeleted" = '0'
),
-- ========== 去年同期数据（动态：去年同期的上个月） ==========
workload_stat_ly AS (
    SELECT COUNT(DISTINCT t."inspection_id") as "标本数", SUM(COALESCE(CAST(C."workload" AS DOUBLE), 0)) as "项目数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample t
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b ON t."inspection_id" = b."inspection_id" AND b."isdeleted" = '0'
    LEFT JOIN HID0101_ORCL_LIS_XHSYSTEM1.lis_charge_item C ON b."charge_item_id" = C."charge_item_id" AND C."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE t."inspection_date" BETWEEN d.last_year_start AND d.last_year_end AND t."isdeleted" = '0' AND t."CHECK_TIME" IS NOT NULL
        AND t."GROUP_ID" IN ('G999', 'G998', 'G014', 'G022')
),
income_stat_ly AS (
    SELECT SUM(COALESCE(CAST(A."SAMPLE_CHARGE" AS DOUBLE), 0)) as "总收入"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    CROSS JOIN date_ranges d
    WHERE A."inspection_date" BETWEEN d.last_year_start AND d.last_year_end AND A."isdeleted" = '0' AND A."CHECK_TIME" IS NOT NULL
        AND A."GROUP_ID" IN ('G999', 'G998', 'G014', 'G022')
),
wb_bufe_ly AS (
    SELECT COUNT(A."inspection_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge B ON A."inspection_id" = B."inspection_id" AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE STRPOS(B."his_id", '||') > 0 AND A."patient_type" IN ('1','2','3','4','5','8','12') AND A."GROUP_ID" IN ('G999','G998')
        AND A."inspection_date" BETWEEN d.last_year_start AND d.last_year_end AND A."isdeleted" = '0'
),
keshi_stat_ly AS (
    SELECT COUNT(DISTINCT A."requisition_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_requisition_item B ON A."requisition_id" = B."requisition_id" AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE A."patient_type" IN ('1','2','3','4','5','8','12') AND A."GROUP_ID" IN ('G999','G998','G014','G022')
        AND A."inspection_date" BETWEEN d.last_year_start AND d.last_year_end AND A."isdeleted" = '0'
)

SELECT 
    d.stat_month_label as "统计月",
    '实验医学科(检验科)' as "运管科室",
    '主院区' as "运管院区",
    '临床微生物实验室' as "亚专业组",
    
    -- 当月数据（动态：上个月）
    COALESCE((SELECT "样本数" FROM wb_bufe), 0) + COALESCE((SELECT "样本数" FROM keshi_stat), 0) as "标本数",
    COALESCE((SELECT "项目数" FROM workload_stat), 0) as "项目数",
    ROUND(COALESCE((SELECT "总收入" FROM income_stat), 0), 2) as "总收入",
    
    -- 上月数据（动态：上上个月）
    COALESCE((SELECT "样本数" FROM wb_bufe_lm), 0) + COALESCE((SELECT "样本数" FROM keshi_stat_lm), 0) as "上月标本数",
    COALESCE((SELECT "项目数" FROM workload_stat_lm), 0) as "上月项目数",
    ROUND(COALESCE((SELECT "总收入" FROM income_stat_lm), 0), 2) as "上月总收入",
    
    -- 去年同期数据（动态：去年同期的上个月）
    COALESCE((SELECT "样本数" FROM wb_bufe_ly), 0) + COALESCE((SELECT "样本数" FROM keshi_stat_ly), 0) as "去年同期标本数",
    COALESCE((SELECT "项目数" FROM workload_stat_ly), 0) as "去年同期项目数",
    ROUND(COALESCE((SELECT "总收入" FROM income_stat_ly), 0), 2) as "去年同期总收入",
    
    -- 收入占比（需要与总合计计算，暂时为NULL）
    NULL as "总收入占比",
    NULL as "上月总收入占比",
    NULL as "去年同期总收入占比",
    
    -- 环比增长率（当月 vs 上月）
    CAST(ROUND(((COALESCE((SELECT "样本数" FROM wb_bufe), 0) + COALESCE((SELECT "样本数" FROM keshi_stat), 0)) - 
                 (COALESCE((SELECT "样本数" FROM wb_bufe_lm), 0) + COALESCE((SELECT "样本数" FROM keshi_stat_lm), 0))) * 100.0 / 
                 NULLIF((COALESCE((SELECT "样本数" FROM wb_bufe_lm), 0) + COALESCE((SELECT "样本数" FROM keshi_stat_lm), 0)), 0), 2) AS DECIMAL(10,2)) as "标本数环比增长率%",
    CAST(ROUND((COALESCE((SELECT "项目数" FROM workload_stat), 0) - COALESCE((SELECT "项目数" FROM workload_stat_lm), 0)) * 100.0 / 
                 NULLIF(COALESCE((SELECT "项目数" FROM workload_stat_lm), 0), 0), 2) AS DECIMAL(10,2)) as "项目数环比增长率%",
    CAST(ROUND((COALESCE((SELECT "总收入" FROM income_stat), 0) - COALESCE((SELECT "总收入" FROM income_stat_lm), 0)) * 100.0 / 
                 NULLIF(COALESCE((SELECT "总收入" FROM income_stat_lm), 0), 0), 2) AS DECIMAL(10,2)) as "收入环比增长率%",
    
    -- 同比增长率（当月 vs 去年同期）
    CAST(ROUND(((COALESCE((SELECT "样本数" FROM wb_bufe), 0) + COALESCE((SELECT "样本数" FROM keshi_stat), 0)) - 
                 (COALESCE((SELECT "样本数" FROM wb_bufe_ly), 0) + COALESCE((SELECT "样本数" FROM keshi_stat_ly), 0))) * 100.0 / 
                 NULLIF((COALESCE((SELECT "样本数" FROM wb_bufe_ly), 0) + COALESCE((SELECT "样本数" FROM keshi_stat_ly), 0)), 0), 2) AS DECIMAL(10,2)) as "标本数同比增长率%",
    CAST(ROUND((COALESCE((SELECT "项目数" FROM workload_stat), 0) - COALESCE((SELECT "项目数" FROM workload_stat_ly), 0)) * 100.0 / 
                 NULLIF(COALESCE((SELECT "项目数" FROM workload_stat_ly), 0), 0), 2) AS DECIMAL(10,2)) as "项目数同比增长率%",
    CAST(ROUND((COALESCE((SELECT "总收入" FROM income_stat), 0) - COALESCE((SELECT "总收入" FROM income_stat_ly), 0)) * 100.0 / 
                 NULLIF(COALESCE((SELECT "总收入" FROM income_stat_ly), 0), 0), 2) AS DECIMAL(10,2)) as "收入同比增长率%"
FROM date_ranges d;








































