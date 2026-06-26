-- 四级手术术前多学科讨论 — 会诊规则探测（Presto / HID0101）
-- 规则：多科会诊 OR（单科会诊 AND 请会诊科室数>2）
-- 数据源：DHC cache 为主；Apply_Consult+Apply_ConsultDept 为辅（VisitID 直连）
-- 有效会诊（对齐 cache 截图）：EC_RStatus IN (7,10)、EC_Type<>'DOCA'；不限 EC_EmFlag
-- Itm 请会诊科室：ec_cloc_dr（已确认入仓列名）；dept_cnt=count distinct ec_cloc_dr
-- 区间：2025-07~12 / 2026-01~06；排除急诊入院（同主指标）

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

consult_itm_cnt AS (
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
        ) AS first_arrive_dt
    FROM hid0101_cache_his_dhcapp_sqluser.dhc_emconsultitm itm
    WHERE coalesce(cast(itm.isdeleted AS varchar), '0') = '0'
      AND itm.ec_parref_dr IS NOT NULL
      AND trim(cast(itm.ec_parref_dr AS varchar)) <> ''
      AND itm.ec_cloc_dr IS NOT NULL
      AND trim(cast(itm.ec_cloc_dr AS varchar)) <> ''
    GROUP BY 1
),

consult_cache_base AS (
    SELECT
        cast(c.ec_rowid AS varchar) AS consult_id,
        ip."Visit_IPReg_VisitID" AS visit_id,
        trim(cast(c.ec_category AS varchar)) AS category_code,
        trim(cast(c.ec_rstatus AS varchar)) AS rstatus_code,
        trim(cast(c.ec_type AS varchar)) AS type_code,
        coalesce(
            try_cast(
                concat(
                    trim(cast(c.ec_rdate AS varchar)),
                    ' ',
                    trim(coalesce(cast(c.ec_rtime AS varchar), '00:00:00'))
                ) AS timestamp
            ),
            ic.first_arrive_dt
        ) AS consult_dt,
        coalesce(ic.dept_cnt, 0) AS dept_cnt
    FROM hid0101_cache_his_dhcapp_sqluser.dhc_emconsult c
    INNER JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
        ON cast(c.ec_adm_dr AS varchar) = cast(adm.paadm_rowid AS varchar)
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON trim(cast(adm.paadm_admno AS varchar)) = trim(cast(ip."Visit_IPReg_VisitNo" AS varchar))
       AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
       AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
    INNER JOIN non_emergency_ip ne
        ON ip."Visit_IPReg_VisitID" = ne.visit_id
    LEFT JOIN consult_itm_cnt ic
        ON cast(c.ec_rowid AS varchar) = ic.consult_id
    WHERE coalesce(cast(c.isdeleted AS varchar), '0') = '0'
      AND c.ec_rdate >= '2025-07-01'
      AND c.ec_rdate < '2026-07-01'
      AND trim(coalesce(cast(c.ec_type AS varchar), '')) <> 'DOCA'
      AND trim(cast(c.ec_rstatus AS varchar)) IN ('7', '10')
),

consult_cache_rule AS (
    SELECT
        consult_id,
        visit_id,
        consult_dt,
        category_code,
        dept_cnt,
        CASE
            WHEN category_code <> '1' THEN 1
            WHEN category_code = '1' AND dept_cnt > 2 THEN 1
            ELSE 0
        END AS hit_rule
    FROM consult_cache_base
),

consult_dc_base AS (
    SELECT
        ac."Apply_Consult_ApplyID" AS apply_id,
        ac."Apply_Consult_VisitID" AS visit_id,
        try_cast(ac."Apply_Consult_ApplyDtTm" AS timestamp) AS consult_dt,
        trim(cast(ac."Apply_Consult_ConsultTypeCode" AS varchar)) AS type_code,
        trim(cast(ac."Apply_Consult_ConsultTypeName" AS varchar)) AS type_name,
        count(DISTINCT cd."Apply_ConsultDept_DeptID") AS dept_cnt
    FROM datacenter_db."Apply_Consult" ac
    LEFT JOIN datacenter_db."Apply_ConsultDept" cd
        ON ac."Apply_Consult_ApplyID" = cd."Apply_ConsultDept_ConsultApplyNo"
       AND cd."Apply_ConsultDept_MedOrgCode" = 'HID0101'
       AND coalesce(cast(cd."Apply_ConsultDept_IsDeleted" AS varchar), '0') = '0'
       AND cd."Apply_ConsultDept_DeptID" IS NOT NULL
       AND trim(cast(cd."Apply_ConsultDept_DeptID" AS varchar)) <> ''
    WHERE ac."Apply_Consult_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ac."Apply_Consult_IsDeleted" AS varchar), '0') = '0'
      AND ac."Apply_Consult_ApplyDtTm" >= '2025-07-01'
      AND ac."Apply_Consult_ApplyDtTm" < '2026-07-01'
    GROUP BY 1, 2, 3, 4, 5
),

consult_dc_rule AS (
    SELECT
        apply_id,
        visit_id,
        consult_dt,
        type_code,
        type_name,
        dept_cnt,
        CASE
            WHEN coalesce(type_name, '') LIKE '%多科%' THEN 1
            WHEN coalesce(type_name, '') LIKE '%单科%' AND dept_cnt > 2 THEN 1
            ELSE 0
        END AS hit_rule
    FROM consult_dc_base
),

