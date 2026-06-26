-- 三四级手术实际开展率 — 空结果/分母为0排查（Presto / HID0101）

SELECT '01_Dict_HospOPS全表行数' AS "排查项", cast(count(*) AS bigint) AS "数量", cast(null AS varchar) AS "备注"
FROM datacenter_db."Dict_HospOPS"

UNION ALL
SELECT '02_HID0101三四级备案行数', cast(count(*) AS bigint), cast(null AS varchar)
FROM datacenter_db."Dict_HospOPS" dict
WHERE dict."Dict_HospOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(dict."Dict_HospOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar)) IN ('3', '4', '03', '04')

UNION ALL
SELECT '03_HID0101三四级备案代码去重', cast(count(DISTINCT coalesce(
    nullif(trim(cast(dict."Dict_HospOPS_HospOPSCode" AS varchar)), ''),
    nullif(trim(cast(dict."Dict_HospOPS_StdOPSCode" AS varchar)), '')
)) AS bigint), cast(null AS varchar)
FROM datacenter_db."Dict_HospOPS" dict
WHERE dict."Dict_HospOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(dict."Dict_HospOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar)) IN ('3', '4', '03', '04')

UNION ALL
SELECT '04_Dict_MedOrgCode种类数', cast(count(DISTINCT trim(cast(dict."Dict_HospOPS_MedOrgCode" AS varchar))) AS bigint), cast(null AS varchar)
FROM datacenter_db."Dict_HospOPS" dict

UNION ALL
SELECT '05_HID0101级别代码分布', cast(count(*) AS bigint), trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar))
FROM datacenter_db."Dict_HospOPS" dict
WHERE dict."Dict_HospOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(dict."Dict_HospOPS_IsDeleted" AS varchar), '0') = '0'
GROUP BY trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar))

UNION ALL
SELECT '06_MR_FPOPS三四级手术例数', cast(count(DISTINCT ops."MR_FPOPS_MROPSID") AS bigint), cast(null AS varchar)
FROM datacenter_db."MR_FPOPS" ops
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4', '03', '04')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'

UNION ALL
SELECT '07_MR_FPOPS三四级术种键去重', cast(count(DISTINCT
    CASE
        WHEN trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)) <> ''
         AND strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') > 0 THEN
            lower(concat(
                substr(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), 1, strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') - 1),
                '.',
                substr(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') + 1, 2)
            ))
        ELSE lower(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)))
    END
) AS bigint), cast(null AS varchar)
FROM datacenter_db."MR_FPOPS" ops
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4', '03', '04')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
  AND trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)) <> ''

-- 排查01=0：Dict_HospOPS 未入仓；06/07 MR_FPOPS 有数

UNION ALL
SELECT '08_MR_FPOPS全历史三四级术种键', cast(count(DISTINCT
    CASE
        WHEN trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)) <> ''
         AND strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') > 0 THEN
            lower(concat(
                substr(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), 1, strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') - 1),
                '.',
                substr(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') + 1, 2)
            ))
        ELSE lower(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)))
    END
) AS bigint), cast(null AS varchar)
FROM datacenter_db."MR_FPOPS" ops
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4', '03', '04')
  AND trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)) <> ''

ORDER BY "排查项";
