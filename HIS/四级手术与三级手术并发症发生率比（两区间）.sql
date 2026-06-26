-- 四级手术与三级手术并发症发生率比（两个固定区间各一行）
--
-- 国考口径：
--   三/四级手术：MR_FPOPS_OPSLevelCode IN ('3','4')
--   分母：同期三/四级手术例数（修正：VisitID+OPSSeqNo 去重，仅 OPSSeqNo=1 主手术行）
--   分子：同期三/四级主手术中发生手术并发症的就诊数 count(DISTINCT VisitID)
--   并发症：Visit_Diag T81/T88，按 Visit_Diag_VisitID 关联（不用 VisitNo 多键）
--   比 = 四级并发症发生率 ÷ 三级并发症发生率
-- 区间1：2025-07-01 ~ 2025-12-31
-- 区间2：2026-01-01 ~ 2026-06-30
-- 院区：HID0101

WITH
visit_complication AS (
    SELECT DISTINCT
        diag."Visit_Diag_VisitID" AS visit_id
    FROM datacenter_db."Visit_Diag" diag
    WHERE diag."Visit_Diag_MedOrgCode" = 'HID0101'
      AND coalesce(cast(diag."Visit_Diag_IsDeleted" AS varchar), '0') = '0'
      AND (
            trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T88%'
          )
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
        trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '1')) AS "手术序号",
        trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) AS "手术级别代码",
        trim(cast(ops."MR_FPOPS_OPSLevelName" AS varchar)) AS "手术级别名称"
    FROM datacenter_db."MR_FPOPS" ops
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND ops."MR_FPOPS_OPSDtTm" IS NOT NULL
      AND trim(cast(ops."MR_FPOPS_OPSDtTm" AS varchar)) <> ''
      AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
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

base_surgery_data AS (
    SELECT
        o."统计区间",
        o."手术行ID",
        o."就诊ID",
        o."手术级别代码",
        max(o."手术级别名称") AS "手术级别名称",
        max(CASE WHEN vc.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS "并发症标识"
    FROM ops_filtered o
    LEFT JOIN visit_complication vc
        ON o."就诊ID" = vc.visit_id
    WHERE o."统计区间" IS NOT NULL
    GROUP BY
        o."统计区间",
        o."就诊ID",
        o."手术序号",
        o."手术行ID",
        o."手术级别代码"
),

interval_level_stats AS (
    SELECT
        "统计区间",
        "手术级别代码",
        max("手术级别名称") AS "手术级别名称",
        count(DISTINCT "手术行ID") AS "手术总例数",
        count(DISTINCT CASE WHEN "并发症标识" = 1 THEN "就诊ID" END) AS "并发症发生例数"
    FROM base_surgery_data
    GROUP BY "统计区间", "手术级别代码"
),

interval_summary AS (
    SELECT
        "统计区间",
        max(CASE WHEN "手术级别代码" = '3' THEN "手术总例数" END) AS "三级手术总例数",
        max(CASE WHEN "手术级别代码" = '3' THEN "并发症发生例数" END) AS "三级手术并发症例数",
        max(CASE WHEN "手术级别代码" = '4' THEN "手术总例数" END) AS "四级手术总例数",
        max(CASE WHEN "手术级别代码" = '4' THEN "并发症发生例数" END) AS "四级手术并发症例数"
    FROM interval_level_stats
    GROUP BY "统计区间"
),

interval_rates AS (
    SELECT
        "统计区间",
        coalesce("三级手术总例数", cast(0 AS bigint)) AS "三级手术总例数",
        coalesce("三级手术并发症例数", cast(0 AS bigint)) AS "三级手术并发症例数",
        coalesce("四级手术总例数", cast(0 AS bigint)) AS "四级手术总例数",
        coalesce("四级手术并发症例数", cast(0 AS bigint)) AS "四级手术并发症例数",
        CASE
            WHEN coalesce("三级手术总例数", cast(0 AS bigint)) > 0 THEN
                round(
                    cast(coalesce("三级手术并发症例数", cast(0 AS bigint)) AS double)
                    / cast("三级手术总例数" AS double) * 100,
                    4
                )
            ELSE 0
        END AS "三级手术并发症发生率(%)",
        CASE
            WHEN coalesce("四级手术总例数", cast(0 AS bigint)) > 0 THEN
                round(
                    cast(coalesce("四级手术并发症例数", cast(0 AS bigint)) AS double)
                    / cast("四级手术总例数" AS double) * 100,
                    4
                )
            ELSE 0
        END AS "四级手术并发症发生率(%)"
    FROM interval_summary
)

SELECT
    "统计区间",
    "三级手术并发症例数" AS "分子_三级并发症",
    "三级手术总例数" AS "分母_三级手术",
    "三级手术并发症发生率(%)",
    "四级手术并发症例数" AS "分子_四级并发症",
    "四级手术总例数" AS "分母_四级手术",
    "四级手术并发症发生率(%)",
    CASE
        WHEN "三级手术并发症发生率(%)" > 0 THEN
            round(
                cast("四级手术并发症发生率(%)" AS double)
                / cast("三级手术并发症发生率(%)" AS double),
                4
            )
        ELSE NULL
    END AS "四级与三级手术并发症发生率比"
FROM interval_rates
ORDER BY "统计区间";

-- 修正点：
-- 1) 分母仅 OPSSeqNo=1（病案首页第一手术/主手术行），避免 2/3/4 台叠加
-- 2) MR_FP 改 EXISTS，避免一对多 JOIN 放大中间行
-- 3) 并发症改 Visit_Diag_VisitID 关联，不用 VisitNo 多键
-- 4) base 层按 VisitID+OPSSeqNo+MROPSID 聚合后再计数
