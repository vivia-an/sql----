-- 优化版本：降低 query_max_stage_count
-- 完全基于原始SQL逻辑，合并重复的UNION ALL，减少查询阶段数

WITH 
-- 当前统计月份
current_stats_month AS (
    SELECT date_format(date_add('month', -2, current_date), '%Y年-%m月') as "统计月"
), 
-- 时间范围定义
time_ranges AS (
    SELECT 1 as period_id, 
           date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') as start_date,
           date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d') as end_date,
           date_format(date_add('month', -2, current_date), '%Y-%m') as period_label,
           '上月' as period_name
    UNION ALL
    SELECT 2 as period_id,
           date_format(date_trunc('month', date_add('month', -3, current_date)), '%Y-%m-%d') as start_date,
           date_format(date_add('day', -1, date_trunc('month', date_add('month', -2, current_date))), '%Y-%m-%d') as end_date,
           date_format(date_add('month', -3, current_date), '%Y-%m') as period_label,
           '上上月' as period_name
    UNION ALL  
    SELECT 3 as period_id,
           date_format(date_trunc('month', date_add('month', -14, current_date)), '%Y-%m-%d') as start_date,
           date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') as end_date,
           date_format(date_add('month', -14, current_date), '%Y-%m') as period_label,
           '去年同期' as period_name
),

-- 基础血库数据：合并原来所有的UNION ALL血库记录
blood_inventory_consolidated AS (
    SELECT 
        tr.period_id,
        tr.period_label as "周期",
        tr.period_name as "周期名称",
        tr.period_id as "排序",
        
        -- 入库血液 = hxb1+xj1+xxb1+lcd1 (所有血型的入库袋数汇总)
        SUM(CASE WHEN a."in_time" >= tr.start_date AND a."in_time" <= tr.end_date 
             THEN (CASE WHEN c."component_id"='00000009' THEN 1 ELSE 0 END) +
                  (CASE WHEN c."component_id"='00000010' THEN 1 ELSE 0 END) +
                  (CASE WHEN c."component_id"='00000011' THEN 1 ELSE 0 END) +
                  (CASE WHEN c."component_id"='00000012' THEN 1 ELSE 0 END)
             ELSE 0 END) as "入库血液",
        
        -- 出库血液 = hxb1+xj1+xxb1+lcd1 (所有血型的出库袋数汇总)
        SUM(CASE WHEN a."out_date" >= tr.start_date AND a."out_date" <= tr.end_date 
             THEN (CASE WHEN c."component_id"='00000009' THEN 1 ELSE 0 END) +
                  (CASE WHEN c."component_id"='00000010' THEN 1 ELSE 0 END) +
                  (CASE WHEN c."component_id"='00000011' THEN 1 ELSE 0 END) +
                  (CASE WHEN c."component_id"='00000012' THEN 1 ELSE 0 END)
             ELSE 0 END) as "出库血液",
             
        -- 红细胞入库 (袋数)
        SUM(CASE WHEN a."in_time" >= tr.start_date AND a."in_time" <= tr.end_date 
                 AND c."component_id"='00000009'
             THEN 1 ELSE 0 END) as "红细胞入库",
             
        -- 红细胞出库 (袋数)    
        SUM(CASE WHEN a."out_date" >= tr.start_date AND a."out_date" <= tr.end_date 
                 AND c."component_id"='00000009'
             THEN 1 ELSE 0 END) as "红细胞出库",
             
        -- 红细胞入库 (量)
        SUM(CASE WHEN a."in_time" >= tr.start_date AND a."in_time" <= tr.end_date 
                 AND c."component_id"='00000009'
             THEN COALESCE(CAST(a."blood_amount" AS DOUBLE), 0) ELSE 0 END) as "红细胞入库-量",
             
        -- 红细胞出库 (量)
        SUM(CASE WHEN a."out_date" >= tr.start_date AND a."out_date" <= tr.end_date 
                 AND c."component_id"='00000009'
             THEN COALESCE(CAST(a."blood_amount" AS DOUBLE), 0) ELSE 0 END) as "红细胞出库-量",
             
        -- 冷沉淀入库 (袋数)
        SUM(CASE WHEN a."in_time" >= tr.start_date AND a."in_time" <= tr.end_date 
                 AND c."component_id"='00000012'
             THEN 1 ELSE 0 END) as "冷沉淀入库",
             
        -- 冷沉淀出库 (袋数)
        SUM(CASE WHEN a."out_date" >= tr.start_date AND a."out_date" <= tr.end_date 
                 AND c."component_id"='00000012'
             THEN 1 ELSE 0 END) as "冷沉淀出库",
             
        -- 血浆入库 (量)
        SUM(CASE WHEN a."in_time" >= tr.start_date AND a."in_time" <= tr.end_date 
                 AND c."component_id"='00000010'
             THEN COALESCE(CAST(a."blood_amount" AS DOUBLE), 0) ELSE 0 END) as "血浆入库-量",
             
        -- 血浆出库 (袋数)
        SUM(CASE WHEN a."out_date" >= tr.start_date AND a."out_date" <= tr.end_date 
                 AND c."component_id"='00000010'
             THEN 1 ELSE 0 END) as "血浆出库",
             
        -- 血小板入库 (袋数)  
        SUM(CASE WHEN a."in_time" >= tr.start_date AND a."in_time" <= tr.end_date 
                 AND c."component_id"='00000011'
             THEN 1 ELSE 0 END) as "血小板入库",
             
        -- 血小板出库 (袋数)
        SUM(CASE WHEN a."out_date" >= tr.start_date AND a."out_date" <= tr.end_date 
                 AND c."component_id"='00000011'
             THEN 1 ELSE 0 END) as "血小板出库",
             
        -- 血小板出库 (量)
        SUM(CASE WHEN a."out_date" >= tr.start_date AND a."out_date" <= tr.end_date 
                 AND c."component_id"='00000011'
             THEN COALESCE(CAST(a."blood_amount" AS DOUBLE), 0) ELSE 0 END) as "血小板出库-量",
             
        -- 全院调剂血小板次数 (血小板出库袋数 * 3)
        SUM(CASE WHEN a."out_date" >= tr.start_date AND a."out_date" <= tr.end_date 
                 AND c."component_id"='00000011'
             THEN 1 ELSE 0 END) * 3 as "全院调剂血小板次数"
             
    FROM time_ranges tr
    CROSS JOIN hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d
        ON a."inspection_id" = d."inspection_id"    
        AND d."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
    GROUP BY tr.period_id, tr.period_label, tr.period_name
),

