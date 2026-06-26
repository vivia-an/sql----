-- 四级手术术前多学科讨论 — 分子为0排查（Presto / HID0101）
-- 与主 SQL 同区间；单条 UNION ALL 阶梯输出

WITH
ops_visit AS (
    SELECT DISTINCT ops."MR_FPOPS_VisitID" AS visit_id
    FROM datacenter_db."MR_FPOPS" ops
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON ops."MR_FPOPS_VisitID" = ip."Visit_IPReg_VisitID"
       AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
       AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayCode" AS varchar)), '') NOT IN ('1')
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
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

cda_tpl AS (
    SELECT
        trim(cast(doc."Case_CDAMainDoc_TemplateID" AS varchar)) AS template_id,
        doc."Case_CDAMainDoc_VisitID" AS visit_id
    FROM datacenter_db."Case_CDAMainDoc" doc
    WHERE doc."Case_CDAMainDoc_MedOrgCode" = 'HID0101'
      AND coalesce(cast(doc."Case_CDAMainDoc_IsDeleted" AS varchar), '0') = '0'
      AND trim(cast(doc."Case_CDAMainDoc_TemplateID" AS varchar)) IN ('1146', '1004')
),

cache_mdt AS (
    SELECT DISTINCT
        ip."Visit_IPReg_VisitID" AS visit_id,
        trim(cast(idata.templateid AS varchar)) AS template_id
    FROM hid0101_cache_his_dhcapp_emrinstance.instancedata idata
    INNER JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
        ON cast(idata.episodeid AS varchar) = cast(adm.paadm_rowid AS varchar)
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON trim(cast(adm.paadm_admno AS varchar)) = trim(cast(ip."Visit_IPReg_VisitNo" AS varchar))
       AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
       AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayName" AS varchar)), '') NOT LIKE '%急诊%'
       AND coalesce(trim(cast(ip."Visit_IPReg_InHospPathwayCode" AS varchar)), '') NOT IN ('1')
    WHERE coalesce(cast(idata.isdeleted AS varchar), '0') = '0'
      AND trim(cast(idata.templateid AS varchar)) IN ('1146', '1004')
),

cda_name AS (
    SELECT count(*) AS cnt
    FROM datacenter_db."Case_CDAMainDoc" doc
    WHERE doc."Case_CDAMainDoc_MedOrgCode" = 'HID0101'
      AND coalesce(cast(doc."Case_CDAMainDoc_IsDeleted" AS varchar), '0') = '0'
      AND (
            doc."Case_CDAMainDoc_TemplateName" LIKE '%多学科%'
            OR doc."Case_CDAMainDoc_TemplateShowName" LIKE '%多学科%'
            OR doc."Case_CDAMainDoc_WritHeadline" LIKE '%多学科%'
          )
)

SELECT '01_CDA模板1146文书数' AS "排查项", cast(count(*) AS bigint) AS "数量", cast(null AS varchar) AS "备注"
FROM datacenter_db."Case_CDAMainDoc" doc
WHERE doc."Case_CDAMainDoc_MedOrgCode" = 'HID0101'
  AND coalesce(cast(doc."Case_CDAMainDoc_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(doc."Case_CDAMainDoc_TemplateID" AS varchar)) = '1146'

UNION ALL
SELECT '02_CDA模板1004文书数', cast(count(*) AS bigint), cast(null AS varchar)
FROM datacenter_db."Case_CDAMainDoc" doc
WHERE doc."Case_CDAMainDoc_MedOrgCode" = 'HID0101'
  AND coalesce(cast(doc."Case_CDAMainDoc_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(doc."Case_CDAMainDoc_TemplateID" AS varchar)) = '1004'

UNION ALL
SELECT '03_CDA名称含多学科文书数', cnt, cast(null AS varchar) FROM cda_name

UNION ALL
SELECT '04_CDA两模板同Visit数_AND', cast(count(*) AS bigint), cast(null AS varchar)
FROM (
    SELECT visit_id FROM cda_tpl GROUP BY visit_id
    HAVING count(DISTINCT template_id) = 2
) t

UNION ALL
SELECT '05_CDA任一模板的Visit数_OR', cast(count(DISTINCT visit_id) AS bigint), cast(null AS varchar)
FROM cda_tpl

UNION ALL
SELECT '06_cache_instancedata_1146/1004行数', cast(count(*) AS bigint), cast(null AS varchar)
FROM cache_mdt

UNION ALL
SELECT '07_cache任一模板的Visit数_OR', cast(count(DISTINCT visit_id) AS bigint), cast(null AS varchar)
FROM cache_mdt

UNION ALL
SELECT '08_cache两模板同Visit数_AND', cast(count(*) AS bigint), cast(null AS varchar)
FROM (
    SELECT visit_id FROM cache_mdt GROUP BY visit_id
    HAVING count(DISTINCT template_id) = 2
) t

UNION ALL
SELECT '09_四级手术Visit与CDA_OR交集', cast(count(*) AS bigint), 'VisitID直接关联'
FROM ops_visit o
INNER JOIN (SELECT DISTINCT visit_id FROM cda_tpl) c ON o.visit_id = c.visit_id

UNION ALL
SELECT '10_四级手术Visit与cache_OR交集', cast(count(*) AS bigint), 'pa_adm→VisitNo→VisitID'
FROM ops_visit o
INNER JOIN (SELECT DISTINCT visit_id FROM cache_mdt) c ON o.visit_id = c.visit_id

UNION ALL
SELECT '11_四级手术Visit与CDA_AND交集', cast(count(*) AS bigint), cast(null AS varchar)
FROM ops_visit o
INNER JOIN (
    SELECT visit_id FROM cda_tpl GROUP BY visit_id HAVING count(DISTINCT template_id) = 2
) c ON o.visit_id = c.visit_id

UNION ALL
SELECT '12_四级手术Visit与cache_AND交集', cast(count(*) AS bigint), cast(null AS varchar)
FROM ops_visit o
INNER JOIN (
    SELECT visit_id FROM cache_mdt GROUP BY visit_id HAVING count(DISTINCT template_id) = 2
) c ON o.visit_id = c.visit_id

ORDER BY "排查项";
