-- 三、四级手术实际开展率（两个固定区间各一行）
-- 术种键：手术编码小数点后仅保留 2 位（32.521 / 32.522 → 32.52）
-- 区间1：2025-07-01 ~ 2025-12-31
-- 区间2：2026-01-01 ~ 2026-06-30
-- 院区：HID0101
--
-- 分母（备案术种）：
--   优先 Dict_HospOPS；数仓该表为空时（排查01=0）改 MR_FPOPS 全历史三四级术种键代理
-- 分子：同期实际开展且落在备案术种集合内的去重术种键

WITH
intervals AS (
    SELECT '2025-07-01~2025-12-31' AS "统计区间",
           '2025-07-01' AS dt_start,
           '2026-01-01' AS dt_end
    UNION ALL
    SELECT '2026-01-01~2026-06-30',
           '2026-01-01',
           '2026-07-01'
),

level_dim AS (
    SELECT '3' AS "手术级别代码"
    UNION ALL
    SELECT '4'
),

dict_registered_raw AS (
    SELECT
        CASE
            WHEN trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar)) IN ('3', '03') THEN '3'
            WHEN trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar)) IN ('4', '04') THEN '4'
            ELSE trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar))
        END AS "手术级别代码",
        coalesce(
            nullif(trim(cast(dict."Dict_HospOPS_HospOPSCode" AS varchar)), ''),
            nullif(trim(cast(dict."Dict_HospOPS_StdOPSCode" AS varchar)), ''),
            nullif(trim(cast(dict."Dict_HospOPS_InsuOPSCode" AS varchar)), ''),
            nullif(trim(cast(dict."Dict_HospOPS_OtherOPSCode" AS varchar)), '')
        ) AS ops_code
    FROM datacenter_db."Dict_HospOPS" dict
    WHERE dict."Dict_HospOPS_MedOrgCode" = 'HID0101'
      AND coalesce(cast(dict."Dict_HospOPS_IsDeleted" AS varchar), '0') = '0'
      AND coalesce(cast(dict."Dict_HospOPS_StopFlag" AS varchar), '0') IN ('0', '')
      AND CASE
            WHEN trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar)) IN ('3', '03') THEN '3'
            WHEN trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar)) IN ('4', '04') THEN '4'
            ELSE trim(cast(dict."Dict_HospOPS_OPSLevelCode" AS varchar))
          END IN ('3', '4')
      AND coalesce(
            nullif(trim(cast(dict."Dict_HospOPS_HospOPSCode" AS varchar)), ''),
            nullif(trim(cast(dict."Dict_HospOPS_StdOPSCode" AS varchar)), ''),
            nullif(trim(cast(dict."Dict_HospOPS_InsuOPSCode" AS varchar)), ''),
            nullif(trim(cast(dict."Dict_HospOPS_OtherOPSCode" AS varchar)), '')
          ) IS NOT NULL
),

mr_fpops_catalog_raw AS (
    SELECT
        CASE
            WHEN trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '03') THEN '3'
            WHEN trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('4', '04') THEN '4'
            ELSE trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar))
        END AS "手术级别代码",
        trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)) AS ops_code
    FROM datacenter_db."MR_FPOPS" ops
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)) <> ''
      AND CASE
            WHEN trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '03') THEN '3'
            WHEN trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('4', '04') THEN '4'
            ELSE trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar))
          END IN ('3', '4')
      AND EXISTS (
          SELECT 1
          FROM datacenter_db."MR_FP" fp
          WHERE fp."MR_FP_VisitID" = ops."MR_FPOPS_VisitID"
            AND fp."MR_FP_MedOrgCode" = 'HID0101'
            AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      )
),

catalog_union_raw AS (
    SELECT "手术级别代码", ops_code FROM dict_registered_raw
    UNION ALL
    SELECT "手术级别代码", ops_code FROM mr_fpops_catalog_raw
    WHERE NOT EXISTS (SELECT 1 FROM dict_registered_raw LIMIT 1)
),

registered_types_key AS (
    SELECT DISTINCT
        "手术级别代码",
        CASE
            WHEN ops_code <> '' AND strpos(ops_code, '.') > 0 THEN
                lower(concat(
                    substr(ops_code, 1, strpos(ops_code, '.') - 1),
                    '.',
                    substr(ops_code, strpos(ops_code, '.') + 1, 2)
                ))
            ELSE lower(ops_code)
        END AS ops_type_key
    FROM catalog_union_raw
    WHERE ops_code IS NOT NULL AND ops_code <> ''
),

registered_count AS (
    SELECT
        "手术级别代码",
        count(DISTINCT ops_type_key) AS "备案术种数"
    FROM registered_types_key
    GROUP BY "手术级别代码"
),

