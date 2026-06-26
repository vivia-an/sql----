-- 四级手术术前多学科讨论完成率（两个固定区间各一行）
--
-- 国考口径：
--   分母：同期四级手术总例数 count(DISTINCT MROPSID)
--   分子：术前完成多学科讨论的四级手术例数
--   完成率 = 分子 / 分母 × 100%
--
-- 多学科判定（OR 合并，术前时间 < OPSDtTm）：
--   A. EMR 模板 ID 1146/1004：instancedata.templateid 或 Case_CDAMainDoc_TemplateID
--   B. DHC 会诊：多科(EC_Category<>1) OR（单科 AND ec_cloc_dr 去重科室数>2）
--      有效会诊：EC_RStatus IN (7,10)、EC_Type<>'DOCA'；时间 EC_RDate+RTime
-- 排除：急诊入院（Visit_IPReg 入院途径/方式含「急诊」，或途径代码=1）
-- 分母：四级 OPSSeqNo=1 + MR_FP EXISTS + HID0101 + 非急诊入院
-- 区间1：2025-07-01 ~ 2025-12-31
-- 区间2：2026-01-01 ~ 2026-06-30

WITH
mdt_doc_cache AS (
    SELECT
        ip."Visit_IPReg_VisitID" AS visit_id,
        trim(cast(idata.templateid AS varchar)) AS template_id,
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
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospModeName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayCode" AS varchar)), '') NOT IN ('1')
    WHERE coalesce(cast(idata.isdeleted AS varchar), '0') = '0'
      AND trim(cast(idata.templateid AS varchar)) IN ('1146', '1004')
),

mdt_doc_cda AS (
    SELECT
        doc."Case_CDAMainDoc_VisitID" AS visit_id,
        trim(cast(doc."Case_CDAMainDoc_TemplateID" AS varchar)) AS template_id,
        coalesce(
            try_cast(doc."Case_CDAMainDoc_FinishDtTm" AS timestamp),
            try_cast(doc."Case_CDAMainDoc_CreateDtTm" AS timestamp),
            try_cast(doc."Case_CDAMainDoc_RecordDtTm" AS timestamp)
        ) AS doc_dt
    FROM datacenter_db."Case_CDAMainDoc" doc
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON doc."Case_CDAMainDoc_VisitID" = ip."Visit_IPReg_VisitID"
       AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
       AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospModeName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayCode" AS varchar)), '') NOT IN ('1')
    WHERE doc."Case_CDAMainDoc_MedOrgCode" = 'HID0101'
      AND coalesce(cast(doc."Case_CDAMainDoc_IsDeleted" AS varchar), '0') = '0'
      AND trim(cast(doc."Case_CDAMainDoc_TemplateID" AS varchar)) IN ('1146', '1004')
      AND coalesce(cast(doc."Case_CDAMainDoc_WritStatusCode" AS varchar), '1') = '1'
),

mdt_doc AS (
    SELECT visit_id, template_id, doc_dt FROM mdt_doc_cache
    UNION ALL
    SELECT visit_id, template_id, doc_dt FROM mdt_doc_cda
),

mdt_consult_itm_cnt AS (
    SELECT
        trim(cast(itm.ec_parref_dr AS varchar)) AS consult_id,
        count(DISTINCT trim(cast(itm.ec_cloc_dr AS varchar))) AS dept_cnt
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
        ) AS consult_dt
    FROM hid0101_cache_his_dhcapp_sqluser.dhc_emconsult c
    INNER JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
        ON cast(c.ec_adm_dr AS varchar) = cast(adm.paadm_rowid AS varchar)
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON trim(cast(adm.paadm_admno AS varchar)) = trim(cast(ip."Visit_IPReg_VisitNo" AS varchar))
       AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
       AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospModeName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayCode" AS varchar)), '') NOT IN ('1')
    LEFT JOIN mdt_consult_itm_cnt ic
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

mdt_evidence AS (
    SELECT visit_id, doc_dt AS mdt_dt FROM mdt_doc
    UNION ALL
    SELECT visit_id, consult_dt AS mdt_dt FROM mdt_consult
),

ops_filtered AS (
    SELECT
        CASE
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
             AND ops."MR_FPOPS_OPSDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2026-01-01'
             AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        ops."MR_FPOPS_MROPSID" AS "手术行ID",
        ops."MR_FPOPS_VisitID" AS "就诊ID",
        try_cast(ops."MR_FPOPS_OPSDtTm" AS timestamp) AS "手术时间"
    FROM datacenter_db."MR_FPOPS" ops
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON ops."MR_FPOPS_VisitID" = ip."Visit_IPReg_VisitID"
       AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
       AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospModeName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayCode" AS varchar)), '') NOT IN ('1')
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND ops."MR_FPOPS_OPSDtTm" IS NOT NULL
      AND trim(cast(ops."MR_FPOPS_OPSDtTm" AS varchar)) <> ''
      AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) = '4'
      AND trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '1')) = '1'
      AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
      AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
      AND EXISTS (
          SELECT 1
          FROM datacenter_db."MR_FP" fp
          WHERE fp."MR_FP_VisitID" = ops."MR_FPOPS_VisitID"
            AND fp."MR_FP_MedOrgCode" = 'HID0101'
            AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      )
),

base_surgery AS (
    SELECT
        o."统计区间",
        o."手术行ID",
        o."就诊ID",
        max(CASE
            WHEN e.visit_id IS NOT NULL
             AND e.mdt_dt IS NOT NULL
             AND e.mdt_dt < o."手术时间"
                THEN 1
            ELSE 0
        END) AS "多学科讨论标识"
    FROM ops_filtered o
    LEFT JOIN mdt_evidence e
        ON o."就诊ID" = e.visit_id
    WHERE o."统计区间" IS NOT NULL
    GROUP BY
        o."统计区间",
        o."手术行ID",
        o."就诊ID",
        o."手术时间"
),

interval_stats AS (
    SELECT
        "统计区间",
        count(DISTINCT "手术行ID") AS "四级手术总例数",
        count(DISTINCT CASE WHEN "多学科讨论标识" = 1 THEN "手术行ID" END) AS "术前多学科讨论例数"
    FROM base_surgery
    GROUP BY "统计区间"
)

SELECT
    "统计区间",
    "术前多学科讨论例数" AS "分子_术前多学科讨论",
    "四级手术总例数" AS "分母_四级手术",
    CASE
        WHEN "四级手术总例数" > 0 THEN
            round(
                cast("术前多学科讨论例数" AS double)
                / cast("四级手术总例数" AS double) * 100,
                4
            )
        ELSE 0
    END AS "四级手术术前多学科讨论完成率(%)"
FROM interval_stats
ORDER BY "统计区间";
