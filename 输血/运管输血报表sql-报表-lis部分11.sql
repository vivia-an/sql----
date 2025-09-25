SET SESSION query_max_stage_count = 2500;


WITH base_result AS (
    -- 输血科综合统计报表（行转列版本）
SELECT 
date_format(date_add('month', -1, current_date), '%Y-%m') as "周期",
'上月' as "周期名称",
1 as "排序",
date_format(date_add('month', -1, current_date), '%Y年-%m月') as "统计月",
'主院区' as "院区分类",
'输血科' as "运管科室",
   

-- 样本数（合并多个项目）
    (SELECT SUM("工作量") FROM (
        SELECT "XM" as "项目名称",
               SUM(T."RC") as "人次",
               SUM(T."FY") as "费用",
               SUM(T."GZL") as "工作量"
        FROM ( 
            -- 第一部分：检验项目统计
            SELECT DISTINCT  
                   b."chinese_name_short" as "XM",
                   count(a."inspection_id") as "RC",
                   sum(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
                   sum(COALESCE(
                       CASE WHEN CAST(b."workload" AS INTEGER) = 0 THEN 1 
                            ELSE CAST(b."workload" AS INTEGER) 
                       END, 1)) as "GZL"
            FROM hid0101_orcl_lis_xhdata.lis6_inspect_sample a
            INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b
                ON a."inspection_id" = b."inspection_id"
                AND b."isdeleted" = '0'
            WHERE a."isdeleted" = '0'
              AND a."input_time" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
              AND a."input_time" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
              AND a."group_id" IN ('G013','G053','G105','G111')     
            GROUP BY b."chinese_name_short"
            
            UNION ALL
            
            -- 第二部分：输血申请统计
            SELECT DISTINCT
                   c."blood_type_name" as "XM",
                   count(a."inspection_id") as "RC",
                   0 as "FY",
                   count(a."inspection_id") as "GZL"
            FROM hid0101_orcl_lis_xhdata.lis6_inspect_sample a
            INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_info b
                ON a."requisition_id" = b."req_id"
                AND b."isdeleted" = '0'
            INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_blood c
                ON b."req_id" = c."req_id"
                AND c."isdeleted" = '0'
            WHERE a."isdeleted" = '0'
              AND a."input_time" >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
              AND a."input_time" < date_format(date_trunc('month', current_date), '%Y-%m-%d')
              AND a."group_id" IN ('G013','G053','G105','G111') 
            GROUP BY c."blood_type_name"
        ) T 
        GROUP BY "XM"
        ORDER BY "XM"
    ) t) as "样本数",
    
    SUM(CASE WHEN "XM" IN (
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
'血型抗体效价测定（IgG+IgM）',
'盐水介质+凝聚胺配血',
'盐水介质交叉配血',
'直接抗人球蛋白试验' -- "RC"  "GZL"
    ) THEN "GZL" ELSE 0 END) + SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 3 as "项目数" , -- 这里应该*4 所以这么写，当前项目数38个和要求是对的上到
 SUM(CASE WHEN "XM" IN (
'ABO血型+Rh血型',
'ABO血型鉴定',
'ABO血型鉴定（微柱凝胶法）',
'血型单特异性抗体鉴定',
'盐水介质+凝聚胺配血',
'特殊介质交叉配血(微柱凝胶法)',
'直接抗人球蛋白试验',
'（请张杰调取抗筛阳性的标本数）',
'血小板交叉配合实验',
'血小板特异性和组织相关融性(HLA)抗体检测',
'血型抗体效价测定（IgG+IgM）',
'RH分型(4个RH其他抗原+1个RHD抗原)',
'ABO红细胞定型（微柱凝胶法）',
'特殊血型抗原鉴定',
'ABO血型+Rh血型',
'血型抗体特异性鉴定（放散）',
'血型抗体特异性鉴定（吸收试验）' -- "RC"  "GZL"
    ) THEN "GZL" ELSE 0 END) 
    + SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 3 
   + (SELECT SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xj1" + T."xxb1" + T."lcd1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '入库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xj1" + T."xxb1" + T."lcd1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xxb1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."xxb1" * 3 ELSE 0 END) as "血库计算" FROM (SELECT '库存记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '001' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '002' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '003' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '004' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '005' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '006' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '007' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '008' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '009' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '010' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '入库记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '011' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '012' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '013' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '014' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '015' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '016' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '017' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '018' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '019' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '020' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '021' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '022' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '023' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '024' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '025' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '026' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '027' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '028' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '029' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '030' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') ) T )
   + (
SELECT 
count(1)

from   hid0101_orcl_lis_xhdata.lis6_inspect_sample  a
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT b 
    ON a."INSPECTION_ID" = b."INSPECTION_ID"
    AND b."TEST_ITEM_ID" = '3573'
    AND b."isdeleted" = '0'
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT c 
    ON a."INSPECTION_ID" = c."INSPECTION_ID"  
    AND c."TEST_ITEM_ID" = '3600'
    AND c."isdeleted" = '0'
LEFT join  hid0101_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST d 
    ON a."INSPECTION_ID" = d."INSPECTION_ID"
    AND d."SPECIAL_TYPE" = '疑难'
    AND d."isdeleted" = '0'
WHERE a."isdeleted" = '0'
    AND c."QUANTITATIVE_RESULT" = '阳性'
    AND a."OUTPATIENT_ID" IS NOT NULL 
    AND a."PATIENT_NAME" IS NOT NULL
    AND UPPER(a."PATIENT_NAME") NOT LIKE '%QC%'
    -- 时间筛选条件 (需要根据实际需求替换)
 AND a."INPUT_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d'))
 +
 (SELECT 
    COUNT(DISTINCT order_main_orderid) 
FROM datacenter_db.Order_Main 
WHERE Order_Main_RecDeptName in ( '输血科','锦江输血科' )
    AND Order_Main_OrderItemCode IN (
        '666600613',  -- 血液稀释疗法
        '666000570',  -- 拟：全血
        '666000571',  -- 拟：Rh(-)全血
        '666600598',  -- 血浆置换术
        '666000510'   -- 血细胞分离单采
    )
    AND Order_Main_IsDeleted = '0'  -- 排除已删除的记录
    AND Order_Main_OrderDtTm >= date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')  -- 开始时间
    AND Order_Main_OrderDtTm <= date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')  -- 结束时间
      and medorgcode = 'HID0101')
      + (select sum(cast(finished_amount as double ))  from hid0101_orcl_lis_xhbis.bis6_blood_inventory  where  inventory_time between date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') and date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d'))
      
      
      
    -- 院区筛选条件 (需要根据实际需求替换)  
    -- AND a."AREA_ID" = '院区编码')
    as "工作量" ,
 -- 卡查血型
    SUM(CASE WHEN "XM" = 'ABO血型+Rh血型' THEN "GZL" ELSE 0 END) as "卡查血型",
 -- 抗A、抗B血清查血型
    SUM(CASE WHEN "XM" = 'ABO血型鉴定' THEN "GZL" ELSE 0 END) as "抗A、抗B血清查血型",
 -- 红细胞血型复查
    SUM(CASE WHEN "XM" = 'ABO血型鉴定（微柱凝胶法）' THEN "GZL" ELSE 0 END) as "红细胞血型复查",
    
    -- 抗体筛查  
    SUM(CASE WHEN "XM" = '血型单特异性抗体鉴定' THEN "GZL" ELSE 0 END) as "抗体筛查",
    
    -- 凝聚胺配血
    SUM(CASE WHEN "XM" = '盐水介质+凝聚胺配血' THEN "GZL" ELSE 0 END) as "凝聚胺配血",
    
    -- 卡式配血
    SUM(CASE WHEN "XM" = '特殊介质交叉配血(微柱凝胶法)' THEN "GZL" ELSE 0 END) as "卡式配血",
    
    -- 直接抗人球蛋白
    SUM(CASE WHEN "XM" = '直接抗人球蛋白试验' THEN "GZL" ELSE 0 END) as "直接抗人球蛋白",
    
    (
SELECT 
count(1)

from   hid0101_orcl_lis_xhdata.lis6_inspect_sample  a
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT b 
    ON a."INSPECTION_ID" = b."INSPECTION_ID"
    AND b."TEST_ITEM_ID" = '3573'
    AND b."isdeleted" = '0'
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT c 
    ON a."INSPECTION_ID" = c."INSPECTION_ID"  
    AND c."TEST_ITEM_ID" = '3600'
    AND c."isdeleted" = '0'
LEFT join  hid0101_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST d 
    ON a."INSPECTION_ID" = d."INSPECTION_ID"
    AND d."SPECIAL_TYPE" = '疑难'
    AND d."isdeleted" = '0'
WHERE a."isdeleted" = '0'
    AND c."QUANTITATIVE_RESULT" = '阳性'
    AND a."OUTPATIENT_ID" IS NOT NULL 
    AND a."PATIENT_NAME" IS NOT NULL
    AND UPPER(a."PATIENT_NAME") NOT LIKE '%QC%'
    -- 时间筛选条件 (需要根据实际需求替换)
 AND a."INPUT_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
    -- 院区筛选条件 (需要根据实际需求替换)  
    -- AND a."AREA_ID" = '院区编码'
--ORDER BY a."INSPECTION_ID"
) as "抗体鉴定",
    
    -- 血小板交叉
    SUM(CASE WHEN "XM" = '血小板交叉配合实验' THEN "RC" ELSE 0 END) as "血小板交叉",
    
    -- 血小板抗体
    SUM(CASE WHEN "XM" = '血小板特异性和组织相关融性(HLA)抗体检测' THEN "GZL" ELSE 0 END) as "血小板抗体",
    
    -- 抗体效价
    SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 4 as "抗体效价",
    
    -- Rh分型
    SUM(CASE WHEN "XM" = 'RH分型(4个RH其他抗原+1个RHD抗原)' THEN "RC" ELSE 0 END) as "Rh分型",
    
    -- 血小板血型复查
    SUM(CASE WHEN "XM" = 'ABO红细胞定型（微柱凝胶法）' THEN "GZL" ELSE 0 END) as "血小板血型复查",

    -- 吸收放散试验
    (SUM(CASE WHEN "XM" = '血型抗体特异性鉴定（放散）' THEN "GZL" ELSE 0 END) +
     SUM(CASE WHEN "XM" = '血型抗体特异性鉴定（吸收试验）' THEN "GZL" ELSE 0 END)) as "吸收放散试验",

    -- 治疗性单采例数
    (SELECT COUNT(DISTINCT "Order_Main_OrderID") 
     FROM datacenter_db.Order_Main
     WHERE "Order_Main_RecDeptName" in ('输血科','锦江输血科')
         AND "Order_Main_OrderItemCode" IN ('666600613','666000570','666000571','666600598','666000510')
         AND "Order_Main_OrderBeginDtTm" BETWEEN
             date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
             AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
         ) as "治疗性单采例数",

    -- 特殊血型抗原鉴定
    SUM(CASE WHEN "XM" = '特殊血型抗原鉴定' THEN "RC" ELSE 0 END) as "特殊血型抗原鉴定"

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
        AND a."input_time" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
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
        AND a."input_time" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
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
    INNER JOIN hid0101_orcl_lis_xhinterface.xinghe_charged_list e
        ON d."sample_charge_id" = e."sample_charge_id"
        AND e."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND e."his_id" IN ('LIS07068','LIS0300114','LIS0300255')
        AND d."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
    GROUP BY e."charge_item_name"

    UNION ALL

    -- 第四部分：收费信息统计（使用正确的库名）
    SELECT
        b."charge_item_name" as "XM",
        SUM(COALESCE(CAST(b."charge_num" AS DOUBLE), 0)) as "RC",
        SUM(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."charged_id") as "GZL"
    FROM hid0101_orcl_lis_xhbis.bis6_charged_info a
    INNER JOIN hid0101_orcl_lis_xhinterface.xinghe_charged_list b
        ON a."sample_charge_id" = b."sample_charge_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."charge_state" IN ('charged','uncharged')
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
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
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
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
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
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
        AND b."req_time" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
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
        AND a."SENDBLOOD_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
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
        AND a."MACTH_DATE" BETWEEN date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d')
        AND e."method_id" NOT IN ('00000004','00000006','00000007','4')
    GROUP BY e."method_name"
) T

