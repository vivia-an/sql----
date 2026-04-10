SET SESSION query_max_stage_count = 2500;

-- 输血科LIS部分简化统计报表（只含三个指标）
-- 统计指标：检测标本数、检测项目数、总工作量

WITH base_stats AS (
    -- 基础数据：检验项目统计
    SELECT DISTINCT  
        b."chinese_name_short" as "项目名称",
        count(a."inspection_id") as "人次",
        sum(COALESCE(
            CASE WHEN CAST(b."workload" AS INTEGER) = 0 THEN 1 
                 ELSE CAST(b."workload" AS INTEGER) 
            END, 1)) as "工作量"
    FROM hid0117_orcl_lis_xhdata.lis6_inspect_sample a
    INNER JOIN hid0117_orcl_lis_dbo.lis_inspection_sample_charge b
        ON a."inspection_id" = b."inspection_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND a."input_time" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
      AND a."input_time" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
      AND a."group_id" IN ('G013','G053','G105','G111')     
    GROUP BY b."chinese_name_short"
    
    UNION ALL
    
    -- 输血申请统计
    SELECT DISTINCT
        c."blood_type_name" as "项目名称",
        count(a."inspection_id") as "人次",
        count(a."inspection_id") as "工作量"
    FROM hid0117_orcl_lis_xhdata.lis6_inspect_sample a
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_req_info b
        ON a."requisition_id" = b."req_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_xhbis.bis6_req_blood c
        ON b."req_id" = c."req_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND a."input_time" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
      AND a."input_time" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
      AND a."group_id" IN ('G013','G053','G105','G111') 
    GROUP BY c."blood_type_name"
),

-- 项目列表（用于计算项目数）
project_list AS (
    SELECT DISTINCT "项目名称"
    FROM base_stats
    WHERE "项目名称" IN (
        'ABO红细胞定型（微柱凝胶法）',
        'ABO血型+Rh血型',
        'ABO血型鉴定',
        'ABO血型鉴定（微柱凝胶法）',
        'RH(-)去白细胞悬浮红细胞',
        'RH分型(4个RH其他抗原+1个RHD抗原)',
        'Rh(-)悬浮红细胞',
        'Rh血型鉴定',
        'Rh阴性确诊试验',
        '冰冻解冻去甘油红细胞',
        '冰冻血浆',
        '病毒灭活血浆',
        '辐照单采血小板',
        '辐照悬浮红细胞',
        '冷沉淀凝血因子',
        '拟:Rh(-)悬浮红细胞',
        '拟:辐照单采血小板',
        '拟:辐照悬浮红细胞',
        '拟:冷沉淀凝血因子',
        '拟:去白细胞悬浮红细胞',
        '拟:洗涤红细胞',
        '拟:悬浮红细胞',
        '拟:血浆',
        '去白细胞悬浮红细胞',
        '特殊介质交叉配血(微柱凝胶法)',
        '特殊血型抗原鉴定',
        '洗涤红细胞',
        '新鲜冰冻血浆',
        '悬浮红细胞',
        '血小板交叉配合实验',
        '血小板特异性和组织相关融性(HLA)抗体检测',
        '血型单特异性抗体鉴定',
        '血型抗体特异性鉴定（放散）',
        '血型抗体特异性鉴定（吸收试验）',
        '盐水介质+凝聚胺配血',
        '盐水介质交叉配血',
        '直接抗人球蛋白试验',
        '血型抗体效价测定（IgG+IgM）'
    )
),

-- 血库额外工作量（入库出库等）
blood_bank_workload AS (
    SELECT 
        SUM(CASE 
            WHEN "kcjl" = '出库记录' AND "xx1" = '合计' AND "js1" = '袋'
                AND "xx2" = '合计' AND "js2" = '袋'
                AND "xx3" = '合计' AND "js3" = '袋'
                AND "xx4" = '合计' AND "js4" = '袋'
            THEN "hxb1" + "xj1" + "xxb1" + "lcd1"
            ELSE 0 
        END) as "出库袋数",
        SUM(CASE 
            WHEN "kcjl" = '入库记录' AND "xx1" = '合计' AND "js1" = '袋'
                AND "xx2" = '合计' AND "js2" = '袋'
                AND "xx3" = '合计' AND "js3" = '袋'
                AND "xx4" = '合计' AND "js4" = '袋'
            THEN "hxb1" + "xj1" + "xxb1" + "lcd1"
            ELSE 0 
        END) as "入库袋数"
    FROM (
        -- 出库记录合计
        SELECT '出库记录' as "kcjl", 
               '合计' as "xx1", '袋' as "js1",
               COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1",
               '合计' as "xx2", '袋' as "js2",
               COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1",
               '合计' as "xx3", '袋' as "js3",
               COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1",
               '合计' as "xx4", '袋' as "js4",
               COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1"
        FROM hid0117_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a 
        INNER JOIN hid0117_orcl_lis_xhbis.bis6_match_blood_type b 
            ON a."blood_type_id" = b."blood_type_id" AND b."isdeleted" = '0'
        INNER JOIN hid0117_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c 
            ON b."component_id" = c."component_id" AND c."isdeleted" = '0'
        INNER JOIN hid0117_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d 
            ON a."inspection_id" = d."inspection_id" AND d."isdeleted" = '0'
        WHERE a."isdeleted" = '0'
          AND a."out_date" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
          AND a."out_date" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
          
        UNION ALL
        
        -- 入库记录合计
        SELECT '入库记录' as "kcjl",
               '合计' as "xx1", '袋' as "js1",
               COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1",
               '合计' as "xx2", '袋' as "js2",
               COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1",
               '合计' as "xx3", '袋' as "js3",
               COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1",
               '合计' as "xx4", '袋' as "js4",
               COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1"
        FROM hid0117_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a 
        INNER JOIN hid0117_orcl_lis_xhbis.bis6_match_blood_type b 
            ON a."blood_type_id" = b."blood_type_id" AND b."isdeleted" = '0'
        INNER JOIN hid0117_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c 
            ON b."component_id" = c."component_id" AND c."isdeleted" = '0'
        WHERE a."isdeleted" = '0'
          AND a."in_time" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
          AND a."in_time" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
    ) blood_data
),