mdt_tpl AS (
    SELECT DISTINCT ip."Visit_IPReg_VisitID" AS visit_id
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

surgery_hit_cache AS (
    SELECT
        o."统计区间",
        o.mropsid,
        max(CASE WHEN c.hit_rule = 1 AND c.consult_dt < o.ops_dt THEN 1 ELSE 0 END) AS hit_preop
    FROM ops_l4 o
    LEFT JOIN consult_cache_rule c
        ON o.visit_id = c.visit_id
    WHERE o."统计区间" IS NOT NULL
    GROUP BY o."统计区间", o.mropsid, o.ops_dt
),

surgery_hit_dc AS (
    SELECT
        o."统计区间",
        o.mropsid,
        max(CASE WHEN c.hit_rule = 1 AND c.consult_dt < o.ops_dt THEN 1 ELSE 0 END) AS hit_preop
    FROM ops_l4 o
    LEFT JOIN consult_dc_rule c
        ON o.visit_id = c.visit_id
    WHERE o."统计区间" IS NOT NULL
    GROUP BY o."统计区间", o.mropsid, o.ops_dt
),

probe_rows AS (
    SELECT '01_cache_会诊子表Itm行数' AS "排查项", cast(count(*) AS bigint) AS "数量", cast(null AS varchar) AS "备注"
    FROM hid0101_cache_his_dhcapp_sqluser.dhc_emconsultitm itm
    WHERE coalesce(cast(itm.isdeleted AS varchar), '0') = '0'

    UNION ALL
    SELECT '02_cache_主表有效会诊_EC_RStatus7/10', cast(count(*) AS bigint), cast(null AS varchar)
    FROM consult_cache_base

    UNION ALL
    SELECT '03_cache_EC_Category分布', cast(count(*) AS bigint), category_code
    FROM consult_cache_base
    GROUP BY category_code

    UNION ALL
    SELECT '04_cache_单科_科室数>2', cast(count(*) AS bigint), cast(max(dept_cnt) AS varchar)
    FROM consult_cache_base
    WHERE category_code = '1' AND dept_cnt > 2

    UNION ALL
    SELECT '05_cache_规则命中_多科OR单科科室>2', cast(count(*) AS bigint), cast(count(DISTINCT visit_id) AS varchar)
    FROM consult_cache_rule
    WHERE hit_rule = 1

    UNION ALL
    SELECT '06_cache_规则命中Visit数', cast(count(DISTINCT visit_id) AS bigint), cast(null AS varchar)
    FROM consult_cache_rule
    WHERE hit_rule = 1

    UNION ALL
    SELECT '07_DC会诊申请总量', cast(count(*) AS bigint), cast(null AS varchar)
    FROM consult_dc_base

    UNION ALL
    SELECT '08_DC规则命中Visit数', cast(count(DISTINCT visit_id) AS bigint), cast(null AS varchar)
    FROM consult_dc_rule
    WHERE hit_rule = 1

    UNION ALL
    SELECT '09_四级手术分母_2025H2', cast(count(DISTINCT mropsid) AS bigint), cast(count(DISTINCT visit_id) AS varchar)
    FROM ops_l4
    WHERE "统计区间" = '2025-07-01~2025-12-31'

    UNION ALL
    SELECT '10_四级手术分母_2026H1', cast(count(DISTINCT mropsid) AS bigint), cast(count(DISTINCT visit_id) AS varchar)
    FROM ops_l4
    WHERE "统计区间" = '2026-01-01~2026-06-30'

    UNION ALL
    SELECT '11_四级×cache会诊规则_术前_2025H2', cast(count(DISTINCT CASE WHEN hit_preop = 1 THEN mropsid END) AS bigint), cast(null AS varchar)
    FROM surgery_hit_cache
    WHERE "统计区间" = '2025-07-01~2025-12-31'

    UNION ALL
    SELECT '12_四级×cache会诊规则_术前_2026H1', cast(count(DISTINCT CASE WHEN hit_preop = 1 THEN mropsid END) AS bigint), cast(null AS varchar)
    FROM surgery_hit_cache
    WHERE "统计区间" = '2026-01-01~2026-06-30'

    UNION ALL
    SELECT '13_四级×DC会诊规则_术前_2025H2', cast(count(DISTINCT CASE WHEN hit_preop = 1 THEN mropsid END) AS bigint), cast(null AS varchar)
    FROM surgery_hit_dc
    WHERE "统计区间" = '2025-07-01~2025-12-31'

    UNION ALL
    SELECT '14_四级×DC会诊规则_术前_2026H1', cast(count(DISTINCT CASE WHEN hit_preop = 1 THEN mropsid END) AS bigint), cast(null AS varchar)
    FROM surgery_hit_dc
    WHERE "统计区间" = '2026-01-01~2026-06-30'

    UNION ALL
    SELECT '15_四级×模板1146/1004_2025H2', cast(count(DISTINCT o.mropsid) AS bigint), cast(null AS varchar)
    FROM ops_l4 o
    INNER JOIN mdt_tpl t ON o.visit_id = t.visit_id
    WHERE o."统计区间" = '2025-07-01~2025-12-31'

    UNION ALL
    SELECT '16_四级×模板1146/1004_2026H1', cast(count(DISTINCT o.mropsid) AS bigint), cast(null AS varchar)
    FROM ops_l4 o
    INNER JOIN mdt_tpl t ON o.visit_id = t.visit_id
    WHERE o."统计区间" = '2026-01-01~2026-06-30'

    UNION ALL
    SELECT '17_cache主表_EC_RStatus分布', cast(count(*) AS bigint), rstatus_code
    FROM consult_cache_base
    GROUP BY rstatus_code

    UNION ALL
    SELECT '18_cache单科_科室数分布', cast(count(*) AS bigint), cast(dept_cnt AS varchar)
    FROM consult_cache_base
    WHERE category_code = '1'
    GROUP BY dept_cnt
)

SELECT "排查项", "数量", "备注"
FROM probe_rows
ORDER BY "排查项";