union all


    -- 输血科综合统计报表（行转列版本）
SELECT 

date_format(date_add('month', -2, current_date), '%Y-%m') as "周期",
'上上月' as "周期名称",
2 as "排序",
date_format(date_add('month', -1, current_date), '%Y年-%m月') as "统计月",
'主院区' as "院区分类",
'输血科' as "运管科室",
-- 样本数（合并多个项目）
    (SELECT SUM("工作量") FROM (
        SELECT "XM" as "项目名称",
               SUM(T."RC") as "人次",
               SUM(T."FY") as "费用",
               SUM(T."GZL") as "工作量"
        FROM ( 
            -- 第一部分：检验项目统计
            SELECT DISTINCT  
                   b."chinese_name_short" as "XM",
                   count(a."inspection_id") as "RC",
                   sum(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
                   sum(COALESCE(
                       CASE WHEN CAST(b."workload" AS INTEGER) = 0 THEN 1 
                            ELSE CAST(b."workload" AS INTEGER) 
                       END, 1)) as "GZL"
            FROM hid0101_orcl_lis_xhdata.lis6_inspect_sample a
            INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b
                ON a."inspection_id" = b."inspection_id"
                AND b."isdeleted" = '0'
            WHERE a."isdeleted" = '0'
              AND a."input_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d')
              AND a."input_time" < date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
              AND a."group_id" IN ('G013','G053','G105','G111')     
            GROUP BY b."chinese_name_short"
            
            UNION ALL
            
            -- 第二部分：输血申请统计
            SELECT DISTINCT
                   c."blood_type_name" as "XM",
                   count(a."inspection_id") as "RC",
                   0 as "FY",
                   count(a."inspection_id") as "GZL"
            FROM hid0101_orcl_lis_xhdata.lis6_inspect_sample a
            INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_info b
                ON a."requisition_id" = b."req_id"
                AND b."isdeleted" = '0'
            INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_blood c
                ON b."req_id" = c."req_id"
                AND c."isdeleted" = '0'
            WHERE a."isdeleted" = '0'
              AND a."input_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d')
              AND a."input_time" < date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d')
              AND a."group_id" IN ('G013','G053','G105','G111') 
            GROUP BY c."blood_type_name"
        ) T 
        GROUP BY "XM"
        ORDER BY "XM"
    ) t) as "样本数",
    
    SUM(CASE WHEN "XM" IN (
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
'血型抗体效价测定（IgG+IgM）',
'盐水介质+凝聚胺配血',
'盐水介质交叉配血',
'直接抗人球蛋白试验' -- "RC"  "GZL"
    ) THEN "GZL" ELSE 0 END) + SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 3 as "项目数" , -- 这里应该*4 所以这么写，当前项目数38个和要求是对的上到
 SUM(CASE WHEN "XM" IN (
'ABO血型+Rh血型',
'ABO血型鉴定',
'ABO血型鉴定（微柱凝胶法）',
'血型单特异性抗体鉴定',
'盐水介质+凝聚胺配血',
'特殊介质交叉配血(微柱凝胶法)',
'直接抗人球蛋白试验',
'（请张杰调取抗筛阳性的标本数）',
'血小板交叉配合实验',
'血小板特异性和组织相关融性(HLA)抗体检测',
'血型抗体效价测定（IgG+IgM）',
'RH分型(4个RH其他抗原+1个RHD抗原)',
'ABO红细胞定型（微柱凝胶法）',
'特殊血型抗原鉴定',
'ABO血型+Rh血型',
'血型抗体特异性鉴定（放散）',
'血型抗体特异性鉴定（吸收试验）' -- "RC"  "GZL"
    ) THEN "GZL" ELSE 0 END) 
    + SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 3 
   + (SELECT SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xj1" + T."xxb1" + T."lcd1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '入库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xj1" + T."xxb1" + T."lcd1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xxb1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."xxb1" * 3 ELSE 0 END) as "血库计算" FROM (SELECT '库存记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '001' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '002' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '003' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '004' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '005' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '006' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '007' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '008' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '009' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '010' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '入库记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '011' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '012' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '013' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '014' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '015' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '016' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '017' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '018' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '019' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '020' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '021' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '022' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '023' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '024' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '025' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '026' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '027' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '028' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '029' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '030' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d') ) T )
   + (
SELECT 
count(1)

from   hid0101_orcl_lis_xhdata.lis6_inspect_sample  a
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT b 
    ON a."INSPECTION_ID" = b."INSPECTION_ID"
    AND b."TEST_ITEM_ID" = '3573'
    AND b."isdeleted" = '0'
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT c 
    ON a."INSPECTION_ID" = c."INSPECTION_ID"  
    AND c."TEST_ITEM_ID" = '3600'
    AND c."isdeleted" = '0'
LEFT join  hid0101_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST d 
    ON a."INSPECTION_ID" = d."INSPECTION_ID"
    AND d."SPECIAL_TYPE" = '疑难'
    AND d."isdeleted" = '0'
WHERE a."isdeleted" = '0'
    AND c."QUANTITATIVE_RESULT" = '阳性'
    AND a."OUTPATIENT_ID" IS NOT NULL 
    AND a."PATIENT_NAME" IS NOT NULL
    AND UPPER(a."PATIENT_NAME") NOT LIKE '%QC%'
    -- 时间筛选条件 (需要根据实际需求替换)
 AND a."INPUT_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d'))
 +
 (SELECT 
    COUNT(DISTINCT order_main_orderid) 
FROM datacenter_db.Order_Main 
WHERE Order_Main_RecDeptName in ('输血科','锦江输血科')
    AND Order_Main_OrderItemCode IN (
        '666600613',  -- 血液稀释疗法
        '666000570',  -- 拟：全血
        '666000571',  -- 拟：Rh(-)全血
        '666600598',  -- 血浆置换术
        '666000510'   -- 血细胞分离单采
    )
    AND Order_Main_IsDeleted = '0'  -- 排除已删除的记录
    AND Order_Main_OrderDtTm >= date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d')  -- 开始时间
    AND Order_Main_OrderDtTm <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')  -- 结束时间
      and medorgcode = 'HID0101')
      + (select sum(cast(finished_amount as double ))  from hid0101_orcl_lis_xhbis.bis6_blood_inventory  where  inventory_time between date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') and date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d'))
      
      
      
    -- 院区筛选条件 (需要根据实际需求替换)  
    -- AND a."AREA_ID" = '院区编码')
    as "工作量" ,
 -- 卡查血型
    SUM(CASE WHEN "XM" = 'ABO血型+Rh血型' THEN "GZL" ELSE 0 END) as "卡查血型",
 -- 抗A、抗B血清查血型
    SUM(CASE WHEN "XM" = 'ABO血型鉴定' THEN "GZL" ELSE 0 END) as "抗A、抗B血清查血型",

    -- 红细胞血型复查
    SUM(CASE WHEN "XM" = 'ABO血型鉴定（微柱凝胶法）' THEN "GZL" ELSE 0 END) as "红细胞血型复查",
    
    -- 抗体筛查  
    SUM(CASE WHEN "XM" = '血型单特异性抗体鉴定' THEN "GZL" ELSE 0 END) as "抗体筛查",
    
    -- 凝聚胺配血
    SUM(CASE WHEN "XM" = '盐水介质+凝聚胺配血' THEN "GZL" ELSE 0 END) as "凝聚胺配血",
    
    -- 卡式配血
    SUM(CASE WHEN "XM" = '特殊介质交叉配血(微柱凝胶法)' THEN "GZL" ELSE 0 END) as "卡式配血",
    
    -- 直接抗人球蛋白
    SUM(CASE WHEN "XM" = '直接抗人球蛋白试验' THEN "GZL" ELSE 0 END) as "直接抗人球蛋白",
    
    (
SELECT 
count(1)

from   hid0101_orcl_lis_xhdata.lis6_inspect_sample  a
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT b 
    ON a."INSPECTION_ID" = b."INSPECTION_ID"
    AND b."TEST_ITEM_ID" = '3573'
    AND b."isdeleted" = '0'
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT c 
    ON a."INSPECTION_ID" = c."INSPECTION_ID"  
    AND c."TEST_ITEM_ID" = '3600'
    AND c."isdeleted" = '0'
LEFT join  hid0101_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST d 
    ON a."INSPECTION_ID" = d."INSPECTION_ID"
    AND d."SPECIAL_TYPE" = '疑难'
    AND d."isdeleted" = '0'
WHERE a."isdeleted" = '0'
    AND c."QUANTITATIVE_RESULT" = '阳性'
    AND a."OUTPATIENT_ID" IS NOT NULL 
    AND a."PATIENT_NAME" IS NOT NULL
    AND UPPER(a."PATIENT_NAME") NOT LIKE '%QC%'
    -- 时间筛选条件 (需要根据实际需求替换)
 AND a."INPUT_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
    -- 院区筛选条件 (需要根据实际需求替换)  
    -- AND a."AREA_ID" = '院区编码'
--ORDER BY a."INSPECTION_ID"
) as "抗体鉴定",
    
    -- 血小板交叉
    SUM(CASE WHEN "XM" = '血小板交叉配合实验' THEN "RC" ELSE 0 END) as "血小板交叉",
    
    -- 血小板抗体
    SUM(CASE WHEN "XM" = '血小板特异性和组织相关融性(HLA)抗体检测' THEN "GZL" ELSE 0 END) as "血小板抗体",
    
    -- 抗体效价
    SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 4 as "抗体效价",
    
    -- Rh分型
    SUM(CASE WHEN "XM" = 'RH分型(4个RH其他抗原+1个RHD抗原)' THEN "RC" ELSE 0 END) as "Rh分型",
    
    -- 血小板血型复查
    SUM(CASE WHEN "XM" = 'ABO红细胞定型（微柱凝胶法）' THEN "GZL" ELSE 0 END) as "血小板血型复查",

    -- 吸收放散试验
    (SUM(CASE WHEN "XM" = '血型抗体特异性鉴定（放散）' THEN "GZL" ELSE 0 END) +
     SUM(CASE WHEN "XM" = '血型抗体特异性鉴定（吸收试验）' THEN "GZL" ELSE 0 END)) as "吸收放散试验",

    -- 治疗性单采例数
    (SELECT COUNT(DISTINCT "Order_Main_OrderID")
     FROM datacenter_db.Order_Main
     WHERE "Order_Main_RecDeptName" in ('输血科','锦江输血科')
         AND "Order_Main_OrderItemCode" IN ('666600613','666000570','666000571','666600598','666000510')
         AND "Order_Main_OrderBeginDtTm" BETWEEN
             date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d')
             AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')) as "治疗性单采例数",

    -- 特殊血型抗原鉴定
    SUM(CASE WHEN "XM" = '特殊血型抗原鉴定' THEN "RC" ELSE 0 END) as "特殊血型抗原鉴定"

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
        AND a."input_time" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
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
        AND a."input_time" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
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
    INNER JOIN hid0101_orcl_lis_xhinterface.xinghe_charged_list e
        ON d."sample_charge_id" = e."sample_charge_id"
        AND e."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND e."his_id" IN ('LIS07068','LIS0300114','LIS0300255')
        AND d."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
    GROUP BY e."charge_item_name"

    UNION ALL

    -- 第四部分：收费信息统计（使用正确的库名）
    SELECT
        b."charge_item_name" as "XM",
        SUM(COALESCE(CAST(b."charge_num" AS DOUBLE), 0)) as "RC",
        SUM(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."charged_id") as "GZL"
    FROM hid0101_orcl_lis_xhbis.bis6_charged_info a
    INNER JOIN hid0101_orcl_lis_xhinterface.xinghe_charged_list b
        ON a."sample_charge_id" = b."sample_charge_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."charge_state" IN ('charged','uncharged')
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
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
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
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
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
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
        AND b."req_time" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
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
        AND a."SENDBLOOD_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
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
        AND a."MACTH_DATE" BETWEEN date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d')
        AND e."method_id" NOT IN ('00000004','00000006','00000007','4')
    GROUP BY e."method_name"
) T