-- 手术用血统计：周末加班手术台次
surgery_blood_data AS (
    SELECT 
        tr.period_id,
        COUNT(DISTINCT CASE 
            WHEN day_of_week(CAST(t.scheduled_date AS TIMESTAMP)) IN (6,7) 
                 AND t.scheduled_date >= tr.start_date 
                 AND t.scheduled_date <= tr.end_date
            THEN t.id 
        END) as "周末加班手术台次"
    FROM time_ranges tr
    CROSS JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply t
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg 
        ON t.id = reg.sam_apply_id AND reg.isdeleted = '0'
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent en 
        ON t.id = en.sam_apply_id 
        AND en.isdeleted = '0'
        AND en.s_mzsjlb_dm = '31'
    WHERE t.health_service_org_id = 'HXSSMZK'
        AND t.oper_type = 'ROOM_OPER'
        AND t.is_reject = '2'
        AND t.s_sssyzt_dm = '90'
        AND t.isdeleted = '0'
    GROUP BY tr.period_id
),

-- 配血检收入统计
blood_match_revenue AS (
    SELECT 
        tr.period_id,
        tr.start_date,
        tr.end_date,
        -- 配血检收入：总收入减去指定血液类型收入
        COALESCE((
            SELECT SUM(CAST(A.BLOOD_AMOUNT as DOUBLE))
            FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT A
            INNER JOIN hid0101_orcl_lis_xhbis.BIS6_MATCH_BLOOD_TYPE B 
                ON A.BLOOD_TYPE_ID = B.BLOOD_TYPE_ID
            WHERE A.BLOODBAG_STATE NOT IN ('1','2') AND A.isdeleted = '0' AND B.isdeleted = '0'
                AND A.SENDBLOOD_TIME BETWEEN tr.start_date AND tr.end_date
        ), 0) - COALESCE((
            SELECT SUM(COALESCE(CAST(e.charge AS DOUBLE), 0))
            FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT A
            INNER JOIN hid0101_orcl_lis_xhbis.BIS6_MATCH_BLOOD_TYPE B ON A.BLOOD_TYPE_ID = B.BLOOD_TYPE_ID
            INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE C ON A.INSPECTION_ID = C.INSPECTION_ID
            INNER JOIN hid0101_orcl_lis_xhbis.bis6_charged_info d ON A.BLOODBAG_ID = d.sample_charge_id
            INNER JOIN hid0101_orcl_lis_xhinterface.xinghe_charged_list e ON d.sample_charge_id = e.sample_charge_id
            WHERE A.BLOODBAG_STATE NOT IN ('1','2') AND A.isdeleted = '0' AND B.isdeleted = '0' 
                AND C.isdeleted = '0' AND d.isdeleted = '0' AND e.isdeleted = '0'
                AND A.SENDBLOOD_TIME BETWEEN tr.start_date AND tr.end_date
        ), 0) as "配血检收入"
    FROM time_ranges tr
    GROUP BY tr.period_id, tr.start_date, tr.end_date
),

