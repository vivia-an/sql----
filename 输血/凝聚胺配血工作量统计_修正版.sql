-- 凝聚胺配血工作量统计SQL（修正版）
-- 基于输血血缘关系分析，使用正确的数据源

SELECT 
    '凝聚胺配血工作量统计' as "统计类型",
    date_format(current_date, '%Y-%m') as "统计月份",
    SUM("工作量") as "凝聚胺配血工作量",
    COUNT(DISTINCT "检验ID") as "配血例数",
    COUNT(DISTINCT "血袋ID") as "配血血袋数"
FROM (
    -- 主要数据源：配血方法统计（实际配血操作记录）
    SELECT DISTINCT
        a."MATCH_ID" as "配血ID",
        a."INSPECTION_ID" as "检验ID", 
        a."BLOODBAG_ID" as "血袋ID",
        e."method_name" as "配血方法",
        COUNT(a."MATCH_ID") as "工作量"
    FROM hid0101_orcl_lis_xhbis.bis6_bloodbag_match a
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT d
        ON a."BLOODBAG_ID" = d."BLOODBAG_ID"
        AND d."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON d."BLOOD_TYPE_ID" = b."BLOOD_TYPE_ID"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhdata.lis6_inspect_sample c
        ON a."INSPECTION_ID" = c."inspection_id"
        AND c."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_method e
        ON a."METHOD_TYPE_ID" = e."method_id"
        AND e."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        -- 限制为凝聚胺配血方法
        AND e."method_name" = '盐水介质+凝聚胺配血'
        -- 时间筛选：上个月
        AND a."MACTH_DATE" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') 
                                AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
    GROUP BY a."MATCH_ID", a."INSPECTION_ID", a."BLOODBAG_ID", e."method_name"
    
    UNION ALL
    
    -- 辅助数据源：LIS检验收费统计（补充检验操作记录）
    SELECT DISTINCT
        NULL as "配血ID",
        a."inspection_id" as "检验ID",
        NULL as "血袋ID", 
        c."chinese_name" as "配血方法",
        COALESCE(CASE WHEN CAST(b."workload" AS DOUBLE) = 0 THEN 1 ELSE CAST(b."workload" AS DOUBLE) END, 1) as "工作量"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample a
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b
        ON a."inspection_id" = b."inspection_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhsystem1.lis_charge_item c
        ON b."charge_item_id" = c."charge_item_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        -- 限制为输血检验组
        AND a."group_id" IN ('G013','G053','G105','G111')
        -- 限制为凝聚胺配血项目
        AND c."chinese_name" = '盐水介质+凝聚胺配血'
        -- 时间筛选：上个月
        AND a."input_time" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') 
                                AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
) result_data;

-- 血缘关系说明：
-- 
-- 主要数据源（配血操作记录）：
-- 1. hid0101_orcl_lis_xhbis.bis6_bloodbag_match - 血袋配血记录表（核心表）
-- 2. hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT - 血袋输入信息表
-- 3. hid0101_orcl_lis_xhbis.bis6_match_blood_type - 血型匹配表
-- 4. hid0101_orcl_lis_xhdata.lis6_inspect_sample - 检验样本表
-- 5. hid0101_orcl_lis_xhbis.bis6_match_method - 配血方法表
-- 
-- 辅助数据源（检验操作记录）：
-- 6. hid0101_orcl_lis_dbo.lis_inspection_sample - 检验样本表（旧版）
-- 7. hid0101_orcl_lis_dbo.lis_inspection_sample_charge - 检验收费表（旧版）
-- 8. hid0101_orcl_lis_xhsystem1.lis_charge_item - 收费项目表
-- 
-- 关键字段：
-- - 配血日期：bis6_bloodbag_match.MACTH_DATE（实际配血操作时间）
-- - 配血方法：bis6_match_method.method_name = '盐水介质+凝聚胺配血'
-- - 工作量计算：COUNT(配血记录) + SUM(检验工作量)
-- - 逻辑删除：所有表均添加 isdeleted = '0' 筛选条件 