union all


    -- 输血科综合统计报表（行转列版本）
SELECT 

date_format(date_add('month', -13, current_date), '%Y-%m') as "周期",
'去年同期' as "周期名称",
3 as "排序",
date_format(date_add('month', -1, current_date), '%Y年-%m月') as "统计月",
'主院区' as "院区分类",
'输血科' as "运管科室",
-- 样本数（使用新的统计逻辑）
    (SELECT SUM("工作量") FROM (
        SELECT "XM" as "项目名称",
               SUM(T."RC") as "人次",
               SUM(T."FY") as "费用",
               SUM(T."GZL") as "工作量"
        FROM ( 
            -- 第一部分：检验项目统计
            SELECT DISTINCT  
                   b."chinese_name_short" as "XM",
                   count(a."inspection_id") as "RC",
                   sum(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
                   sum(COALESCE(
                       CASE WHEN CAST(b."workload" AS INTEGER) = 0 THEN 1 
                            ELSE CAST(b."workload" AS INTEGER) 
                       END, 1)) as "GZL"
            FROM hid0101_orcl_lis_xhdata.lis6_inspect_sample a
            INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge b
                ON a."inspection_id" = b."inspection_id"
                AND b."isdeleted" = '0'
            WHERE a."isdeleted" = '0'
              AND a."input_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d')
              AND a."input_time" < date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
              AND a."group_id" IN ('G013','G053','G105','G111')     
            GROUP BY b."chinese_name_short"
            
            UNION ALL
            
            -- 第二部分：输血申请统计
            SELECT DISTINCT
                   c."blood_type_name" as "XM",
                   count(a."inspection_id") as "RC",
                   0 as "FY",
                   count(a."inspection_id") as "GZL"
            FROM hid0101_orcl_lis_xhdata.lis6_inspect_sample a
            INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_info b
                ON a."requisition_id" = b."req_id"
                AND b."isdeleted" = '0'
            INNER JOIN hid0101_orcl_lis_xhbis.bis6_req_blood c
                ON b."req_id" = c."req_id"
                AND c."isdeleted" = '0'
            WHERE a."isdeleted" = '0'
              AND a."input_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d')
              AND a."input_time" < date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
              AND a."group_id" IN ('G013','G053','G105','G111') 
            GROUP BY c."blood_type_name"
        ) T 
        GROUP BY "XM"
        ORDER BY "XM"
    ) t) as "样本数",
    
    SUM(CASE WHEN "XM" IN (
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
'血型抗体效价测定（IgG+IgM）',
'盐水介质+凝聚胺配血',
'盐水介质交叉配血',
'直接抗人球蛋白试验' -- "RC"  "GZL"
    ) THEN "GZL" ELSE 0 END) + SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 3 as "项目数" , -- 这里应该*4 所以这么写，当前项目数38个和要求是对的上到
 SUM(CASE WHEN "XM" IN (
'ABO血型+Rh血型',
'ABO血型鉴定',
'ABO血型鉴定（微柱凝胶法）',
'血型单特异性抗体鉴定',
'盐水介质+凝聚胺配血',
'特殊介质交叉配血(微柱凝胶法)',
'直接抗人球蛋白试验',
'（请张杰调取抗筛阳性的标本数）',
'血小板交叉配合实验',
'血小板特异性和组织相关融性(HLA)抗体检测',
'血型抗体效价测定（IgG+IgM）',
'RH分型(4个RH其他抗原+1个RHD抗原)',
'ABO红细胞定型（微柱凝胶法）',
'特殊血型抗原鉴定',
'ABO血型+Rh血型',
'血型抗体特异性鉴定（放散）',
'血型抗体特异性鉴定（吸收试验）' -- "RC"  "GZL"
    ) THEN "GZL" ELSE 0 END) 
    + SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 3 
   + (SELECT SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xj1" + T."xxb1" + T."lcd1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '入库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xj1" + T."xxb1" + T."lcd1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."hxb1" + T."xxb1"ELSE 0 END) + SUM(CASE WHEN T."kcjl" = '出库记录'AND T."xx1" = '合计' AND T."js1" = '袋'AND T."xx2" = '合计' AND T."js2" = '袋'AND T."xx3" = '合计' AND T."js3" = '袋'AND T."xx4" = '合计' AND T."js4" = '袋'THEN T."xxb1" * 3 ELSE 0 END) as "血库计算" FROM (SELECT '库存记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '001' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '002' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '003' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '004' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '005' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '006' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '007' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '008' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '009' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '库存记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '010' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."bloodbag_state" IN ('1','2') AND a."isdeleted" = '0'UNION ALL SELECT '入库记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '011' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '012' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '013' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '014' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '015' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '016' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '017' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '018' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '019' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '入库记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '020' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."in_time" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."in_time" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'O型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "hxb1", 'O型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xj1", 'O型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "xxb1", 'O型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN a."bloodbag_id" END) as "lcd1", '021' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'O型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'O型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'O型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'O型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='O型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '022' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'A型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "hxb1", 'A型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xj1", 'A型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "xxb1", 'A型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN a."bloodbag_id" END) as "lcd1", '023' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'A型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'A型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'A型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'A型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='A型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '024' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'B型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "hxb1", 'B型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xj1", 'B型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "xxb1", 'B型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN a."bloodbag_id" END) as "lcd1", '025' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'B型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'B型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'B型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'B型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='B型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '026' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'AB型' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "hxb1", 'AB型' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xj1", 'AB型' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "xxb1", 'AB型' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN a."bloodbag_id" END) as "lcd1", '027' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", 'AB型' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", 'AB型' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", 'AB型' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", 'AB型' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' AND a."abo_blood_group"='AB型' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '028' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", '合计' as "xx1", '袋' as "js1", COUNT(DISTINCT CASE WHEN c."component_id"='00000009' THEN a."bloodbag_id" END) as "hxb1", '合计' as "xx2", '袋' as "js2", COUNT(DISTINCT CASE WHEN c."component_id"='00000010' THEN a."bloodbag_id" END) as "xj1", '合计' as "xx3", '袋' as "js3", COUNT(DISTINCT CASE WHEN c."component_id"='00000011' THEN a."bloodbag_id" END) as "xxb1", '合计' as "xx4", '袋' as "js4", COUNT(DISTINCT CASE WHEN c."component_id"='00000012' THEN a."bloodbag_id" END) as "lcd1", '029' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') UNION ALL SELECT '出库记录' as "kcjl", '合计' as "xx1", '量' as "js1", SUM(CASE WHEN c."component_id"='00000009' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "hxb1", '合计' as "xx2", '量' as "js2", SUM(CASE WHEN c."component_id"='00000010' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xj1", '合计' as "xx3", '量' as "js3", SUM(CASE WHEN c."component_id"='00000011' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "xxb1", '合计' as "xx4", '量' as "js4", SUM(CASE WHEN c."component_id"='00000012' THEN CAST(a."blood_amount" AS DOUBLE) ELSE 0 END) as "lcd1", '030' as "sort"FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b ON a."blood_type_id" = b."blood_type_id"AND b."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c ON b."component_id" = c."component_id"AND c."isdeleted" = '0'INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d ON a."inspection_id" = d."inspection_id"AND d."isdeleted" = '0'WHERE a."isdeleted" = '0'AND a."out_date" >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND a."out_date" <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d') ) T )
   + (
SELECT 
count(1)

from   hid0101_orcl_lis_xhdata.lis6_inspect_sample  a
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT b 
    ON a."INSPECTION_ID" = b."INSPECTION_ID"
    AND b."TEST_ITEM_ID" = '3573'
    AND b."isdeleted" = '0'
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT c 
    ON a."INSPECTION_ID" = c."INSPECTION_ID"  
    AND c."TEST_ITEM_ID" = '3600'
    AND c."isdeleted" = '0'
LEFT join  hid0101_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST d 
    ON a."INSPECTION_ID" = d."INSPECTION_ID"
    AND d."SPECIAL_TYPE" = '疑难'
    AND d."isdeleted" = '0'
WHERE a."isdeleted" = '0'
    AND c."QUANTITATIVE_RESULT" = '阳性'
    AND a."OUTPATIENT_ID" IS NOT NULL 
    AND a."PATIENT_NAME" IS NOT NULL
    AND UPPER(a."PATIENT_NAME") NOT LIKE '%QC%'
    -- 时间筛选条件 (需要根据实际需求替换)
 AND a."INPUT_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d'))
 +
 (SELECT 
    COUNT(DISTINCT order_main_orderid) 
FROM datacenter_db.Order_Main 
WHERE Order_Main_RecDeptName like '%输血%'
    AND Order_Main_OrderItemCode IN (
        '666600613',  -- 血液稀释疗法
        '666000570',  -- 拟：全血
        '666000571',  -- 拟：Rh(-)全血
        '666600598',  -- 血浆置换术
        '666000510'   -- 血细胞分离单采
    )
    AND Order_Main_IsDeleted = '0'  -- 排除已删除的记录
    AND Order_Main_OrderDtTm >= date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d')  -- 开始时间
    AND Order_Main_OrderDtTm <= date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')  -- 结束时间
      and medorgcode = 'HID0101')
      + (select sum(cast(finished_amount as double ))  from hid0101_orcl_lis_xhbis.bis6_blood_inventory  where  inventory_time between date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') and date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d'))
      
      
      
    -- 院区筛选条件 (需要根据实际需求替换)  
    -- AND a."AREA_ID" = '院区编码')
    as "工作量" ,
 -- 卡查血型
    SUM(CASE WHEN "XM" = 'ABO血型+Rh血型' THEN "GZL" ELSE 0 END) as "卡查血型",
 -- 抗A、抗B血清查血型
    SUM(CASE WHEN "XM" = 'ABO血型鉴定' THEN "GZL" ELSE 0 END) as "抗A、抗B血清查血型",

    -- 红细胞血型复查
    SUM(CASE WHEN "XM" = 'ABO血型鉴定（微柱凝胶法）' THEN "GZL" ELSE 0 END) as "红细胞血型复查",
    
    -- 抗体筛查  
    SUM(CASE WHEN "XM" = '血型单特异性抗体鉴定' THEN "GZL" ELSE 0 END) as "抗体筛查",
    
    -- 凝聚胺配血
    SUM(CASE WHEN "XM" = '盐水介质+凝聚胺配血' THEN "GZL" ELSE 0 END) as "凝聚胺配血",
    
    -- 卡式配血
    SUM(CASE WHEN "XM" = '特殊介质交叉配血(微柱凝胶法)' THEN "GZL" ELSE 0 END) as "卡式配血",
    
    -- 直接抗人球蛋白
    SUM(CASE WHEN "XM" = '直接抗人球蛋白试验' THEN "GZL" ELSE 0 END) as "直接抗人球蛋白",
    
    (
SELECT 
count(1)

from   hid0101_orcl_lis_xhdata.lis6_inspect_sample  a
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT b 
    ON a."INSPECTION_ID" = b."INSPECTION_ID"
    AND b."TEST_ITEM_ID" = '3573'
    AND b."isdeleted" = '0'
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT c 
    ON a."INSPECTION_ID" = c."INSPECTION_ID"  
    AND c."TEST_ITEM_ID" = '3600'
    AND c."isdeleted" = '0'
LEFT join  hid0101_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST d 
    ON a."INSPECTION_ID" = d."INSPECTION_ID"
    AND d."SPECIAL_TYPE" = '疑难'
    AND d."isdeleted" = '0'
WHERE a."isdeleted" = '0'
    AND c."QUANTITATIVE_RESULT" = '阳性'
    AND a."OUTPATIENT_ID" IS NOT NULL 
    AND a."PATIENT_NAME" IS NOT NULL
    AND UPPER(a."PATIENT_NAME") NOT LIKE '%QC%'
    -- 时间筛选条件 (需要根据实际需求替换)
 AND a."INPUT_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
    -- 院区筛选条件 (需要根据实际需求替换)  
    -- AND a."AREA_ID" = '院区编码'
--ORDER BY a."INSPECTION_ID"
) as "抗体鉴定",
    
    -- 血小板交叉
    SUM(CASE WHEN "XM" = '血小板交叉配合实验' THEN "GZL" ELSE 0 END) as "血小板交叉",
    
    -- 血小板抗体
    SUM(CASE WHEN "XM" = '血小板特异性和组织相关融性(HLA)抗体检测' THEN "GZL" ELSE 0 END) as "血小板抗体",
    
    -- 抗体效价
    SUM(CASE WHEN "XM" = '血型抗体效价测定（IgG+IgM）' THEN "GZL" ELSE 0 END) * 4 as "抗体效价",
    
    -- Rh分型
    SUM(CASE WHEN "XM" = 'RH分型(4个RH其他抗原+1个RHD抗原)' THEN "RC" ELSE 0 END) as "Rh分型",
    
    -- 血小板血型复查
    SUM(CASE WHEN "XM" = 'ABO红细胞定型（微柱凝胶法）' THEN "GZL" ELSE 0 END) as "血小板血型复查",

    -- 吸收放散试验
    (SUM(CASE WHEN "XM" = '血型抗体特异性鉴定（放散）' THEN "GZL" ELSE 0 END) +
     SUM(CASE WHEN "XM" = '血型抗体特异性鉴定（吸收试验）' THEN "GZL" ELSE 0 END)) as "吸收放散试验",

    -- 治疗性单采例数
    (SELECT COUNT(DISTINCT "Order_Main_OrderID") 
     FROM datacenter_db.Order_Main
     WHERE "Order_Main_RecDeptName" in ('输血科','锦江输血科')
         AND "Order_Main_OrderItemCode" IN ('666600613','666000570','666000571','666600598','666000510')
         AND "Order_Main_OrderBeginDtTm" BETWEEN
             date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d')
             AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')) as "治疗性单采例数",

    -- 特殊血型抗原鉴定
    SUM(CASE WHEN "XM" = '特殊血型抗原鉴定' THEN "RC" ELSE 0 END) as "特殊血型抗原鉴定"

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
        AND a."input_time" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
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
        AND a."input_time" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
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
    INNER JOIN hid0101_orcl_lis_xhinterface.xinghe_charged_list e
        ON d."sample_charge_id" = e."sample_charge_id"
        AND e."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND e."his_id" IN ('LIS07068','LIS0300114','LIS0300255')
        AND d."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
    GROUP BY e."charge_item_name"

    UNION ALL

    -- 第四部分：收费信息统计（使用正确的库名）
    SELECT
        b."charge_item_name" as "XM",
        SUM(COALESCE(CAST(b."charge_num" AS DOUBLE), 0)) as "RC",
        SUM(COALESCE(CAST(b."charge" AS DOUBLE), 0)) as "FY",
        COUNT(a."charged_id") as "GZL"
    FROM hid0101_orcl_lis_xhbis.bis6_charged_info a
    INNER JOIN hid0101_orcl_lis_xhinterface.xinghe_charged_list b
        ON a."sample_charge_id" = b."sample_charge_id"
        AND b."isdeleted" = '0'
    WHERE a."isdeleted" = '0'
        AND a."charge_state" IN ('charged','uncharged')
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
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
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
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
        AND a."charge_time" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
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
        AND b."req_time" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
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
        AND a."SENDBLOOD_TIME" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
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
        AND a."MACTH_DATE" BETWEEN date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d') AND date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d')
        AND e."method_id" NOT IN ('00000004','00000006','00000007','4')
    GROUP BY e."method_name"
) T
)
SELECT * FROM base_result

