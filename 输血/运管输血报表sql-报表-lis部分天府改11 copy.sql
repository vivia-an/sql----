SET SESSION query_max_stage_count = 2500;

-- 输血科综合项目统计（转换为Presto SQL）
-- 数据源：天府医院LIS系统（hid0117）

-- 时间范围定义：上月数据
WITH last_month_range AS (
  SELECT
    FORMAT_DATETIME(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH), 'yyyy-MM-dd') || ' 00:00:00' AS start_date,
    FORMAT_DATETIME(LAST_DAY_OF_MONTH(DATE_TRUNC('MONTH', CURRENT_DATE - INTERVAL '1' MONTH)), 'yyyy-MM-dd') || ' 23:59:59' AS end_date,
    '2025-04-22 00:00:00' AS system_switch_date  -- 新旧系统切换日期
)

SELECT 
    "XM" as "项目名称",
    SUM(T."RC") as "人次",
    SUM(T."FY") as "费用",
    SUM(T."GZL") as "工作量"
FROM ( 
    -- ========== 第一部分：2025-04-22之前的旧系统数据（bis库） ==========
    -- 检验项目统计（旧系统）
    SELECT DISTINCT  
        c."chinese_name" as "XM",
        count(a."inspection_id") as "RC",
        sum(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
        sum(COALESCE(
            CASE WHEN CAST(b."workload" AS INTEGER) = 0 THEN 1 
                 ELSE CAST(b."workload" AS INTEGER) 
            END, 1)) as "GZL"
    FROM hid0117_orcl_lis_bis.lis6_inspect_sample a
    INNER JOIN hid0117_orcl_lis_bis.bis_charged_list b
        ON a."inspection_id" = b."inspection_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_bis.bis_charge_item c
        ON b."charge_item_id" = c."charge_item_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND a."group_id" IN ('G013')
      AND b."sample_charge_id" NOT LIKE 'B%' 
      AND b."sample_charge_id" NOT LIKE 'C%'
      -- 旧系统数据：时间 >= 上月开始 AND 时间 < 系统切换日期
      AND a."input_time" >= (SELECT start_date FROM last_month_range)
      AND a."input_time" < (SELECT system_switch_date FROM last_month_range)
    GROUP BY c."chinese_name"
    
    UNION ALL
    
    -- 补费项目统计（旧系统）
    SELECT
        a."charge_item_name" as "XM",
        sum(CAST(a."charge_num" AS INTEGER)) as "RC",
        sum(COALESCE(CAST(a."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."serial_no") as "GZL"
    FROM hid0117_orcl_lis_bis.bis_charged_list a
    INNER JOIN hid0117_orcl_lis_bis.bis_requisition_info b
        ON a."requisition_id" = b."requisition_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND a."requisition_id" LIKE '99%'
      AND a."charge_state" IN ('1','-1')
      AND (a."inspection_id" NOT LIKE '*%' OR a."inspection_id" IS NULL)
      AND a."sample_charge_id" LIKE 'H%'
      -- 旧系统数据：时间 >= 上月开始 AND 时间 < 系统切换日期
      AND a."input_time" >= (SELECT start_date FROM last_month_range)
      AND a."input_time" < (SELECT system_switch_date FROM last_month_range)
    GROUP BY a."charge_item_name"
    
    UNION ALL
    
    -- ========== 第二部分：2025-04-22之后的新系统数据（XH系统） ==========
    -- 检验项目统计（新系统）
    SELECT DISTINCT  
        c."chinese_name" as "XM",
        count(a."inspection_id") as "RC",
        sum(COALESCE(CAST(c."charge" AS DOUBLE), 0)) as "FY",
        sum(COALESCE(
            CASE WHEN CAST(b."workload" AS INTEGER) = 0 THEN 1 
                 ELSE CAST(b."workload" AS INTEGER) 
            END, 1)) as "GZL"
    FROM hid0117_orcl_lis_xhdata.lis6_inspect_sample a
    INNER JOIN hid0117_orcl_lis_xhdata.lis6_inspect_charge b
        ON a."inspection_id" = b."inspection_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_xhsystem1.lis6_charge_item c
        ON b."charge_item_id" = c."charge_item_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND a."group_id" IN ('G013')
      -- 新系统数据：时间 >= 系统切换日期 AND 时间 <= 上月结束
      AND a."input_time" >= (SELECT system_switch_date FROM last_month_range)
      AND a."input_time" <= (SELECT end_date FROM last_month_range)
    GROUP BY c."chinese_name"
    
    UNION ALL
    
    -- 输血申请统计（新系统）
    SELECT DISTINCT
        c."blood_type_name" as "XM",
        count(a."inspection_id") as "RC",
        0 as "FY",
        count(a."inspection_id") as "GZL"
    FROM hid0117_orcl_lis_xhdata.lis6_inspect_sample a
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_req_info b
        ON a."requisition_id" = b."req_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_req_blood c
        ON b."req_id" = c."req_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND a."group_id" IN ('G013')
      -- 新系统数据：时间 >= 系统切换日期 AND 时间 <= 上月结束
      AND a."input_time" >= (SELECT system_switch_date FROM last_month_range)
      AND a."input_time" <= (SELECT end_date FROM last_month_range)
    GROUP BY c."blood_type_name"
    
    UNION ALL
    
    -- 收费项目统计（带H样本编号，新系统）
    SELECT
        b."charge_item_name" as "XM",
        sum(CAST(b."charge_num" AS INTEGER)) as "RC",
        sum(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."charged_id") as "GZL"
    FROM hid0117_orcl_lis_xhbis.bis6_charged_info a
    INNER JOIN hid0117_orcl_lis_bis.xinghe_charged_list b
        ON a."sample_charge_id" = b."sample_charge_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND a."charge_state" IN ('charged','uncharged')
      AND a."sample_charge_id" LIKE 'H%'
      -- 新系统数据：时间 >= 系统切换日期 AND 时间 <= 上月结束
      AND a."charge_time" >= (SELECT system_switch_date FROM last_month_range)
      AND a."charge_time" <= (SELECT end_date FROM last_month_range)
    GROUP BY b."charge_item_name"
    
    UNION ALL
    
    -- 补费项目统计（新系统）
    SELECT
        a."charge_item_name" as "XM",
        count(a."charged_id") as "RC",
        sum(COALESCE(CAST(a."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."charged_id") as "GZL"
    FROM hid0117_orcl_lis_xhbis.bis6_charged_info a
    WHERE a."isdeleted" = '0'
      AND a."charge_state" IN ('charged','uncharged')
      AND a."charged_type" = '补费'
      AND a."sample_charge_id" <> 'LIS07134'
      -- 新系统数据：时间 >= 系统切换日期 AND 时间 <= 上月结束
      AND a."charge_time" >= (SELECT system_switch_date FROM last_month_range)
      AND a."charge_time" <= (SELECT end_date FROM last_month_range)
    GROUP BY a."charge_item_name"
    
    UNION ALL
    
    -- HIS申请统计
    SELECT 
        a."charge_name" as "XM",
        count(DISTINCT b."req_id") as "RC",
        sum(COALESCE(CAST(a."charge" AS DOUBLE), 0)) as "FY",
        count(DISTINCT b."req_id") as "GZL"
    FROM hid0117_orcl_lis_dbo.his_requisition a
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_req_info b
        ON a."rep_id" = b."req_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND b."req_type" = '4'
      AND b."patient_dept_name" NOT LIKE '%测试%'
      -- 新系统数据：时间 >= 系统切换日期 AND 时间 <= 上月结束
      AND b."req_time" >= (SELECT system_switch_date FROM last_month_range)
      AND b."req_time" <= (SELECT end_date FROM last_month_range)
    GROUP BY a."charge_name"
    
    UNION ALL
    
    -- 血袋发血统计
    SELECT DISTINCT
        b."blood_name" as "XM",
        COUNT(a."bloodbag_id") as "RC",
        SUM(COALESCE(CAST(a."blood_charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."bloodbag_id") as "GZL"
    FROM hid0117_orcl_lis_xhbis.bis6_bloodbag_input a
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_xhdata.lis6_inspect_sample c
        ON a."inspection_id" = c."inspection_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      -- 新系统数据：时间 >= 系统切换日期 AND 时间 <= 上月结束
      AND a."sendblood_time" >= (SELECT system_switch_date FROM last_month_range)
      AND a."sendblood_time" <= (SELECT end_date FROM last_month_range)
    GROUP BY b."blood_name"
    
    UNION ALL
    
    -- 配血方法统计
    SELECT DISTINCT
        e."method_name" as "XM",
        COUNT(a."match_id") as "RC",
        SUM(COALESCE(CAST(e."method_charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."match_id") as "GZL"
    FROM hid0117_orcl_lis_xhbis.bis6_bloodbag_match a
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_bloodbag_input d
        ON a."bloodbag_id" = d."bloodbag_id"
        AND d."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_match_blood_type b
        ON d."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_xhdata.lis6_inspect_sample c
        ON a."inspection_id" = c."inspection_id"
        AND c."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_match_method e
        ON a."method_type_id" = e."method_id"
        AND e."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND e."method_id" NOT IN ('00000004','9','8','4')
      -- 新系统数据：时间 >= 系统切换日期 AND 时间 <= 上月结束
      AND a."macth_date" >= (SELECT system_switch_date FROM last_month_range)
      AND a."macth_date" <= (SELECT end_date FROM last_month_range)
    GROUP BY e."method_name"
) T
GROUP BY T."XM"
ORDER BY T."XM";