-- 抗体筛查阳性统计
antibody_screening AS (
    SELECT COUNT(1) as "抗体筛查阳性数"
    FROM hid0117_orcl_lis_xhdata.lis6_inspect_sample a
    INNER JOIN hid0117_orcl_lis_dbo.LIS_INSPECTION_RESULT b 
        ON a."INSPECTION_ID" = b."INSPECTION_ID"
        AND b."TEST_ITEM_ID" = '3573'
        AND b."isdeleted" = '0'
    INNER JOIN hid0117_orcl_lis_dbo.LIS_INSPECTION_RESULT c 
        ON a."INSPECTION_ID" = c."INSPECTION_ID"  
        AND c."TEST_ITEM_ID" = '3600'
        AND c."isdeleted" = '0'
    LEFT JOIN hid0117_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST d 
        ON a."INSPECTION_ID" = d."INSPECTION_ID"
        AND d."SPECIAL_TYPE" = '疑难'
        AND d."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
      AND c."QUANTITATIVE_RESULT" = '阳性'
      AND a."OUTPATIENT_ID" IS NOT NULL 
      AND a."PATIENT_NAME" IS NOT NULL
      AND UPPER(a."PATIENT_NAME") NOT LIKE '%QC%'
      AND a."INPUT_TIME" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
      AND a."INPUT_TIME" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
),

-- 治疗性单采统计
therapeutic_collection AS (
    SELECT COUNT(DISTINCT "Order_Main_OrderID") as "治疗性单采数"
    FROM datacenter_db.Order_Main 
    WHERE "Order_Main_RecDeptName" IN ('输血科','锦江输血科')
      AND "Order_Main_OrderItemCode" IN ('666600613','666000570','666000571','666600598','666000510')
      AND "Order_Main_IsDeleted" = '0'
      AND "Order_Main_OrderDtTm" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
      AND "Order_Main_OrderDtTm" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
      AND "medorgcode" = 'HID0101'
),

-- 盘点工作量
inventory_workload AS (
    SELECT SUM(CAST("finished_amount" AS DOUBLE)) as "盘点量"
    FROM hid0117_orcl_lis_xhbis.bis6_blood_inventory  
    WHERE "inventory_time" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
      AND "inventory_time" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
)

-- 最终输出：三个核心指标
SELECT 
    date_format(date_add('month', -1, current_date), '%Y-%m') as "统计月份",
    '输血科' as "运管科室",
    '主院区' as "运管院区",
    
    -- 指标1：检测标本数（各类工作量的总和）
    (SELECT SUM("工作量") FROM base_stats) as "检测标本数",
    
    -- 指标2：检测项目数（符合条件的项目种类数，血型抗体效价算4个）
    (SELECT COUNT(*) FROM project_list) + 
    (SELECT CASE WHEN COUNT(*) > 0 THEN 3 ELSE 0 END 
     FROM base_stats 
     WHERE "项目名称" = '血型抗体效价测定（IgG+IgM）') as "检测项目数",
    
    -- 指标3：总工作量（基础工作量 + 血库工作量 + 抗体筛查 + 治疗性单采 + 盘点）
    (SELECT SUM("工作量") FROM base_stats) +
    (SELECT COALESCE("出库袋数", 0) + COALESCE("入库袋数", 0) FROM blood_bank_workload) +
    (SELECT COALESCE("抗体筛查阳性数", 0) FROM antibody_screening) +
    (SELECT COALESCE("治疗性单采数", 0) FROM therapeutic_collection) +
    (SELECT COALESCE("盘点量", 0) FROM inventory_workload) as "总工作量";