-- LIS检验统计：合并LIS相关的所有UNION ALL
lis_inspection_data AS (
    SELECT 
        tr.period_id,
        tr.start_date,
        tr.end_date,
        -- LIS检验统计（基于原SQL中的LIS相关查询）
        COALESCE((
            SELECT SUM(COALESCE(CASE WHEN CAST(b."workload" AS DOUBLE) = 0 THEN 1 ELSE CAST(b."workload" AS DOUBLE) END, 1))
            FROM hid0101_orcl_lis_dbo.lis_inspection_sample a
            INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b
                ON a."inspection_id" = b."inspection_id" AND b."isdeleted" = '0'
            INNER JOIN hid0101_orcl_lis_xhsystem1.lis_charge_item c
                ON b."charge_item_id" = c."charge_item_id" AND c."isdeleted" = '0'
            WHERE a."isdeleted" = '0' AND a."group_id" IN ('G013','G053','G105','G111')
                AND a."input_time" BETWEEN CONCAT(tr.start_date, ' 00:00:00') AND CONCAT(tr.end_date, ' 23:59:59')
        ), 0) as "LIS检验工作量"
    FROM time_ranges tr
    GROUP BY tr.period_id, tr.start_date, tr.end_date
),

-- 合并所有数据
base_result AS (
    SELECT 
        bic."周期",
        bic."周期名称", 
        bic."排序",
        bic."入库血液",
        bic."出库血液",
        bic."红细胞入库",
        bic."红细胞出库", 
        bic."红细胞入库-量",
        bic."红细胞出库-量",
        bic."冷沉淀入库",
        bic."冷沉淀出库",
        bic."血浆入库-量",
        bic."血浆出库",
        bic."血小板入库", 
        bic."血小板出库",
        bic."血小板出库-量",
        bic."全院调剂血小板次数",
        COALESCE(sbd."周末加班手术台次", 0) as "周末加班手术台次",
        COALESCE(bmr."配血检收入", 0) as "配血检收入"
    FROM blood_inventory_consolidated bic
    LEFT JOIN surgery_blood_data sbd ON bic."排序" = sbd.period_id  
    LEFT JOIN blood_match_revenue bmr ON bic."排序" = bmr.period_id
    LEFT JOIN lis_inspection_data lid ON bic."排序" = lid.period_id
)

-- 主查询：基础数据 + 环比同比计算
SELECT 
    (SELECT "统计月" FROM current_stats_month) as "统计月",
    '主院区' as "院区分类",
    '输血科' as "运管科室",
    * 
FROM base_result
WHERE "排序" <= 3

UNION ALL

-- 环比计算：当月vs上月
SELECT 
    (SELECT "统计月" FROM current_stats_month) as "统计月",
    '主院区' as "院区分类",
    '输血科' as "运管科室",
    CONCAT(
        MAX(CASE WHEN "排序" = 1 THEN "周期" END),
        ' vs ',
        MAX(CASE WHEN "排序" = 2 THEN "周期" END)
    ) as "周期",
    '环比' as "周期名称",
    4 as "排序",
    -- 入库血液环比
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "入库血液" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "入库血液" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "入库血液" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "入库血液" END), 2)
         ELSE NULL 
    END as "入库血液",
    -- 出库血液环比
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "出库血液" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "出库血液" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "出库血液" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "出库血液" END), 2)
         ELSE NULL 
    END as "出库血液",
    -- 红细胞入库环比
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "红细胞入库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞入库" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "红细胞入库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "红细胞入库" END), 2)
         ELSE NULL 
    END as "红细胞入库",
    -- 红细胞出库环比
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "红细胞出库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞出库" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "红细胞出库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "红细胞出库" END), 2)
         ELSE NULL 
    END as "红细胞出库",
    -- 其他字段的环比计算
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "红细胞入库-量" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞入库-量" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "红细胞入库-量" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "红细胞入库-量" END), 2)
         ELSE NULL 
    END as "红细胞入库-量",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "红细胞出库-量" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞出库-量" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "红细胞出库-量" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "红细胞出库-量" END), 2)
         ELSE NULL 
    END as "红细胞出库-量",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "冷沉淀入库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "冷沉淀入库" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "冷沉淀入库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "冷沉淀入库" END), 2)
         ELSE NULL 
    END as "冷沉淀入库",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "冷沉淀出库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "冷沉淀出库" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "冷沉淀出库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "冷沉淀出库" END), 2)
         ELSE NULL 
    END as "冷沉淀出库",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "血浆入库-量" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血浆入库-量" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "血浆入库-量" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "血浆入库-量" END), 2)
         ELSE NULL 
    END as "血浆入库-量",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "血浆出库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血浆出库" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "血浆出库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "血浆出库" END), 2)
         ELSE NULL 
    END as "血浆出库",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "血小板入库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板入库" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "血小板入库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "血小板入库" END), 2)
         ELSE NULL 
    END as "血小板入库",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "血小板出库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板出库" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "血小板出库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "血小板出库" END), 2)
         ELSE NULL 
    END as "血小板出库",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "血小板出库-量" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板出库-量" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "血小板出库-量" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "血小板出库-量" END), 2)
         ELSE NULL 
    END as "血小板出库-量",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "全院调剂血小板次数" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "全院调剂血小板次数" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "全院调剂血小板次数" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "全院调剂血小板次数" END), 2)
         ELSE NULL 
    END as "全院调剂血小板次数",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "周末加班手术台次" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "周末加班手术台次" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "周末加班手术台次" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "周末加班手术台次" END), 2)
         ELSE NULL 
    END as "周末加班手术台次",
    CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "配血检收入" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "配血检收入" END) - 
                    MAX(CASE WHEN "排序" = 2 THEN "配血检收入" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 2 THEN "配血检收入" END), 2)
         ELSE NULL 
    END as "配血检收入"