union all

 -- 环比计算（上月比上上月）
    SELECT 
        CONCAT(
            MAX(CASE WHEN "排序" = 1 THEN "周期" END),
            ' vs ',
            MAX(CASE WHEN "排序" = 2 THEN "周期" END)
        ) as "周期",
        '同比' as "周期名称",
        4 as "排序",
        CONCAT(
            MAX(CASE WHEN "排序" = 1 THEN "统计月" END),
            ' vs ',
            MAX(CASE WHEN "排序" = 2 THEN "统计月" END)
        ) as "统计月",
        '主院区' as "院区分类",
        '输血科' as "运管科室",
        -- 样本数环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "样本数" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "样本数" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "样本数" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "样本数" END), 2)
             ELSE NULL 
        END as "样本数",
        -- 项目数环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "项目数" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "项目数" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "项目数" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "项目数" END), 2)
             ELSE NULL 
        END as "项目数",
        -- 工作量环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "工作量" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "工作量" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "工作量" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "工作量" END), 2)
             ELSE NULL 
        END as "工作量",
        -- 卡查血型环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "卡查血型" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "卡查血型" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "卡查血型" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "卡查血型" END), 2)
             ELSE NULL 
        END as "卡查血型",
        -- 抗A、抗B血清查血型环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "抗A、抗B血清查血型" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "抗A、抗B血清查血型" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "抗A、抗B血清查血型" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "抗A、抗B血清查血型" END), 2)
             ELSE NULL 
        END as "抗A、抗B血清查血型",
        -- 红细胞血型复查环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "红细胞血型复查" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞血型复查" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "红细胞血型复查" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "红细胞血型复查" END), 2)
             ELSE NULL 
        END as "红细胞血型复查",
        -- 抗体筛查环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "抗体筛查" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "抗体筛查" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "抗体筛查" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "抗体筛查" END), 2)
             ELSE NULL 
        END as "抗体筛查",
        -- 凝聚胺配血环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "凝聚胺配血" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "凝聚胺配血" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "凝聚胺配血" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "凝聚胺配血" END), 2)
             ELSE NULL 
        END as "凝聚胺配血",
        -- 卡式配血环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "卡式配血" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "卡式配血" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "卡式配血" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "卡式配血" END), 2)
             ELSE NULL 
        END as "卡式配血",
        -- 直接抗人球蛋白环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "直接抗人球蛋白" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "直接抗人球蛋白" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "直接抗人球蛋白" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "直接抗人球蛋白" END), 2)
             ELSE NULL 
        END as "直接抗人球蛋白",
        -- 抗体鉴定环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "抗体鉴定" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "抗体鉴定" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "抗体鉴定" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "抗体鉴定" END), 2)
             ELSE NULL 
        END as "抗体鉴定",
        -- 血小板交叉环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "血小板交叉" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板交叉" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "血小板交叉" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "血小板交叉" END), 2)
             ELSE NULL 
        END as "血小板交叉",
        -- 血小板抗体环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "血小板抗体" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板抗体" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "血小板抗体" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "血小板抗体" END), 2)
             ELSE NULL 
        END as "血小板抗体",
        -- 抗体效价环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "抗体效价" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "抗体效价" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "抗体效价" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "抗体效价" END), 2)
             ELSE NULL 
        END as "抗体效价",
        -- Rh分型环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "Rh分型" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "Rh分型" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "Rh分型" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "Rh分型" END), 2)
             ELSE NULL 
        END as "Rh分型",
        -- 血小板血型复查环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "血小板血型复查" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板血型复查" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "血小板血型复查" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "血小板血型复查" END), 2)
             ELSE NULL 
        END as "血小板血型复查",
        -- 吸收放散试验环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "吸收放散试验" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "吸收放散试验" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "吸收放散试验" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "吸收放散试验" END), 2)
             ELSE NULL 
        END as "吸收放散试验",
        -- 治疗性单采例数环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "治疗性单采例数" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "治疗性单采例数" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "治疗性单采例数" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "治疗性单采例数" END), 2)
             ELSE NULL 
        END as "治疗性单采例数",
        -- 特殊血型抗原鉴定环比
        CASE WHEN MAX(CASE WHEN "排序" = 2 THEN "特殊血型抗原鉴定" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "特殊血型抗原鉴定" END) - 
                        MAX(CASE WHEN "排序" = 2 THEN "特殊血型抗原鉴定" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 2 THEN "特殊血型抗原鉴定" END), 2)
             ELSE NULL 
        END as "特殊血型抗原鉴定"
    FROM base_result
    WHERE "排序" <= 2
    

    union all 




 -- 环比计算（上月比上上月）
    SELECT 
        CONCAT(
            MAX(CASE WHEN "排序" = 1 THEN "周期" END),
            ' vs ',
            MAX(CASE WHEN "排序" = 3 THEN "周期" END)
        ) as "周期",
        '环比' as "周期名称",
        5 as "排序",
        CONCAT(
            MAX(CASE WHEN "排序" = 1 THEN "统计月" END),
            ' vs ',
            MAX(CASE WHEN "排序" = 3 THEN "统计月" END)
        ) as "统计月",
        '主院区' as "院区分类",
        '输血科' as "运管科室",
        -- 样本数环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "样本数" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "样本数" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "样本数" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "样本数" END), 3)
             ELSE NULL 
        END as "样本数",
        -- 项目数环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "项目数" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "项目数" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "项目数" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "项目数" END), 3)
             ELSE NULL 
        END as "项目数",
        -- 工作量环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "工作量" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "工作量" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "工作量" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "工作量" END), 3)
             ELSE NULL 
        END as "工作量",
        -- 卡查血型环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "卡查血型" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "卡查血型" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "卡查血型" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "卡查血型" END), 3)
             ELSE NULL 
        END as "卡查血型",
        -- 抗A、抗B血清查血型环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "抗A、抗B血清查血型" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "抗A、抗B血清查血型" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "抗A、抗B血清查血型" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "抗A、抗B血清查血型" END), 3)
             ELSE NULL 
        END as "抗A、抗B血清查血型",
        -- 红细胞血型复查环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "红细胞血型复查" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "红细胞血型复查" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "红细胞血型复查" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "红细胞血型复查" END), 3)
             ELSE NULL 
        END as "红细胞血型复查",
        -- 抗体筛查环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "抗体筛查" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "抗体筛查" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "抗体筛查" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "抗体筛查" END), 3)
             ELSE NULL 
        END as "抗体筛查",
        -- 凝聚胺配血环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "凝聚胺配血" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "凝聚胺配血" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "凝聚胺配血" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "凝聚胺配血" END), 3)
             ELSE NULL 
        END as "凝聚胺配血",
        -- 卡式配血环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "卡式配血" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "卡式配血" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "卡式配血" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "卡式配血" END), 3)
             ELSE NULL 
        END as "卡式配血",
        -- 直接抗人球蛋白环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "直接抗人球蛋白" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "直接抗人球蛋白" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "直接抗人球蛋白" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "直接抗人球蛋白" END), 3)
             ELSE NULL 
        END as "直接抗人球蛋白",
        -- 抗体鉴定环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "抗体鉴定" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "抗体鉴定" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "抗体鉴定" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "抗体鉴定" END), 3)
             ELSE NULL 
        END as "抗体鉴定",
        -- 血小板交叉环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "血小板交叉" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板交叉" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "血小板交叉" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "血小板交叉" END), 3)
             ELSE NULL 
        END as "血小板交叉",
        -- 血小板抗体环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "血小板抗体" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板抗体" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "血小板抗体" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "血小板抗体" END), 3)
             ELSE NULL 
        END as "血小板抗体",
        -- 抗体效价环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "抗体效价" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "抗体效价" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "抗体效价" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "抗体效价" END), 3)
             ELSE NULL 
        END as "抗体效价",
        -- Rh分型环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "Rh分型" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "Rh分型" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "Rh分型" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "Rh分型" END), 3)
             ELSE NULL 
        END as "Rh分型",
        -- 血小板血型复查环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "血小板血型复查" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "血小板血型复查" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "血小板血型复查" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "血小板血型复查" END), 3)
             ELSE NULL 
        END as "血小板血型复查",
        -- 吸收放散试验环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "吸收放散试验" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "吸收放散试验" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "吸收放散试验" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "吸收放散试验" END), 3)
             ELSE NULL 
        END as "吸收放散试验",
        -- 治疗性单采例数环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "治疗性单采例数" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "治疗性单采例数" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "治疗性单采例数" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "治疗性单采例数" END), 3)
             ELSE NULL 
        END as "治疗性单采例数",
        -- 特殊血型抗原鉴定环比
        CASE WHEN MAX(CASE WHEN "排序" = 3 THEN "特殊血型抗原鉴定" END) > 0 
             THEN ROUND((MAX(CASE WHEN "排序" = 1 THEN "特殊血型抗原鉴定" END) - 
                        MAX(CASE WHEN "排序" = 3 THEN "特殊血型抗原鉴定" END)) * 100.0 / 
                        MAX(CASE WHEN "排序" = 3 THEN "特殊血型抗原鉴定" END), 3)
             ELSE NULL 
        END as "特殊血型抗原鉴定"
    FROM base_result
    WHERE "排序" <= 3

order by "排序" 