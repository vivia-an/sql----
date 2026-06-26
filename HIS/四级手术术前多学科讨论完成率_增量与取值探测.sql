-- 四级手术术前多学科讨论 — 增量与取值探测（Presto / HID0101）
-- 目的：解释「加会诊规则后分子只多一点点」——拆解模板/会诊重叠、术前时间取值、会诊时间字段
-- 与主 SQL 同分母口径；两区间各输出一行对比 + UNION 明细项

WITH
non_emergency_ip AS (
    SELECT ip."Visit_IPReg_VisitID" AS visit_id
    FROM datacenter_db."Visit_IPReg" ip
    WHERE ip."Visit_IPReg_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
      AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayName" AS varchar)), '') NOT LIKE '%急诊%'
      AND coalesce(trim(cast(ip."Visit_IPReg_InHospModeName" AS varchar)), '') NOT LIKE '%急诊%'
      AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayCode" AS varchar)), '') NOT IN ('1')
),

ops_l4 AS (
    SELECT
        CASE
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2025-07-01' AND ops."MR_FPOPS_OPSDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2026-01-01' AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        ops."MR_FPOPS_MROPSID" AS mropsid,
        ops."MR_FPOPS_VisitID" AS visit_id,
        try_cast(ops."MR_FPOPS_OPSDtTm" AS timestamp) AS ops_dt
    FROM datacenter_db."MR_FPOPS" ops
    INNER JOIN non_emergency_ip ip
        ON ops."MR_FPOPS_VisitID" = ip.visit_id
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND ops."MR_FPOPS_OPSDtTm" IS NOT NULL
      AND trim(cast(ops."MR_FPOPS_OPSDtTm" AS varchar)) <> ''
      AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) = '4'
      AND trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '1')) = '1'
      AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
      AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
      AND EXISTS (
          SELECT 1 FROM datacenter_db."MR_FP" fp
          WHERE fp."MR_FP_VisitID" = ops."MR_FPOPS_VisitID"
            AND fp."MR_FP_MedOrgCode" = 'HID0101'
            AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      )
),

mdt_doc_cache AS (
    SELECT
        ip."Visit_IPReg_VisitID" AS visit_id,
        coalesce(
            try_cast(
                concat(
                    trim(cast(idata.createdate AS varchar)),
                    ' ',
                    trim(coalesce(cast(idata.createtime AS varchar), '00:00:00'))
                ) AS timestamp
            ),
            try_cast(idata.createdate AS timestamp)
        ) AS doc_dt
    FROM hid0101_cache_his_dhcapp_emrinstance.instancedata idata
    INNER JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
        ON cast(idata.episodeid AS varchar) = cast(adm.paadm_rowid AS varchar)
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON trim(cast(adm.paadm_admno AS varchar)) = trim(cast(ip."Visit_IPReg_VisitNo" AS varchar))
       AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
       AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
    INNER JOIN non_emergency_ip ne
        ON ip."Visit_IPReg_VisitID" = ne.visit_id
    WHERE coalesce(cast(idata.isdeleted AS varchar), '0') = '0'
      AND trim(cast(idata.templateid AS varchar)) IN ('1146', '1004')
),

mdt_doc_cda AS (
    SELECT
        doc."Case_CDAMainDoc_VisitID" AS visit_id,
        coalesce(
            try_cast(doc."Case_CDAMainDoc_FinishDtTm" AS timestamp),
            try_cast(doc."Case_CDAMainDoc_CreateDtTm" AS timestamp),
            try_cast(doc."Case_CDAMainDoc_RecordDtTm" AS timestamp)
        ) AS doc_dt
    FROM datacenter_db."Case_CDAMainDoc" doc
    INNER JOIN non_emergency_ip ne
        ON doc."Case_CDAMainDoc_VisitID" = ne.visit_id
    WHERE doc."Case_CDAMainDoc_MedOrgCode" = 'HID0101'
      AND coalesce(cast(doc."Case_CDAMainDoc_IsDeleted" AS varchar), '0') = '0'
      AND trim(cast(doc."Case_CDAMainDoc_TemplateID" AS varchar)) IN ('1146', '1004')
      AND coalesce(cast(doc."Case_CDAMainDoc_WritStatusCode" AS varchar), '1') = '1'
),

