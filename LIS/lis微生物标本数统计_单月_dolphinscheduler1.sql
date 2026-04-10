-- 临床微生物实验室统计 - DolphinScheduler单月版本
-- GROUP_ID: G999, G998, G014, G022
-- 使用说明：DolphinScheduler参数 $[yyyy-MM-1] 表示上个月
-- 
-- ==================== 血缘依赖说明 ====================
-- 数据来源表：
-- 1. hid0101_orcl_lis_dbo.lis_inspection_sample - LIS检验样本表
--    关键字段：inspection_id, GROUP_ID, inspection_date, CHECK_TIME, SAMPLE_CHARGE, patient_type, isdeleted
-- 2. hid0101_orcl_lis_dbo.lis_inspection_sample_charge - LIS检验收费关联表
--    关键字段：inspection_id, charge_item_id, his_id, isdeleted
-- 3. HID0101_ORCL_LIS_XHSYSTEM1.lis_charge_item - 收费项目表（工作量）
--    关键字段：charge_item_id, workload, isdeleted
-- 4. hid0101_orcl_lis_dbo.lis_requisition_item - LIS申请单项目表
--    关键字段：requisition_id, isdeleted

WITH date_ranges AS (
    -- 动态日期范围（基于DolphinScheduler参数）
    SELECT 
        -- 统计月份标签
        SUBSTR('$[month]', 1, 4) || '年-' || SUBSTR('$[month]', 6, 2) || '月' as stat_month_label,
        -- 当月日期范围（格式：yyyyMMdd）
        REPLACE('$[month]', '-', '') || '01' as current_month_start,
        REPLACE(CAST(LAST_DAY_OF_MONTH(DATE_PARSE('$[month]' || '-01', '%Y-%m-%d')) AS VARCHAR), '-', '') as current_month_end
),

-- ==================== 当月数据查询 ====================

-- 工作量和标本数
-- 来源：lis_inspection_sample + lis_inspection_sample_charge + lis_charge_item
-- 筛选：GROUP_ID IN ('G999', 'G998', 'G014', 'G022')
workload_stat AS (
    SELECT 
        COUNT(DISTINCT t."inspection_id") as "标本数", 
        SUM(COALESCE(CAST(C."workload" AS DOUBLE), 0)) as "项目数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample t
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b 
        ON t."inspection_id" = b."inspection_id" AND b."isdeleted" = '0'
    LEFT JOIN HID0101_ORCL_LIS_XHSYSTEM1.lis_charge_item C 
        ON b."charge_item_id" = C."charge_item_id" AND C."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE t."inspection_date" BETWEEN d.current_month_start AND d.current_month_end 
        AND t."isdeleted" = '0' 
        AND t."CHECK_TIME" IS NOT NULL
        AND t."GROUP_ID" IN ('G999', 'G998', 'G014', 'G022')
),

-- 收入统计
-- 来源：lis_inspection_sample
income_stat AS (
    SELECT SUM(COALESCE(CAST(A."SAMPLE_CHARGE" AS DOUBLE), 0)) as "总收入"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    CROSS JOIN date_ranges d
    WHERE A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end 
        AND A."isdeleted" = '0' 
        AND A."CHECK_TIME" IS NOT NULL
        AND A."GROUP_ID" IN ('G999', 'G998', 'G014', 'G022')
),

-- 外包收费样本数（his_id包含'||'的记录）
-- 来源：lis_inspection_sample + lis_inspection_sample_charge
-- 筛选：GROUP_ID IN ('G999','G998'), patient_type IN ('1','2','3','4','5','8','12')
wb_bufe AS (
    SELECT COUNT(A."inspection_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge B 
        ON A."inspection_id" = B."inspection_id" AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE STRPOS(B."his_id", '||') > 0 
        AND A."patient_type" IN ('1','2','3','4','5','8','12') 
        AND A."GROUP_ID" IN ('G999','G998')
        AND A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end 
        AND A."isdeleted" = '0'
),

-- 科室样本数（按申请单去重）
-- 来源：lis_inspection_sample + lis_requisition_item
-- 筛选：GROUP_ID IN ('G999','G998','G014','G022'), patient_type IN ('1','2','3','4','5','8','12')
keshi_stat AS (
    SELECT COUNT(DISTINCT A."requisition_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_requisition_item B 
        ON A."requisition_id" = B."requisition_id" AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE A."patient_type" IN ('1','2','3','4','5','8','12') 
        AND A."GROUP_ID" IN ('G999','G998','G014','G022')
        AND A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end 
        AND A."isdeleted" = '0'
)

-- ==================== 最终输出（保持原有字段结构） ====================
SELECT 
    d.stat_month_label as "统计月",
    '实验医学科(检验科)' as "运管科室",
    '主院区' as "运管院区",
    '临床微生物实验室' as "亚专业组",
    
    -- 当月数据
    COALESCE((SELECT "样本数" FROM wb_bufe), 0) + COALESCE((SELECT "样本数" FROM keshi_stat), 0) as "标本数",
    COALESCE((SELECT "项目数" FROM workload_stat), 0) as "项目数",
    ROUND(COALESCE((SELECT "总收入" FROM income_stat), 0), 2) as "总收入",
    
    -- 上月数据（默认值0）
    CAST(0 AS BIGINT) as "上月标本数",
    CAST(0 AS BIGINT) as "上月项目数",
    CAST(0 AS DECIMAL(18,2)) as "上月总收入",
    
    -- 去年同期数据（默认值0）
    CAST(0 AS BIGINT) as "去年同期标本数",
    CAST(0 AS BIGINT) as "去年同期项目数",
    CAST(0 AS DECIMAL(18,2)) as "去年同期总收入",
    
    -- 收入占比（默认值0）
    CAST(0 AS DECIMAL(10,2)) as "总收入占比",
    CAST(0 AS DECIMAL(10,2)) as "上月总收入占比",
    CAST(0 AS DECIMAL(10,2)) as "去年同期总收入占比",
    
    -- 环比增长率（默认值0）
    CAST(0 AS DECIMAL(10,2)) as "标本数环比增长率%",
    CAST(0 AS DECIMAL(10,2)) as "项目数环比增长率%",
    CAST(0 AS DECIMAL(10,2)) as "收入环比增长率%",
    
    -- 同比增长率（默认值0）
    CAST(0 AS DECIMAL(10,2)) as "标本数同比增长率%",
    CAST(0 AS DECIMAL(10,2)) as "项目数同比增长率%",
    CAST(0 AS DECIMAL(10,2)) as "收入同比增长率%"
FROM date_ranges d

