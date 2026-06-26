-- mr_ops 与 MR_FP / Visit_Diag 关联键命中探查（2025 出院手术样本）
-- 上一步：FP_Desc全时段17226；ICD_T81就诊28840 — 有数据，需找对关联键

WITH params AS (
    SELECT '2025-01-01' AS startdate, '2026-01-01' AS enddate
),
ops AS (
    SELECT DISTINCT
        cast(o.mrops_paadmdr AS varchar) AS paadmdr,
        trim(cast(o.mrops_padmno AS varchar)) AS padmno,
        trim(cast(b.mrb_padmno AS varchar)) AS mrb_padmno,
        trim(cast(b.mrb_paadmdr AS varchar)) AS mrb_paadmdr,
        trim(cast(adm.paadm_admno AS varchar)) AS admno
    FROM cache53.mr_ops o
    INNER JOIN cache53.mr_base b
        ON cast(o.mrops_mrbaseid AS varchar) = cast(b.id AS varchar)
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
        ON cast(adm.paadm_rowid AS varchar) = cast(o.mrops_paadmdr AS varchar)
    WHERE trim(coalesce(b.mrb_checkitem2, '')) = '医院'
      AND trim(cast(o.mrops_foutdate AS varchar)) >= (SELECT startdate FROM params)
      AND trim(cast(o.mrops_foutdate AS varchar)) < (SELECT enddate FROM params)
),
fp_desc AS (
    SELECT
        trim(cast(fp."MR_FP_VisitNo" AS varchar)) AS visit_no,
        trim(coalesce(fp."MR_FP_OPSComplicationDesc", '')) AS compl_desc,
        trim(cast(fp."MR_FP_OutHospDtTm" AS varchar)) AS out_dt
    FROM datacenter_db."MR_FP" fp
    WHERE fp."MR_FP_MedOrgCode" = 'HID0101'
      AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      AND nullif(trim(cast(fp."MR_FP_OPSComplicationDesc" AS varchar)), '') IS NOT NULL
),
icd AS (
    SELECT DISTINCT trim(cast(d."Visit_Diag_VisitNo" AS varchar)) AS visit_no
    FROM datacenter_db."Visit_Diag" d
    WHERE d."Visit_Diag_MedOrgCode" = 'HID0101'
      AND trim(cast(d."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
)

SELECT
    count(DISTINCT o.paadmdr) AS "2025手术ADM数",
    count(DISTINCT CASE WHEN fp.visit_no = o.paadmdr THEN o.paadmdr END) AS "Desc命中_rowid",
    count(DISTINCT CASE WHEN fp.visit_no = o.admno THEN o.paadmdr END) AS "Desc命中_admno",
    count(DISTINCT CASE WHEN fp.visit_no = o.padmno THEN o.paadmdr END) AS "Desc命中_padmno",
    count(DISTINCT CASE WHEN fp.visit_no = o.mrb_padmno THEN o.paadmdr END) AS "Desc命中_mrb_padmno",
    count(DISTINCT CASE WHEN fp.visit_no IN (o.paadmdr, o.admno, o.padmno, o.mrb_padmno, o.mrb_paadmdr)
          THEN o.paadmdr END) AS "Desc命中_任一",
    count(DISTINCT CASE WHEN icd.visit_no IN (o.paadmdr, o.admno, o.padmno, o.mrb_padmno, o.mrb_paadmdr)
          THEN o.paadmdr END) AS "ICD_T81命中_任一",
    count(DISTINCT CASE WHEN substring(fp.out_dt, 1, 4) = '2025' THEN fp.visit_no END) AS "FP_Desc_2025VisitNo数"
FROM ops o
LEFT JOIN fp_desc fp
    ON fp.visit_no IN (o.paadmdr, o.admno, o.padmno, o.mrb_padmno, o.mrb_paadmdr)
LEFT JOIN icd
    ON icd.visit_no IN (o.paadmdr, o.admno, o.padmno, o.mrb_padmno, o.mrb_paadmdr);

-- 样本：FP VisitNo 与 ops 键长什么样（各取5条）
/*
SELECT 'fp_visitno' AS src, visit_no AS v FROM fp_desc LIMIT 5;
SELECT 'ops_paadmdr' AS src, paadmdr AS v FROM ops LIMIT 5;
SELECT 'ops_admno' AS src, admno AS v FROM ops WHERE admno IS NOT NULL LIMIT 5;
*/
