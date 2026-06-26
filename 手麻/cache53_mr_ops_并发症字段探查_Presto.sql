-- cache53.mr_ops + mr_base：并发症字段探查（Presto）
-- 原 IRIS：ZPack.testWyl5_BFZFLAG(MROPS_PAADMDR) 返回 0/1，Presto 无此函数
-- 本脚本：① 列名探查 ② 明细+多源并发症候选对比

-- =============================================================================
-- A) 列名探查（先跑，看 mr_ops / mr_base 有没有 bfz/complication 字段）
-- =============================================================================
-- SHOW COLUMNS FROM cache53.mr_ops LIKE '%bfz%';
-- SHOW COLUMNS FROM cache53.mr_ops LIKE '%compl%';
-- SHOW COLUMNS FROM cache53.mr_ops LIKE '%infect%';
-- SHOW COLUMNS FROM cache53.mr_base LIKE '%bfz%';
-- SHOW COLUMNS FROM cache53.mr_base LIKE '%compl%';
-- SHOW COLUMNS FROM cache53.mr_base LIKE '%infect%';

-- =============================================================================
-- B) mr_base 疑似感染/并发症字段取值分布（2025 出院手术关联样本）
-- =============================================================================
/*
WITH ops AS (
    SELECT DISTINCT cast(o.mrops_mrbaseid AS varchar) AS mrbase_id
    FROM cache53.mr_ops o
    INNER JOIN cache53.mr_base b ON cast(o.mrops_mrbaseid AS varchar) = cast(b.id AS varchar)
    WHERE trim(coalesce(b.mrb_checkitem2, '')) = '医院'
      AND trim(cast(o.mrops_foutdate AS varchar)) >= '2025-01-01'
      AND trim(cast(o.mrops_foutdate AS varchar)) < '2026-01-01'
)
SELECT 'mrb_hospinfect' AS fld, trim(coalesce(b.mrb_hospinfect, '')) AS v, count(*) AS c
FROM cache53.mr_base b INNER JOIN ops ON ops.mrbase_id = cast(b.id AS varchar)
GROUP BY 2 ORDER BY c DESC LIMIT 10;
-- 同上可换：mrb_infect / mrb_infectcheck / mrb_hospinfectcheck / mrb_opnotexpec
*/

-- =============================================================================
-- C) 明细 + 并发症多源候选（对齐原 hxbi 明细，可筛医师）
--    修改 params：startdate / enddate / opsdoc / opsas
-- =============================================================================
WITH params AS (
    SELECT
        '2025-01-01' AS startdate,
        '2025-12-31 23:59:59' AS enddate,
        cast(null AS varchar) AS opsdoc,   -- 例：'张三'；不筛填 null
        cast(null AS varchar) AS opsas     -- 例：'李四'；不筛填 null
),
visit_icd AS (
    SELECT DISTINCT trim(cast(diag."Visit_Diag_VisitNo" AS varchar)) AS visit_no
    FROM datacenter_db."Visit_Diag" diag
    WHERE diag."Visit_Diag_MedOrgCode" = 'HID0101'
      AND coalesce(cast(diag."Visit_Diag_IsDeleted" AS varchar), '0') = '0'
      AND (
            trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T88%'
          )
),
base_rows AS (
    SELECT
        o.mrops_paadmdr AS "患者ADM",
        o.mrops_papmino AS "登记号",
        o.mrops_padmno AS "病案号",
        b.mrb_paname AS "姓名",
        b.mrb_panationdesc AS "民族",
        b.mrb_pasexdr AS "性别代码",
        b.mrb_paageyear AS "年龄",
        b.mrb_padindate AS "入院日期",
        o.mrops_foutdate AS "出院日期",
        b.mrb_painlocdesc AS "入院科室",
        b.mrb_paoutlocdesc AS "出院科室",
        o.mrops_mainopsflag AS "主手术标志",
        o.mrops_opfirstcode AS "手术编码",
        o.mrops_opfirstname AS "手术名称",
        o.mrops_assistantfirst AS "手术一助",
        o.mrops_assistantsecond AS "手术二助",
        o.mrops_opdocdesc AS "手术医师",
        o.mrops_narcosisdocname AS "麻醉医师",
        o.mrops_surgtype AS "手术类型",
        o.mrops_narcosisname AS "麻醉方式名称",
        o.mrops_opsdate AS "手术日期",
        b.mrb_paouthealdr AS "出院情况_4为死亡",
        trim(coalesce(b.mrb_hospinfect, '')) AS "候选_mrb_hospinfect",
        trim(coalesce(b.mrb_infect, '')) AS "候选_mrb_infect",
        trim(coalesce(b.mrb_infectcheck, '')) AS "候选_mrb_infectcheck",
        trim(coalesce(fp."MR_FP_OPSComplicationFlag", '')) AS "候选_FP_Flag",
        trim(coalesce(fp."MR_FP_OPSComplicationDesc", '')) AS "候选_FP_Desc",
        trim(cast(adm.paadm_admno AS varchar)) AS admno
    FROM cache53.mr_ops o
    INNER JOIN cache53.mr_base b
        ON cast(o.mrops_mrbaseid AS varchar) = cast(b.id AS varchar)
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
        ON cast(adm.paadm_rowid AS varchar) = cast(o.mrops_paadmdr AS varchar)
    LEFT JOIN datacenter_db."MR_FP" fp
        ON fp."MR_FP_MedOrgCode" = 'HID0101'
       AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
       AND trim(cast(fp."MR_FP_VisitNo" AS varchar)) IN (
            cast(o.mrops_paadmdr AS varchar),
            trim(cast(adm.paadm_admno AS varchar)),
            trim(cast(o.mrops_padmno AS varchar)),
            trim(cast(b.mrb_padmno AS varchar)),
            trim(cast(b.mrb_paadmdr AS varchar))
       )
    CROSS JOIN params p
    WHERE trim(coalesce(b.mrb_checkitem2, '')) = '医院'
      AND coalesce(cast(o.isdeleted AS varchar), '0') = '0'
      AND coalesce(cast(b.isdeleted AS varchar), '0') = '0'
      AND trim(cast(o.mrops_foutdate AS varchar)) >= p.startdate
      AND trim(cast(o.mrops_foutdate AS varchar)) <= p.enddate
      AND (
            p.opsdoc IS NULL
            OR trim(o.mrops_opdocdesc) = p.opsdoc
            OR trim(o.mrops_assistantfirst) = p.opsas
          )
)
SELECT
    br.*,
    CASE WHEN vi.visit_no IS NOT NULL THEN 1 ELSE 0 END AS "候选_ICD_T81T88",
    CASE
        WHEN nullif(br."候选_FP_Desc", '') IS NOT NULL THEN 1
        WHEN br."候选_FP_Flag" IN ('1', '是', '√', 'Y', 'y') THEN 1
        WHEN vi.visit_no IS NOT NULL THEN 1
        ELSE 0
    END AS "并发症_综合推断"