mdt_doc AS (
    SELECT visit_id, doc_dt FROM mdt_doc_cache
    UNION ALL
    SELECT visit_id, doc_dt FROM mdt_doc_cda
),

consult_itm_agg AS (
    SELECT
        trim(cast(itm.ec_parref_dr AS varchar)) AS consult_id,
        count(DISTINCT trim(cast(itm.ec_cloc_dr AS varchar))) AS dept_cnt,
        min(
            try_cast(
                concat(
                    trim(cast(itm.ec_cdate AS varchar)),
                    ' ',
                    trim(coalesce(cast(itm.ec_ctime AS varchar), '00:00:00'))
                ) AS timestamp
            )
        ) AS arrive_dt
    FROM hid0101_cache_his_dhcapp_sqluser.dhc_emconsultitm itm
    WHERE coalesce(cast(itm.isdeleted AS varchar), '0') = '0'
      AND itm.ec_parref_dr IS NOT NULL
      AND trim(cast(itm.ec_parref_dr AS varchar)) <> ''
      AND itm.ec_cloc_dr IS NOT NULL
      AND trim(cast(itm.ec_cloc_dr AS varchar)) <> ''
    GROUP BY 1
),

mdt_consult AS (
    SELECT
        ip."Visit_IPReg_VisitID" AS visit_id,
        coalesce(
            try_cast(
                concat(
                    trim(cast(c.ec_rdate AS varchar)),
                    ' ',
                    trim(coalesce(cast(c.ec_rtime AS varchar), '00:00:00'))
                ) AS timestamp
            ),
            try_cast(c.ec_rdate AS timestamp)
        ) AS apply_dt,
        ic.arrive_dt
    FROM hid0101_cache_his_dhcapp_sqluser.dhc_emconsult c
    INNER JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
        ON cast(c.ec_adm_dr AS varchar) = cast(adm.paadm_rowid AS varchar)
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON trim(cast(adm.paadm_admno AS varchar)) = trim(cast(ip."Visit_IPReg_VisitNo" AS varchar))
       AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
       AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
    INNER JOIN non_emergency_ip ne
        ON ip."Visit_IPReg_VisitID" = ne.visit_id
    LEFT JOIN consult_itm_agg ic
        ON cast(c.ec_rowid AS varchar) = ic.consult_id
    WHERE coalesce(cast(c.isdeleted AS varchar), '0') = '0'
      AND c.ec_rdate >= '2025-07-01'
      AND c.ec_rdate < '2026-07-01'
      AND trim(coalesce(cast(c.ec_type AS varchar), '')) <> 'DOCA'
      AND trim(cast(c.ec_rstatus AS varchar)) IN ('7', '10')
      AND (
            trim(cast(c.ec_category AS varchar)) <> '1'
            OR (
                trim(cast(c.ec_category AS varchar)) = '1'
                AND coalesce(ic.dept_cnt, 0) > 2
            )
          )
),