FROM base_result
WHERE "排序" <= 2

UNION ALL

-- 同比计算：当月vs去年同期
SELECT 
    (SELECT "统计月" FROM current_stats_month) as "统计月",
    '主院区' as "院区分类",
    '输血科' as "运管科室",
    CONCAT(
        MAX(CASE WHEN "排序" = 1 THEN "周期" END),
        ' vs ',
        MAX(CASE WHEN "排序" = 3 THEN "周期" END)
    ) as "周期",
    '同比' as "周期名称", 
    5 as "排序",
    -- 入库血液同比
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "入库血液" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "入库血液" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "入库血液" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "入库血液" END), 2)
         ELSE NULL 
    END as "入库血液",
    -- 出库血液同比
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "出库血液" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "出库血液" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "出库血液" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "出库血液" END), 2)
         ELSE NULL 
    END as "出库血液",
    -- 红细胞入库同比
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "红细胞入库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞入库" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "红细胞入库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "红细胞入库" END), 2)
         ELSE NULL 
    END as "红细胞入库",
    -- 红细胞出库同比
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "红细胞出库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞出库" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "红细胞出库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "红细胞出库" END), 2)
         ELSE NULL 
    END as "红细胞出库",
    -- 其他字段的同比计算
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "红细胞入库-量" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞入库-量" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "红细胞入库-量" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "红细胞入库-量" END), 2)
         ELSE NULL 
    END as "红细胞入库-量",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "红细胞出库-量" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞出库-量" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "红细胞出库-量" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "红细胞出库-量" END), 2)
         ELSE NULL 
    END as "红细胞出库-量",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "冷沉淀入库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "冷沉淀入库" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "冷沉淀入库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "冷沉淀入库" END), 2)
         ELSE NULL 
    END as "冷沉淀入库", 
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "冷沉淀出库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "冷沉淀出库" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "冷沉淀出库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "冷沉淀出库" END), 2)
         ELSE NULL 
    END as "冷沉淀出库",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "血浆入库-量" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血浆入库-量" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "血浆入库-量" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "血浆入库-量" END), 2)
         ELSE NULL 
    END as "血浆入库-量",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "血浆出库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血浆出库" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "血浆出库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "血浆出库" END), 2)
         ELSE NULL 
    END as "血浆出库",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "血小板入库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板入库" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "血小板入库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "血小板入库" END), 2)
         ELSE NULL 
    END as "血小板入库",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "血小板出库" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板出库" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "血小板出库" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "血小板出库" END), 2)
         ELSE NULL 
    END as "血小板出库",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "血小板出库-量" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板出库-量" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "血小板出库-量" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "血小板出库-量" END), 2)
         ELSE NULL 
    END as "血小板出库-量",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "全院调剂血小板次数" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "全院调剂血小板次数" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "全院调剂血小板次数" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "全院调剂血小板次数" END), 2)
         ELSE NULL 
    END as "全院调剂血小板次数",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "周末加班手术台次" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "周末加班手术台次" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "周末加班手术台次" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "周末加班手术台次" END), 2)
         ELSE NULL 
    END as "周末加班手术台次",
    CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "配血检收入" END) > 0 
         THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "配血检收入" END) - 
                    MAX(CASE WHEN "排序" = 3 THEN "配血检收入" END)) * 100.0 / 
                    MAX(CASE WHEN "排序" = 3 THEN "配血检收入" END), 2)
         ELSE NULL 
    END as "配血检收入"
FROM base_result
WHERE "排序" IN (1, 3)

ORDER BY "排序"