FROM base_rows br
LEFT JOIN visit_icd vi
    ON vi.visit_no IN (cast(br."患者ADM" AS varchar), br.admno, cast(br."病案号" AS varchar))
LIMIT 500;

-- =============================================================================
-- D) 各候选字段阳性 ADM 数（2025，看哪个接近 Cache 全年 ~800-900）
-- =============================================================================
/*
WITH params AS (
    SELECT '2025-01-01' AS startdate, '2026-01-01' AS enddate
),
ops AS (
    SELECT DISTINCT
        cast(o.mrops_paadmdr AS varchar) AS paadmdr,
        trim(cast(o.mrops_padmno AS varchar)) AS padmno,
        trim(cast(b.mrb_padmno AS varchar)) AS mrb_padmno,
        trim(cast(b.mrb_hospinfect AS varchar)) AS hospinfect,
        trim(cast(b.mrb_infect AS varchar)) AS infect,
        trim(cast(adm.paadm_admno AS varchar)) AS admno
    FROM cache53.mr_ops o
    INNER JOIN cache53.mr_base b ON cast(o.mrops_mrbaseid AS varchar) = cast(b.id AS varchar)
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
        ON cast(adm.paadm_rowid AS varchar) = cast(o.mrops_paadmdr AS varchar)
    WHERE trim(coalesce(b.mrb_checkitem2, '')) = '医院'
      AND trim(cast(o.mrops_foutdate AS varchar)) >= (SELECT startdate FROM params)
      AND trim(cast(o.mrops_foutdate AS varchar)) < (SELECT enddate FROM params)
),
fp AS (
    SELECT trim(cast(fp."MR_FP_VisitNo" AS varchar)) AS visit_no,
           trim(coalesce(fp."MR_FP_OPSComplicationDesc", '')) AS compl_desc,
           trim(coalesce(fp."MR_FP_OPSComplicationFlag", '')) AS compl_flag
    FROM datacenter_db."MR_FP" fp
    WHERE fp."MR_FP_MedOrgCode" = 'HID0101'
),
icd AS (
    SELECT DISTINCT trim(cast(d."Visit_Diag_VisitNo" AS varchar)) AS visit_no
    FROM datacenter_db."Visit_Diag" d
    WHERE d."Visit_Diag_MedOrgCode" = 'HID0101'
      AND (trim(cast(d."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
        OR trim(cast(d."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T88%')
)
SELECT
    count(DISTINCT paadmdr) AS "ADM总数",
    count(DISTINCT CASE WHEN hospinfect NOT IN ('', '0', '否') THEN paadmdr END) AS "阳性_mrb_hospinfect",
    count(DISTINCT CASE WHEN infect NOT IN ('', '0', '否') THEN paadmdr END) AS "阳性_mrb_infect",
    count(DISTINCT CASE WHEN nullif(fp.compl_desc, '') IS NOT NULL
          AND fp.visit_no IN (o.paadmdr, o.admno, o.padmno, o.mrb_padmno) THEN o.paadmdr END) AS "阳性_FP_Desc",
    count(DISTINCT CASE WHEN icd.visit_no IN (o.paadmdr, o.admno, o.padmno, o.mrb_padmno) THEN o.paadmdr END) AS "阳性_ICD_T81T88"
FROM ops o
LEFT JOIN fp ON fp.visit_no IN (o.paadmdr, o.admno, o.padmno, o.mrb_padmno)
LEFT JOIN icd ON icd.visit_no IN (o.paadmdr, o.admno, o.padmno, o.mrb_padmno);
*/