actual_ops AS (
    SELECT
        iv."统计区间",
        CASE
            WHEN trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '03') THEN '3'
            WHEN trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('4', '04') THEN '4'
            ELSE trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar))
        END AS "手术级别代码",
        CASE
            WHEN trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)) <> ''
             AND strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') > 0 THEN
                lower(concat(
                    substr(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), 1, strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') - 1),
                    '.',
                    substr(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), strpos(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)), '.') + 1, 2)
                ))
            ELSE lower(trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)))
        END AS ops_type_key
    FROM datacenter_db."MR_FPOPS" ops
    INNER JOIN datacenter_db."MR_FP" fp
        ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
    INNER JOIN intervals iv
        ON ops."MR_FPOPS_OPSDtTm" >= iv.dt_start
       AND ops."MR_FPOPS_OPSDtTm" < iv.dt_end
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND fp."MR_FP_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      AND ops."MR_FPOPS_OPSDtTm" IS NOT NULL
      AND trim(cast(ops."MR_FPOPS_OPSDtTm" AS varchar)) <> ''
      AND trim(cast(ops."MR_FPOPS_OPSCode" AS varchar)) <> ''
      AND CASE
            WHEN trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '03') THEN '3'
            WHEN trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('4', '04') THEN '4'
            ELSE trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar))
          END IN ('3', '4')
),

actual_registered_types AS (
    SELECT DISTINCT
        a."统计区间",
        a."手术级别代码",
        a.ops_type_key AS ops_type_code
    FROM actual_ops a
    INNER JOIN registered_types_key r
        ON a."手术级别代码" = r."手术级别代码"
       AND a.ops_type_key = r.ops_type_key
),

actual_count AS (
    SELECT
        "统计区间",
        "手术级别代码",
        count(DISTINCT ops_type_code) AS "实际开展备案术种数"
    FROM actual_registered_types
    GROUP BY "统计区间", "手术级别代码"
),

interval_level AS (
    SELECT
        iv."统计区间",
        ld."手术级别代码",
        coalesce(ac."实际开展备案术种数", cast(0 AS bigint)) AS "实际开展备案术种数",
        coalesce(rc."备案术种数", cast(0 AS bigint)) AS "备案术种数"
    FROM intervals iv
    CROSS JOIN level_dim ld
    LEFT JOIN registered_count rc
        ON ld."手术级别代码" = rc."手术级别代码"
    LEFT JOIN actual_count ac
        ON iv."统计区间" = ac."统计区间"
       AND ld."手术级别代码" = ac."手术级别代码"
),

interval_summary AS (
    SELECT
        "统计区间",
        max(CASE WHEN "手术级别代码" = '3' THEN "实际开展备案术种数" END) AS "三级实际开展术种数",
        max(CASE WHEN "手术级别代码" = '3' THEN "备案术种数" END) AS "三级备案术种数",
        max(CASE WHEN "手术级别代码" = '4' THEN "实际开展备案术种数" END) AS "四级实际开展术种数",
        max(CASE WHEN "手术级别代码" = '4' THEN "备案术种数" END) AS "四级备案术种数"
    FROM interval_level
    GROUP BY "统计区间"
)

SELECT
    "统计区间",
    coalesce("三级实际开展术种数", cast(0 AS bigint)) AS "分子_三级实际开展术种数",
    coalesce("三级备案术种数", cast(0 AS bigint)) AS "分母_三级备案术种数",
    CASE
        WHEN coalesce("三级备案术种数", cast(0 AS bigint)) > 0 THEN
            round(
                cast(coalesce("三级实际开展术种数", cast(0 AS bigint)) AS double)
                / cast("三级备案术种数" AS double) * 100,
                2
            )
        ELSE 0
    END AS "三级手术实际开展率(%)",
    coalesce("四级实际开展术种数", cast(0 AS bigint)) AS "分子_四级实际开展术种数",
    coalesce("四级备案术种数", cast(0 AS bigint)) AS "分母_四级备案术种数",
    CASE
        WHEN coalesce("四级备案术种数", cast(0 AS bigint)) > 0 THEN
            round(
                cast(coalesce("四级实际开展术种数", cast(0 AS bigint)) AS double)
                / cast("四级备案术种数" AS double) * 100,
                2
            )
        ELSE 0
    END AS "四级手术实际开展率(%)",
    coalesce("三级实际开展术种数", cast(0 AS bigint)) + coalesce("四级实际开展术种数", cast(0 AS bigint)) AS "分子_三四级实际开展术种数",
    coalesce("三级备案术种数", cast(0 AS bigint)) + coalesce("四级备案术种数", cast(0 AS bigint)) AS "分母_三四级备案术种数",
    CASE
        WHEN coalesce("三级备案术种数", cast(0 AS bigint)) + coalesce("四级备案术种数", cast(0 AS bigint)) > 0 THEN
            round(
                cast(coalesce("三级实际开展术种数", cast(0 AS bigint)) + coalesce("四级实际开展术种数", cast(0 AS bigint)) AS double)
                / cast(coalesce("三级备案术种数", cast(0 AS bigint)) + coalesce("四级备案术种数", cast(0 AS bigint)) AS double) * 100,
                2
            )
        ELSE 0
    END AS "三四级手术整体实际开展率(%)"
FROM interval_summary
ORDER BY "统计区间";

-- 排查01=0：Dict_HospOPS 未入仓 → 分母改 MR_FPOPS 全历史三四级术种键（代理备案）
-- Dict 入仓后自动切回正式备案目录
