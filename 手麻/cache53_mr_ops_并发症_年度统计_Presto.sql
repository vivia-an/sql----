-- cache53.mr_ops 并发症年度统计（Presto）
-- 时间：仅 mr_ops.mrops_foutdate（varchar）；MR_FP 不再按 OutHospDtTm 过滤
-- 并发症来源：① MR_FP.OPSComplicationDesc  ② Visit_Diag T81/T88+精确码
-- 关联：paadmdr / paadm_admno / padmno 多键 OR

WITH params AS (
    SELECT
        2025 AS stat_year,
        '2025-01-01' AS startdate,
        '2026-01-01' AS enddate
),
ops_base AS (
    SELECT
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
      AND coalesce(cast(o.isdeleted AS varchar), '0') = '0'
      AND coalesce(cast(b.isdeleted AS varchar), '0') = '0'
      AND trim(cast(o.mrops_foutdate AS varchar)) >= (SELECT startdate FROM params)
      AND trim(cast(o.mrops_foutdate AS varchar)) < (SELECT enddate FROM params)
),
ops_filtered AS (
    SELECT DISTINCT paadmdr FROM ops_base
),
fp_complication AS (
    SELECT DISTINCT trim(cast(fp."MR_FP_VisitNo" AS varchar)) AS visit_no
    FROM datacenter_db."MR_FP" fp
    WHERE fp."MR_FP_MedOrgCode" = 'HID0101'
      AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      AND nullif(trim(cast(fp."MR_FP_OPSComplicationDesc" AS varchar)), '') IS NOT NULL
),
visit_icd AS (
    SELECT DISTINCT trim(cast(diag."Visit_Diag_VisitNo" AS varchar)) AS visit_no
    FROM datacenter_db."Visit_Diag" diag
    WHERE diag."Visit_Diag_MedOrgCode" = 'HID0101'
      AND coalesce(cast(diag."Visit_Diag_IsDeleted" AS varchar), '0') = '0'
      AND (
            trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T88%'
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) IN (
                'I26', 'I80.1', 'I80.2', 'I82.8', 'A40', 'A41',
                'T81.411', 'T81.0', 'T81.3', 'T81.4', 'T81.5', 'T81.6',
                'T88.2', 'T88.3', 'T88.4', 'T88.5',
                'J95.1', 'J95.2', 'J95.3', 'J95.4', 'J95.8', 'J95.9',
                'T81.2', 'N17', 'N99.0', 'K91',
                'T81.1', 'T81.7', 'T81.8', 'T81.9'
            )
          )
),
ops_bfz AS (
    SELECT DISTINCT ob.paadmdr
    FROM ops_base ob
    INNER JOIN fp_complication fc
        ON fc.visit_no IN (ob.paadmdr, ob.admno, ob.padmno, ob.mrb_padmno, ob.mrb_paadmdr)
    UNION
    SELECT DISTINCT ob.paadmdr
    FROM ops_base ob
    INNER JOIN visit_icd vi
        ON vi.visit_no IN (ob.paadmdr, ob.admno, ob.padmno, ob.mrb_padmno, ob.mrb_paadmdr)
)

SELECT
    (SELECT stat_year FROM params) AS "统计年",
    count(DISTINCT o.paadmdr) AS "出院手术涉及就诊数",
    count(DISTINCT bfz.paadmdr) AS "手术并发症例数"
FROM ops_filtered o
LEFT JOIN ops_bfz bfz
    ON o.paadmdr = bfz.paadmdr;

-- =============================================================================
-- 排查：各数据源独立计数（单独跑）
-- =============================================================================
/*
SELECT
    (SELECT count(*) FROM datacenter_db."MR_FP" fp
     WHERE fp."MR_FP_MedOrgCode" = 'HID0101'
       AND nullif(trim(cast(fp."MR_FP_OPSComplicationDesc" AS varchar)), '') IS NOT NULL) AS "FP_Desc非空_全时段",
    (SELECT count(DISTINCT trim(cast(fp."MR_FP_VisitNo" AS varchar)))
     FROM datacenter_db."MR_FP" fp
     WHERE fp."MR_FP_MedOrgCode" = 'HID0101'
       AND nullif(trim(cast(fp."MR_FP_OPSComplicationDesc" AS varchar)), '') IS NOT NULL
       AND substring(trim(cast(fp."MR_FP_OutHospDtTm" AS varchar)), 1, 4) = '2025') AS "FP_Desc非空_2025年",
    (SELECT count(DISTINCT trim(cast(d."Visit_Diag_VisitNo" AS varchar)))
     FROM datacenter_db."Visit_Diag" d
     WHERE d."Visit_Diag_MedOrgCode" = 'HID0101'
       AND trim(cast(d."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%') AS "ICD_T81_就诊数";
*/