surgery_flag AS (
    SELECT
        o."统计区间",
        o.mropsid,
        o.visit_id,
        o.ops_dt,
        max(CASE WHEN d.doc_dt IS NOT NULL THEN 1 ELSE 0 END) AS has_tpl_any,
        max(CASE WHEN d.doc_dt IS NOT NULL AND d.doc_dt < o.ops_dt THEN 1 ELSE 0 END) AS tpl_preop,
        max(CASE WHEN d.doc_dt IS NOT NULL AND d.doc_dt >= o.ops_dt THEN 1 ELSE 0 END) AS tpl_postop,
        max(CASE WHEN c.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS has_cons_any,
        max(CASE
            WHEN c.apply_dt IS NOT NULL AND c.apply_dt < o.ops_dt THEN 1
            ELSE 0
        END) AS cons_preop_apply,
        max(CASE
            WHEN c.arrive_dt IS NOT NULL AND c.arrive_dt < o.ops_dt THEN 1
            ELSE 0
        END) AS cons_preop_arrive,
        max(CASE
            WHEN c.apply_dt IS NOT NULL AND c.apply_dt >= o.ops_dt THEN 1
            ELSE 0
        END) AS cons_postop_apply,
        max(CASE
            WHEN (d.doc_dt IS NOT NULL AND d.doc_dt < o.ops_dt)
              OR (c.apply_dt IS NOT NULL AND c.apply_dt < o.ops_dt)
                THEN 1 ELSE 0
        END) AS num_tpl_or_cons_apply,
        max(CASE
            WHEN (d.doc_dt IS NOT NULL AND d.doc_dt < o.ops_dt)
              OR (c.arrive_dt IS NOT NULL AND c.arrive_dt < o.ops_dt)
                THEN 1 ELSE 0
        END) AS num_tpl_or_cons_arrive
    FROM ops_l4 o
    LEFT JOIN mdt_doc d
        ON o.visit_id = d.visit_id
    LEFT JOIN mdt_consult c
        ON o.visit_id = c.visit_id
    WHERE o."统计区间" IS NOT NULL
    GROUP BY o."统计区间", o.mropsid, o.visit_id, o.ops_dt
),

interval_bucket AS (
    SELECT
        "统计区间",
        count(DISTINCT mropsid) AS denom,
        count(DISTINCT CASE WHEN tpl_preop = 1 THEN mropsid END) AS num_tpl_only_logic,
        count(DISTINCT CASE WHEN cons_preop_apply = 1 THEN mropsid END) AS num_cons_apply,
        count(DISTINCT CASE WHEN cons_preop_arrive = 1 THEN mropsid END) AS num_cons_arrive,
        count(DISTINCT CASE WHEN num_tpl_or_cons_apply = 1 THEN mropsid END) AS num_combined_apply,
        count(DISTINCT CASE WHEN num_tpl_or_cons_arrive = 1 THEN mropsid END) AS num_combined_arrive,
        count(DISTINCT CASE WHEN tpl_preop = 1 AND cons_preop_apply = 0 THEN mropsid END) AS only_tpl,
        count(DISTINCT CASE WHEN tpl_preop = 0 AND cons_preop_apply = 1 THEN mropsid END) AS only_cons,
        count(DISTINCT CASE WHEN tpl_preop = 1 AND cons_preop_apply = 1 THEN mropsid END) AS both_hit,
        count(DISTINCT CASE WHEN tpl_preop = 0 AND cons_preop_apply = 0 THEN mropsid END) AS neither_hit,
        count(DISTINCT CASE WHEN has_tpl_any = 1 THEN mropsid END) AS tpl_any_no_time,
        count(DISTINCT CASE WHEN has_cons_any = 1 THEN mropsid END) AS cons_any_no_time,
        count(DISTINCT CASE WHEN tpl_postop = 1 THEN mropsid END) AS tpl_postop_cnt,
        count(DISTINCT CASE WHEN cons_postop_apply = 1 THEN mropsid END) AS cons_postop_cnt
    FROM surgery_flag
    GROUP BY "统计区间"
),

consult_time_on_l4 AS (
    SELECT
        o."统计区间",
        count(DISTINCT o.mropsid) AS l4_with_consult_rule,
        count(DISTINCT CASE WHEN c.apply_dt < o.ops_dt THEN o.mropsid END) AS preop_apply,
        count(DISTINCT CASE WHEN c.apply_dt >= o.ops_dt THEN o.mropsid END) AS postop_apply,
        count(DISTINCT CASE WHEN c.arrive_dt IS NOT NULL AND c.arrive_dt < o.ops_dt THEN o.mropsid END) AS preop_arrive,
        count(DISTINCT CASE WHEN c.arrive_dt IS NOT NULL AND c.arrive_dt >= o.ops_dt THEN o.mropsid END) AS postop_arrive,
        count(DISTINCT CASE WHEN c.apply_dt IS NULL THEN o.mropsid END) AS apply_dt_null
    FROM ops_l4 o
    INNER JOIN mdt_consult c
        ON o.visit_id = c.visit_id
    WHERE o."统计区间" IS NOT NULL
    GROUP BY o."统计区间"
)

SELECT 'A01_分母_四级手术' AS "排查项", "统计区间", cast(denom AS bigint) AS "数量", cast(null AS varchar) AS "备注"
FROM interval_bucket

UNION ALL
SELECT 'A02_分子_仅模板术前', "统计区间", cast(num_tpl_only_logic AS bigint), cast(null AS varchar)
FROM interval_bucket

UNION ALL
SELECT 'A03_分子_仅会诊术前(申请EC_RDate)', "统计区间", cast(num_cons_apply AS bigint), cast(null AS varchar)
FROM interval_bucket

UNION ALL
SELECT 'A04_分子_仅会诊术前(到达EC_CDate)', "统计区间", cast(num_cons_arrive AS bigint), cast(null AS varchar)
FROM interval_bucket

UNION ALL
SELECT 'A05_分子_模板OR会诊(申请时间)', "统计区间", cast(num_combined_apply AS bigint), '当前主SQL口径'
FROM interval_bucket

UNION ALL
SELECT 'A06_分子_模板OR会诊(到达时间)', "统计区间", cast(num_combined_arrive AS bigint), '若改Itm到达时间'
FROM interval_bucket

UNION ALL
SELECT 'A07_增量_仅会诊命中(模板未命中)', "统计区间", cast(only_cons AS bigint), '会诊真正增量'
FROM interval_bucket

UNION ALL
SELECT 'A08_重叠_模板+会诊均命中', "统计区间", cast(both_hit AS bigint), cast(null AS varchar)
FROM interval_bucket

UNION ALL
SELECT 'A09_仅模板命中', "统计区间", cast(only_tpl AS bigint), cast(null AS varchar)
FROM interval_bucket

UNION ALL
SELECT 'A10_均未命中', "统计区间", cast(neither_hit AS bigint), cast(null AS varchar)
FROM interval_bucket

UNION ALL
SELECT 'B01_模板存在但术后才写', "统计区间", cast(tpl_postop_cnt AS bigint), 'has_tpl且doc_dt>=ops'
FROM interval_bucket

UNION ALL
SELECT 'B02_模板存在(不限术前)', "统计区间", cast(tpl_any_no_time AS bigint), '不限时间≈原15/16'
FROM interval_bucket

UNION ALL
SELECT 'B03_会诊存在(不限术前)', "统计区间", cast(cons_any_no_time AS bigint), cast(null AS varchar)
FROM interval_bucket

UNION ALL
SELECT 'B04_会诊存在但申请时间在术后', "统计区间", cast(cons_postop_cnt AS bigint), 'EC_RDate+RTime>=ops'
FROM interval_bucket

UNION ALL
SELECT 'C01_四级有会诊规则_术前(申请)', "统计区间", cast(preop_apply AS bigint), cast(l4_with_consult_rule AS varchar)
FROM consult_time_on_l4

UNION ALL
SELECT 'C02_四级有会诊规则_术后(申请)', "统计区间", cast(postop_apply AS bigint), cast(null AS varchar)
FROM consult_time_on_l4

UNION ALL
SELECT 'C03_四级有会诊规则_术前(到达)', "统计区间", cast(preop_arrive AS bigint), cast(null AS varchar)
FROM consult_time_on_l4

UNION ALL
SELECT 'C04_四级有会诊规则_术后(到达)', "统计区间", cast(postop_arrive AS bigint), cast(null AS varchar)
FROM consult_time_on_l4

UNION ALL
SELECT 'C05_会诊申请时间为空', "统计区间", cast(apply_dt_null AS bigint), cast(null AS varchar)
FROM consult_time_on_l4

ORDER BY "排查项", "统计区间";
