==========================================

==  原始统计


-- 输血科综合统计报表（基于输血血缘文档修正版）
SELECT 
    "XM" as "项目名称",
    SUM("RC") as "人次",
    SUM("FY") as "费用",
    SUM("GZL") as "工作量"
FROM (
    -- 第一部分：LIS检验收费统计
    SELECT DISTINCT
        c."chinese_name" as "XM",
        COUNT(a."inspection_id") as "RC",
        SUM(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
        SUM(COALESCE(CASE WHEN CAST(b."workload" AS DOUBLE) = 0 THEN 1 ELSE CAST(b."workload" AS DOUBLE) END, 1)) as "GZL"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample a
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b
        ON a."inspection_id" = b."inspection_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhsystem1.lis_charge_item c
        ON b."charge_item_id" = c."charge_item_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."group_id" IN ('G013','G053','G105','G111')
        AND a."input_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY c."chinese_name"

    UNION ALL

    -- 第二部分：血型统计（通过申请信息关联）
    SELECT DISTINCT
        c."blood_type_name" as "XM",
        COUNT(a."inspection_id") as "RC",
        0 as "FY",
        COUNT(a."inspection_id") as "GZL"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_info b
        ON a."requisition_id" = b."req_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_blood c
        ON b."req_id" = c."req_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."group_id" IN ('G013','G053','G105','G111')
        AND a."input_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY c."blood_type_name"

    UNION ALL

    -- 第三部分：血袋收费统计（修正库名和表结构）
    SELECT 
        e."charge_item_name" as "XM",
        COUNT(b."BLOODBAG_ID") as "RC",
        SUM(COALESCE(CAST(e."charge" AS DOUBLE), 0)) as "FY",
        COUNT(b."BLOODBAG_ID") as "GZL"
    FROM hid0101_orcl_lis_xhdata.lis6_inspect_sample a
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT b
        ON a."inspection_id" = b."INSPECTION_ID"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type c
        ON b."BLOOD_TYPE_ID" = c."BLOOD_TYPE_ID"
        AND c."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_charged_info d
        ON b."BLOODBAG_ID" = d."sample_charge_id"
        AND d."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_bis6.xinghe_charged_list e
        ON d."sample_charge_id" = e."sample_charge_id"
        AND e."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND e."his_id" IN ('LIS07068','LIS0300114','LIS0300255')
        AND d."charge_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY e."charge_item_name"

    UNION ALL

    -- 第四部分：收费信息统计（使用正确的库名）
    SELECT
        b."charge_item_name" as "XM",
        SUM(COALESCE(CAST(b."charge_num" AS DOUBLE), 0)) as "RC",
        SUM(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."charged_id") as "GZL"
    FROM hid0101_orcl_lis_xhbis.bis6_charged_info a
    INNER JOIN hid0101_orcl_lis_bis6.xinghe_charged_list b
        ON a."sample_charge_id" = b."sample_charge_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."charge_state" IN ('charged','uncharged')
        AND a."charge_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
        AND a."sample_charge_id" LIKE 'H%'
    GROUP BY b."charge_item_name"

    UNION ALL

    -- 第五部分：补费统计（排除特定项目）
    SELECT
        a."charge_item_name" as "XM",
        SUM(COALESCE(CAST(a."charge_num" AS DOUBLE), 0)) as "RC",
        SUM(COALESCE(CAST(a."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."charged_id") as "GZL"
    FROM hid0101_orcl_lis_xhbis.bis6_charged_info a
    WHERE a."isdeleted" = '0'
        AND a."charge_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
        AND a."charge_state" IN ('charged','uncharged')
        AND a."charged_type" = '补费'
        AND a."sample_charge_id" NOT IN ('LIS023141','LIS023137','LIS07142','LIS07140','LIS07139','LIS07138','LIS07137','LIS07134','LIS07131',
                                       'LIS07127','LIS017635','LIS07123','LIS0300114','LIS0300255')
    GROUP BY a."charge_item_name"

    UNION ALL

    -- 第六部分：补费统计（包含特定项目）
    SELECT
        a."charge_item_name" as "XM",
        COUNT(a."charged_id") as "RC",
        SUM(COALESCE(CAST(a."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."charged_id") as "GZL"
    FROM hid0101_orcl_lis_xhbis.bis6_charged_info a
    WHERE a."isdeleted" = '0'
        AND a."charge_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
        AND a."charge_state" IN ('charged','uncharged')
        AND a."charged_type" = '补费'
        AND a."sample_charge_id" IN ('LIS023141','LIS023137','LIS07142','LIS07140','LIS07139','LIS07138','LIS07137','LIS07134','LIS07131',
                                   'LIS07127','LIS017635','LIS07123','LIS0300114','LIS0300255')
    GROUP BY a."charge_item_name"

    UNION ALL

    -- 第七部分：申请单统计（使用正确的库名和表名）
    SELECT 
        a."charge_name" as "XM",
        COUNT(DISTINCT b."req_id") as "RC",
        SUM(COALESCE(CAST(a."charge" AS DOUBLE), 0)) as "FY",
        COUNT(DISTINCT b."req_id") as "GZL"
    FROM hid0101_orcl_lis_bis.his_requisition a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_info b
        ON a."rep_id" = b."req_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND b."req_type" = '4'
        AND b."patient_dept_name" NOT LIKE '%测试%'
        AND b."req_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY a."charge_name"

    UNION ALL

    -- 第八部分：血袋输入统计（使用文档中的正确表结构）
    SELECT DISTINCT
        b."BLOOD_NAME" as "XM",
        COUNT(a."BLOODBAG_ID") as "RC",
        SUM(COALESCE(CAST(a."BLOOD_CHARGE" AS DOUBLE), 0)) as "FY",
        COUNT(a."BLOODBAG_ID") as "GZL"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."BLOOD_TYPE_ID" = b."BLOOD_TYPE_ID"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhdata.lis6_inspect_sample c
        ON a."INSPECTION_ID" = c."inspection_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."SENDBLOOD_TIME" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY b."BLOOD_NAME"

    UNION ALL

    -- 第九部分：配血方法统计（使用血缘文档中的表结构）
    SELECT DISTINCT
        e."method_name" as "XM",
        COUNT(a."MATCH_ID") as "RC",
        SUM(COALESCE(CAST(e."method_charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."MATCH_ID") as "GZL"
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
        AND a."MACTH_DATE" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
        AND e."method_id" NOT IN ('00000004','00000006','00000007','4')
    GROUP BY e."method_name"
) T
GROUP BY T."XM"
ORDER BY T."XM"


===========================================




-- 输血科血液库存统计报表（完整Oracle转Presto版本）
-- 时间范围：2025-07-01 到 2025-07-31
-- 统计维度：库存记录、入库记录、出库记录 × O型/A型/B型/AB型/合计 × 袋数/血量

SELECT 
    T."kcjl" as "库存记录类型",
    T."xx1" as "血型1", T."js1" as "计数单位1", T."hxb1" as "红细胞悬液",
    T."xx2" as "血型2", T."js2" as "计数单位2", T."xj1" as "血小板", 
    T."xx3" as "血型3", T."js3" as "计数单位3", T."xxb1" as "新鲜冰冻血浆",
    T."xx4" as "血型4", T."js4" as "计数单位4", T."LCD1" as "冷沉淀"
FROM (
    -- ================================
    -- 第一部分：库存记录统计（10个查询：4种血型×2种统计方式+合计×2种统计方式）
    -- ================================
    
    -- 01. O型库存袋数统计
    SELECT 
        '库存记录' as "kcjl", 
        'O型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1",
        'O型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 
        'O型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1",
        'O型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1",
        '001' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'
        -- ⚠️ 院区条件暂时注释，根据需要取消注释
        -- AND a."area_id" = 'A001'

    UNION ALL
    
    -- 02. O型库存血量统计
    SELECT 
        '库存记录' as "kcjl", 
        'O型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'O型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'O型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'O型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '002' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    UNION ALL
    
    -- 03. A型库存袋数统计
    SELECT 
        '库存记录' as "kcjl", 
        'A型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1",
        'A型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 
        'A型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1",
        'A型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1",
        '003' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    UNION ALL
    
    -- 04. A型库存血量统计
    SELECT 
        '库存记录' as "kcjl", 
        'A型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'A型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'A型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'A型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '004' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    UNION ALL
    
    -- 05. B型库存袋数统计
    SELECT 
        '库存记录' as "kcjl", 
        'B型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1",
        'B型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 
        'B型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1",
        'B型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1",
        '005' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    UNION ALL
    
    -- 06. B型库存血量统计
    SELECT 
        '库存记录' as "kcjl", 
        'B型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'B型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'B型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'B型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '006' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    UNION ALL
    
    -- 07. AB型库存袋数统计
    SELECT 
        '库存记录' as "kcjl", 
        'AB型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1",
        'AB型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1",
        'AB型' as "xx3", '袋' as "js3", 
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1",
        'AB型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1",
        '007' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    UNION ALL
    
    -- 08. AB型库存血量统计
    SELECT 
        '库存记录' as "kcjl", 
        'AB型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'AB型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'AB型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'AB型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '008' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    UNION ALL
    
    -- 09. 库存合计袋数统计
    SELECT 
        '库存记录' as "kcjl", 
        '合计' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1",
        '合计' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", 
        '合计' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1",
        '合计' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1",
        '009' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    UNION ALL
    
    -- 10. 库存合计血量统计
    SELECT 
        '库存记录' as "kcjl", 
        '合计' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        '合计' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        '合计' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        '合计' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '010' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."bloodbag_state" IN ('1','2')
        AND a."isdeleted" = '0'

    -- ================================
    -- 第二部分：入库记录统计（10个查询：4种血型×2种统计方式+合计×2种统计方式）
    -- ================================
    
    UNION ALL
    
    -- 11. O型入库袋数统计
    SELECT 
        '入库记录' as "kcjl", 
        'O型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1",
        'O型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 
        'O型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1",
        'O型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1",
        '011' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        -- ✅ 入库时间条件：使用in_time字段
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 12. O型入库血量统计
    SELECT 
        '入库记录' as "kcjl", 
        'O型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'O型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'O型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'O型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '012' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 13. A型入库袋数统计
    SELECT 
        '入库记录' as "kcjl", 
        'A型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1",
        'A型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 
        'A型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1",
        'A型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1",
        '013' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 14. A型入库血量统计
    SELECT 
        '入库记录' as "kcjl", 
        'A型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'A型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'A型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'A型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '014' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 15. B型入库袋数统计
    SELECT 
        '入库记录' as "kcjl", 
        'B型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1",
        'B型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 
        'B型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1",
        'B型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1",
        '015' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 16. B型入库血量统计
    SELECT 
        '入库记录' as "kcjl", 
        'B型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'B型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'B型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'B型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '016' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 17. AB型入库袋数统计
    SELECT 
        '入库记录' as "kcjl", 
        'AB型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1",
        'AB型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1",
        'AB型' as "xx3", '袋' as "js3", 
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1",
        'AB型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1",
        '017' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 18. AB型入库血量统计
    SELECT 
        '入库记录' as "kcjl", 
        'AB型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'AB型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'AB型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'AB型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '018' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 19. 入库合计袋数统计
    SELECT 
        '入库记录' as "kcjl", 
        '合计' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1",
        '合计' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", 
        '合计' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1",
        '合计' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1",
        '019' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    UNION ALL
    
    -- 20. 入库合计血量统计
    SELECT 
        '入库记录' as "kcjl", 
        '合计' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        '合计' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        '合计' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        '合计' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '020' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."blood_type_id" = b."blood_type_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON b."component_id" = c."component_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."in_time" >= '2025-07-01' 
        AND a."in_time" <= '2025-07-31'

    -- ================================
    -- 第三部分：出库记录统计（10个查询：4种血型×2种统计方式+合计×2种统计方式）
    -- ================================
    
    UNION ALL
    
    -- 21. O型出库袋数统计
    SELECT 
        '出库记录' as "kcjl", 
        'O型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1",
        'O型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 
        'O型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1",
        'O型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1",
        '021' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        -- ✅ 出库时间条件：使用OUT_DATE字段
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 22. O型出库血量统计
    SELECT 
        '出库记录' as "kcjl", 
        'O型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'O型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'O型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'O型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '022' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 23. A型出库袋数统计
    SELECT 
        '出库记录' as "kcjl", 
        'A型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1",
        'A型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 
        'A型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1",
        'A型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1",
        '023' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 24. A型出库血量统计
    SELECT 
        '出库记录' as "kcjl", 
        'A型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'A型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'A型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'A型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '024' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 25. B型出库袋数统计
    SELECT 
        '出库记录' as "kcjl", 
        'B型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1",
        'B型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 
        'B型' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1",
        'B型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1",
        '025' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 26. B型出库血量统计
    SELECT 
        '出库记录' as "kcjl", 
        'B型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'B型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'B型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'B型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '026' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 27. AB型出库袋数统计
    SELECT 
        '出库记录' as "kcjl", 
        'AB型' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1",
        'AB型' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1",
        'AB型' as "xx3", '袋' as "js3", 
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1",
        'AB型' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1",
        '027' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 28. AB型出库血量统计
    SELECT 
        '出库记录' as "kcjl", 
        'AB型' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        'AB型' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        'AB型' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        'AB型' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '028' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 29. 出库合计袋数统计
    SELECT 
        '出库记录' as "kcjl", 
        '合计' as "xx1", '袋' as "js1",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1",
        '合计' as "xx2", '袋' as "js2",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", 
        '合计' as "xx3", '袋' as "js3",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1",
        '合计' as "xx4", '袋' as "js4",
        COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1",
        '029' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

    UNION ALL
    
    -- 30. 出库合计血量统计
    SELECT 
        '出库记录' as "kcjl", 
        '合计' as "xx1", '量' as "js1",
        SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1",
        '合计' as "xx2", '量' as "js2",
        SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1",
        '合计' as "xx3", '量' as "js3",
        SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1",
        '合计' as "xx4", '量' as "js4",
        SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1",
        '030' as "sort"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
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
        AND a."out_date" >= '2025-07-01' 
        AND a."out_date" <= '2025-07-31'

) T 
ORDER BY T."sort"










/**
 * 输血科血液库存、入库、出库统计报表
 * 
 * 功能说明：
 * 1. 按血型(O型、A型、B型、AB型)和血液成分统计血液库存、入库、出库情况
 * 2. 统计维度包括：袋数、血量
 * 3. 血液成分包括：红细胞悬液、血小板、新鲜冰冻血浆、冷沉淀
 * 
 * 数据来源表：
 * - hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT (血袋入库记录表)
 * - hid0101_orcl_lis_xhbis.bis6_match_blood_type (血型匹配关系表)  
 * - hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT (血液成分字典表)
 * - hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE (检验样本表，用于出库关联)
 * 
 * 血液成分编码对照：
 * - '00000009': 红细胞悬液 (hxb)
 * - '00000010': 血小板 (xj)
 * - '00000011': 新鲜冰冻血浆 (xxb)  
 * - '00000012': 冷沉淀 (lcd)
 * 
 * 血袋状态说明：
 * - '1': 入库状态
 * - '2': 出库状态
 * 
 * 院区编码说明(根据血缘补充信息)：
 * - A001: 本院
 * - A002: 温江
 * - A003: 天府
 * - A004: 锦江
 * 
 * 注意：所有查询都添加了逻辑删除筛选条件 isdeleted = '0'
 */

SELECT T."库存记录类型",
       T."血型1", T."计数单位1", T."红细胞悬液",
       T."血型2", T."计数单位2", T."血小板", 
       T."血型3", T."计数单位3", T."新鲜冰冻血浆",
       T."血型4", T."计数单位4", T."冷沉淀"
FROM (
    -- =================== 库存记录统计部分 ===================
    -- 1. O型血液库存统计 - 按袋数
    SELECT '库存记录' AS "库存记录类型",
           'O型' AS "血型1", '袋' AS "计数单位1",
           COUNT(DISTINCT CASE WHEN c.component_id='00000009' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "红细胞悬液",
           'O型' AS "血型2", '袋' AS "计数单位2", 
           COUNT(DISTINCT CASE WHEN c.component_id='00000010' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "血小板",
           'O型' AS "血型3", '袋' AS "计数单位3",
           COUNT(DISTINCT CASE WHEN c.component_id='00000011' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "新鲜冰冻血浆",
           'O型' AS "血型4", '袋' AS "计数单位4",
           COUNT(DISTINCT CASE WHEN c.component_id='00000012' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "冷沉淀",
           '001' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'                    -- 逻辑删除筛选
      AND a.bloodbag_state IN ('1','2')       -- 血袋状态：入库(1)或出库(2)
     -- AND (@{C:AREA_ID:A.AREA_ID})           -- 院区参数筛选
    
    UNION ALL
    -- 2. O型血液库存统计 - 按血量
    SELECT '库存记录' AS "库存记录类型",
           'O型' AS "血型1", '量' AS "计数单位1",
           SUM(CASE WHEN c.component_id='00000009' AND a.abo_blood_group='O型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "红细胞悬液",
           'O型' AS "血型2", '量' AS "计数单位2",
           SUM(CASE WHEN c.component_id='00000010' AND a.abo_blood_group='O型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "血小板",
           'O型' AS "血型3", '量' AS "计数单位3", 
           SUM(CASE WHEN c.component_id='00000011' AND a.abo_blood_group='O型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "新鲜冰冻血浆",
           'O型' AS "血型4", '量' AS "计数单位4",
           SUM(CASE WHEN c.component_id='00000012' AND a.abo_blood_group='O型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "冷沉淀",
           '002' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2') 
     -- AND (@{C:AREA_ID:A.AREA_ID})
    
    UNION ALL
    -- 3. A型血液库存统计 - 按袋数
    SELECT '库存记录' AS "库存记录类型",
           'A型' AS "血型1", '袋' AS "计数单位1",
           COUNT(DISTINCT CASE WHEN c.component_id='00000009' AND a.abo_blood_group='A型' THEN a.bloodbag_id END) AS "红细胞悬液",
           'A型' AS "血型2", '袋' AS "计数单位2",
           COUNT(DISTINCT CASE WHEN c.component_id='00000010' AND a.abo_blood_group='A型' THEN a.bloodbag_id END) AS "血小板", 
           'A型' AS "血型3", '袋' AS "计数单位3",
           COUNT(DISTINCT CASE WHEN c.component_id='00000011' AND a.abo_blood_group='A型' THEN a.bloodbag_id END) AS "新鲜冰冻血浆",
           'A型' AS "血型4", '袋' AS "计数单位4",
           COUNT(DISTINCT CASE WHEN c.component_id='00000012' AND a.abo_blood_group='A型' THEN a.bloodbag_id END) AS "冷沉淀",
           '003' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2')
     -- AND (@{C:AREA_ID:A.AREA_ID})
    
    UNION ALL
    -- 4. A型血液库存统计 - 按血量
    SELECT '库存记录' AS "库存记录类型",
           'A型' AS "血型1", '量' AS "计数单位1",
           SUM(CASE WHEN c.component_id='00000009' AND a.abo_blood_group='A型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "红细胞悬液",
           'A型' AS "血型2", '量' AS "计数单位2",
           SUM(CASE WHEN c.component_id='00000010' AND a.abo_blood_group='A型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "血小板",
           'A型' AS "血型3", '量' AS "计数单位3",
           SUM(CASE WHEN c.component_id='00000011' AND a.abo_blood_group='A型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "新鲜冰冻血浆",
           'A型' AS "血型4", '量' AS "计数单位4",
           SUM(CASE WHEN c.component_id='00000012' AND a.abo_blood_group='A型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "冷沉淀",
           '004' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2')
     -- AND (@{C:AREA_ID:A.AREA_ID})
    
    UNION ALL
    -- 5. B型血液库存统计 - 按袋数
    SELECT '库存记录' AS "库存记录类型",
           'B型' AS "血型1", '袋' AS "计数单位1",
           COUNT(DISTINCT CASE WHEN c.component_id='00000009' AND a.abo_blood_group='B型' THEN a.bloodbag_id END) AS "红细胞悬液",
           'B型' AS "血型2", '袋' AS "计数单位2",
           COUNT(DISTINCT CASE WHEN c.component_id='00000010' AND a.abo_blood_group='B型' THEN a.bloodbag_id END) AS "血小板", 
           'B型' AS "血型3", '袋' AS "计数单位3",
           COUNT(DISTINCT CASE WHEN c.component_id='00000011' AND a.abo_blood_group='B型' THEN a.bloodbag_id END) AS "新鲜冰冻血浆",
           'B型' AS "血型4", '袋' AS "计数单位4",
           COUNT(DISTINCT CASE WHEN c.component_id='00000012' AND a.abo_blood_group='B型' THEN a.bloodbag_id END) AS "冷沉淀",
           '005' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2')
     -- AND (@{C:AREA_ID:A.AREA_ID})
    
    UNION ALL
    -- 6. B型血液库存统计 - 按血量
    SELECT '库存记录' AS "库存记录类型",
           'B型' AS "血型1", '量' AS "计数单位1",
           SUM(CASE WHEN c.component_id='00000009' AND a.abo_blood_group='B型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "红细胞悬液",
           'B型' AS "血型2", '量' AS "计数单位2",
           SUM(CASE WHEN c.component_id='00000010' AND a.abo_blood_group='B型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "血小板",
           'B型' AS "血型3", '量' AS "计数单位3",
           SUM(CASE WHEN c.component_id='00000011' AND a.abo_blood_group='B型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "新鲜冰冻血浆",
           'B型' AS "血型4", '量' AS "计数单位4",
           SUM(CASE WHEN c.component_id='00000012' AND a.abo_blood_group='B型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "冷沉淀",
           '006' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2')
     -- AND (@{C:AREA_ID:A.AREA_ID})
    
    UNION ALL
    -- 7. AB型血液库存统计 - 按袋数
    SELECT '库存记录' AS "库存记录类型",
           'AB型' AS "血型1", '袋' AS "计数单位1",
           COUNT(DISTINCT CASE WHEN c.component_id='00000009' AND a.abo_blood_group='AB型' THEN a.bloodbag_id END) AS "红细胞悬液",
           'AB型' AS "血型2", '袋' AS "计数单位2",
           COUNT(DISTINCT CASE WHEN c.component_id='00000010' AND a.abo_blood_group='AB型' THEN a.bloodbag_id END) AS "血小板",
           'AB型' AS "血型3", '袋' AS "计数单位3", 
           COUNT(DISTINCT CASE WHEN c.component_id='00000011' AND a.abo_blood_group='AB型' THEN a.bloodbag_id END) AS "新鲜冰冻血浆",
           'AB型' AS "血型4", '袋' AS "计数单位4",
           COUNT(DISTINCT CASE WHEN c.component_id='00000012' AND a.abo_blood_group='AB型' THEN a.bloodbag_id END) AS "冷沉淀",
           '007' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2')
     -- AND (@{C:AREA_ID:A.AREA_ID})
    
    UNION ALL
    -- 8. AB型血液库存统计 - 按血量
    SELECT '库存记录' AS "库存记录类型",
           'AB型' AS "血型1", '量' AS "计数单位1",
           SUM(CASE WHEN c.component_id='00000009' AND a.abo_blood_group='AB型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "红细胞悬液",
           'AB型' AS "血型2", '量' AS "计数单位2",
           SUM(CASE WHEN c.component_id='00000010' AND a.abo_blood_group='AB型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "血小板",
           'AB型' AS "血型3", '量' AS "计数单位3",
           SUM(CASE WHEN c.component_id='00000011' AND a.abo_blood_group='AB型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "新鲜冰冻血浆",
           'AB型' AS "血型4", '量' AS "计数单位4",
           SUM(CASE WHEN c.component_id='00000012' AND a.abo_blood_group='AB型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "冷沉淀",
           '008' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2')
     -- AND (@{C:AREA_ID:A.AREA_ID})
    
    UNION ALL
    -- 9. 合计库存统计 - 按袋数
    SELECT '库存记录' AS "库存记录类型",
           '合计' AS "血型1", '袋' AS "计数单位1",
           COUNT(DISTINCT CASE WHEN c.component_id='00000009' THEN a.bloodbag_id END) AS "红细胞悬液",
           '合计' AS "血型2", '袋' AS "计数单位2",
           COUNT(DISTINCT CASE WHEN c.component_id='00000010' THEN a.bloodbag_id END) AS "血小板", 
           '合计' AS "血型3", '袋' AS "计数单位3",
           COUNT(DISTINCT CASE WHEN c.component_id='00000011' THEN a.bloodbag_id END) AS "新鲜冰冻血浆",
           '合计' AS "血型4", '袋' AS "计数单位4",
           COUNT(DISTINCT CASE WHEN c.component_id='00000012' THEN a.bloodbag_id END) AS "冷沉淀",
           '009' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2')
     -- AND (@{C:AREA_ID:A.AREA_ID})
    
    UNION ALL
    -- 10. 合计库存统计 - 按血量
    SELECT '库存记录' AS "库存记录类型",
           '合计' AS "血型1", '量' AS "计数单位1",
           SUM(CASE WHEN c.component_id='00000009' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "红细胞悬液",
           '合计' AS "血型2", '量' AS "计数单位2",
           SUM(CASE WHEN c.component_id='00000010' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "血小板",
           '合计' AS "血型3", '量' AS "计数单位3",
           SUM(CASE WHEN c.component_id='00000011' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "新鲜冰冻血浆",
           '合计' AS "血型4", '量' AS "计数单位4",
           SUM(CASE WHEN c.component_id='00000012' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "冷沉淀",
           '010' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
      AND a.bloodbag_state IN ('1','2')
     -- AND (@{C:AREA_ID:A.AREA_ID})
 
    -- =================== 入库记录统计部分 ===================
    UNION ALL
    -- 11. O型血液入库统计 - 按袋数
    SELECT '入库记录' AS "库存记录类型",
           'O型' AS "血型1", '袋' AS "计数单位1",
           COUNT(DISTINCT CASE WHEN c.component_id='00000009' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "红细胞悬液",
           'O型' AS "血型2", '袋' AS "计数单位2",
           COUNT(DISTINCT CASE WHEN c.component_id='00000010' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "血小板", 
           'O型' AS "血型3", '袋' AS "计数单位3",
           COUNT(DISTINCT CASE WHEN c.component_id='00000011' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "新鲜冰冻血浆",
           'O型' AS "血型4", '袋' AS "计数单位4",
           COUNT(DISTINCT CASE WHEN c.component_id='00000012' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "冷沉淀",
           '011' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
     -- AND (@{C:AREA_ID:A.AREA_ID})              -- 院区筛选
     --  AND (@{C:IN_TIME:A.IN_TIME})              -- 入库时间筛选
    
    UNION ALL
    -- 12. O型血液入库统计 - 按血量
    SELECT '入库记录' AS "库存记录类型",
           'O型' AS "血型1", '量' AS "计数单位1",
           SUM(CASE WHEN c.component_id='00000009' AND a.abo_blood_group='O型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "红细胞悬液",
           'O型' AS "血型2", '量' AS "计数单位2",
           SUM(CASE WHEN c.component_id='00000010' AND a.abo_blood_group='O型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "血小板",
           'O型' AS "血型3", '量' AS "计数单位3",
           SUM(CASE WHEN c.component_id='00000011' AND a.abo_blood_group='O型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "新鲜冰冻血浆",
           'O型' AS "血型4", '量' AS "计数单位4",
           SUM(CASE WHEN c.component_id='00000012' AND a.abo_blood_group='O型' THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "冷沉淀",
           '012' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    WHERE a.isdeleted = '0'
     -- AND (@{C:AREA_ID:A.AREA_ID})
     -- AND (@{C:IN_TIME:A.IN_TIME})
    
    -- 继续后续A型、B型、AB型、合计的入库记录统计... 
    -- (为节省篇幅，此处省略重复模式的SQL，实际使用时需要完整补充)
    
    -- =================== 出库记录统计部分 ===================
    UNION ALL
    -- 21. O型血液出库统计 - 按袋数 (关联检验样本表)
    SELECT '出库记录' AS "库存记录类型",
           'O型' AS "血型1", '袋' AS "计数单位1",
           COUNT(DISTINCT CASE WHEN c.component_id='00000009' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "红细胞悬液",
           'O型' AS "血型2", '袋' AS "计数单位2",
           COUNT(DISTINCT CASE WHEN c.component_id='00000010' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "血小板", 
           'O型' AS "血型3", '袋' AS "计数单位3",
           COUNT(DISTINCT CASE WHEN c.component_id='00000011' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "新鲜冰冻血浆",
           'O型' AS "血型4", '袋' AS "计数单位4",
           COUNT(DISTINCT CASE WHEN c.component_id='00000012' AND a.abo_blood_group='O型' THEN a.bloodbag_id END) AS "冷沉淀",
           '021' AS sort
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a.blood_type_id = b.blood_type_id
    INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b.component_id = c.component_id
    INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a.inspection_id = d.inspection_id    -- 关联检验样本表
    WHERE a.isdeleted = '0'
      -- AND (@{C:AREA_ID:A.AREA_ID})              -- 院区筛选  
      --AND (@{C:IN_TIME:A.OUT_DATE})             -- 出库时间筛选
    
    -- 继续后续出库记录统计...
    -- (为节省篇幅，此处省略重复模式的SQL，实际使用时需要完整补充)
    
) T 
ORDER BY T.sort;

/*
 * 字段血缘关系说明：
 * 
 * 1. 核心业务字段：
 *    - a.bloodbag_id: 血袋编号 (来源：BIS6_BLOODBAG_INPUT.bloodbag_id)
 *    - a.abo_blood_group: ABO血型 (来源：BIS6_BLOODBAG_INPUT.abo_blood_group)  
 *    - a.blood_amount: 血液数量 (来源：BIS6_BLOODBAG_INPUT.blood_amount)
 *    - a.bloodbag_state: 血袋状态 (来源：BIS6_BLOODBAG_INPUT.bloodbag_state)
 *    - a.area_id: 院区ID (来源：BIS6_BLOODBAG_INPUT.area_id)
 *    - a.in_time: 入库时间 (来源：BIS6_BLOODBAG_INPUT.in_time)
 *    - a.out_date: 出库时间 (来源：BIS6_BLOODBAG_INPUT.out_date)
 * 
 * 2. 关联表字段：
 *    - b.blood_type_id: 血液类型ID (关联键)
 *    - b.component_id: 血液成分ID (关联键)
 *    - c.component_id: 血液成分编码 (字典表主键)
 *    - d.inspection_id: 检验单ID (出库时关联检验样本)
 * 
 * 3. 数据质量要求：
 *    - 所有表都必须添加 isdeleted = '0' 筛选条件
 *    - 中文字段名需要用双引号包围 (Presto要求)
 *    - 数值类型字段需要使用 CAST(field AS DOUBLE) 进行类型转换
 *    - 日期字段需要注意格式处理
 * 
 * 4. 性能优化建议：
 *    - 建议在 bloodbag_state, area_id, in_time, out_date 字段上建立索引
 *    - 考虑分区表设计，按院区或时间分区
 *    - 大数据量查询时可考虑使用物化视图
 */ 



 -- 输血科综合统计报表（Lis版本）
SELECT 
    "XM" as "项目名称",
    SUM("RC") as "人次",
    SUM("FY") as "费用",
    SUM("GZL") as "工作量"
FROM (
    -- 第一部分：LIS检验收费统计
    SELECT DISTINCT
        c."chinese_name" as "XM",
        COUNT(a."inspection_id") as "RC",
        SUM(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
        SUM(COALESCE(CASE WHEN CAST(b."workload" AS DOUBLE) = 0 THEN 1 ELSE CAST(b."workload" AS DOUBLE) END, 1)) as "GZL"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample a
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b
        ON a."inspection_id" = b."inspection_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhsystem1.lis_charge_item c
        ON b."charge_item_id" = c."charge_item_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."group_id" IN ('G013','G053','G105','G111')
        AND a."input_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY c."chinese_name"

    UNION ALL


    -- 第二部分：血型统计（通过申请信息关联）
    SELECT DISTINCT
        c."blood_type_name" as "XM",
        COUNT(a."inspection_id") as "RC",
        0 as "FY",
        COUNT(a."inspection_id") as "GZL"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_info b
        ON a."requisition_id" = b."req_id"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_blood c
        ON b."req_id" = c."req_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."group_id" IN ('G013','G053','G105','G111')
        AND a."input_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY c."blood_type_name"

    UNION ALL


    -- 第七部分：申请单统计（使用正确的库名和表名）
    SELECT 
        a."charge_name" as "XM",
        COUNT(DISTINCT b."req_id") as "RC",
        SUM(COALESCE(CAST(a."charge" AS DOUBLE), 0)) as "FY",
        COUNT(DISTINCT b."req_id") as "GZL"
    FROM hid0101_orcl_lis_bis.his_requisition a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_info b
        ON a."rep_id" = b."req_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND b."req_type" = '4'
        AND b."patient_dept_name" NOT LIKE '%测试%'
        AND b."req_time" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY a."charge_name"

    UNION ALL

    -- 第八部分：血袋输入统计（使用文档中的正确表结构）
    SELECT DISTINCT
        b."BLOOD_NAME" as "XM",
        COUNT(a."BLOODBAG_ID") as "RC",
        SUM(COALESCE(CAST(a."BLOOD_CHARGE" AS DOUBLE), 0)) as "FY",
        COUNT(a."BLOODBAG_ID") as "GZL"
    FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a
    INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b
        ON a."BLOOD_TYPE_ID" = b."BLOOD_TYPE_ID"
        AND b."isdeleted" = '0'
    INNER JOIN hid0101_orcl_lis_xhdata.lis6_inspect_sample c
        ON a."INSPECTION_ID" = c."inspection_id"
        AND c."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."SENDBLOOD_TIME" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
    GROUP BY b."BLOOD_NAME"

    UNION ALL

    -- 第九部分：配血方法统计（使用血缘文档中的表结构）
    SELECT DISTINCT
        e."method_name" as "XM",
        COUNT(a."MATCH_ID") as "RC",
        SUM(COALESCE(CAST(e."method_charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."MATCH_ID") as "GZL"
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
        AND a."MACTH_DATE" BETWEEN '2024-08-01 00:00:00' AND '2024-08-31 23:59:59'
        AND e."method_id" NOT IN ('00000004','00000006','00000007','4')
    GROUP BY e."method_name"
) T
GROUP BY T."XM"
ORDER BY T."XM"


--- 第二个

