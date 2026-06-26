-- 四级手术与三级手术患者死亡率比（两个固定区间各一行）
-- 定义：四级手术患者死亡率与三级手术患者死亡率的比
-- 计算公式：
--   四级手术患者死亡率 = 四级手术死亡患者人数 / 四级手术总例数 × 100%
--   三级手术患者死亡率 = 三级手术死亡患者人数 / 三级手术总例数 × 100%
--   四级与三级手术患者死亡率比 = 四级手术患者死亡率 ÷ 三级手术患者死亡率
-- 区间1：2025-07-01 ~ 2025-12-31
-- 区间2：2026-01-01 ~ 2026-06-30
--
-- 口径说明（分母与并发症发生率比对齐）：
--   分母：OPSSeqNo=1 主手术行 count(DISTINCT MROPSID)，MR_FP EXISTS，按 OPSDtTm 归区间
--   分子：死亡按 VisitID 计 1 人；同区间兼做三+四级 → 死亡只归四级，三级不计
--   兼有判定（方案A）：仅 OPSSeqNo=1 主手术行内兼有三四级 → 死亡归四级
--   死亡：MR_FP 离院方式含「死亡/亡」（OutHospModeName/Code LIKE）
--   院区：MR_FPOPS / MR_FP .MedOrgCode = HID0101

WITH
visit_death AS (
    SELECT DISTINCT
        fp."MR_FP_VisitID" AS visit_id
    FROM datacenter_db."MR_FP" fp
    WHERE fp."MR_FP_MedOrgCode" = 'HID0101'
      AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      AND (
            fp."MR_FP_OutHospModeName" LIKE '%死亡%'
            OR fp."MR_FP_OutHospModeCode" LIKE '%死亡%'
            OR fp."MR_FP_OutHospModeName" LIKE '%亡%'
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
        max(CASE WHEN vd.visit_id IS NOT NULL THEN 1 ELSE 0 END) AS "死亡标识"
    FROM ops_filtered o
    LEFT JOIN visit_death vd
        ON o."就诊ID" = vd.visit_id
    WHERE o."统计区间" IS NOT NULL
    GROUP BY
        o."统计区间",
        o."就诊ID",
        o."手术序号",
        o."手术行ID",
        o."手术级别代码"
),

denominator_stats AS (
    SELECT
        "统计区间",
        "手术级别代码",
        max("手术级别名称") AS "手术级别名称",
        count(DISTINCT "手术行ID") AS "手术总例数"
    FROM base_surgery_data
    GROUP BY "统计区间", "手术级别代码"
),

visit_death_alloc AS (
    SELECT
        "统计区间",
        "就诊ID",
        max("死亡标识") AS "死亡标识",
        max(CASE WHEN "手术级别代码" = '4' THEN 1 ELSE 0 END) AS has_level4
    FROM base_surgery_data
    GROUP BY "统计区间", "就诊ID"
),

death_stats AS (
    SELECT
        "统计区间",
        count(DISTINCT CASE
            WHEN "死亡标识" = 1 AND has_level4 = 1 THEN "就诊ID"
        END) AS "四级手术死亡患者人数",
        count(DISTINCT CASE
            WHEN "死亡标识" = 1 AND has_level4 = 0 THEN "就诊ID"
        END) AS "三级手术死亡患者人数"
    FROM visit_death_alloc
    GROUP BY "统计区间"
),

denominator_pivot AS (
    SELECT
        "统计区间",
        max(CASE WHEN "手术级别代码" = '3' THEN "手术总例数" END) AS "三级手术总例数",
        max(CASE WHEN "手术级别代码" = '4' THEN "手术总例数" END) AS "四级手术总例数"
    FROM denominator_stats
    GROUP BY "统计区间"
),

interval_summary AS (
    SELECT
        dp."统计区间",
        coalesce(dp."三级手术总例数", cast(0 AS bigint)) AS "三级手术总例数",
        coalesce(dp."四级手术总例数", cast(0 AS bigint)) AS "四级手术总例数",
        coalesce(ds."三级手术死亡患者人数", cast(0 AS bigint)) AS "三级手术死亡患者人数",
        coalesce(ds."四级手术死亡患者人数", cast(0 AS bigint)) AS "四级手术死亡患者人数"
    FROM denominator_pivot dp
    LEFT JOIN death_stats ds
        ON dp."统计区间" = ds."统计区间"
),

interval_rates AS (
    SELECT
        "统计区间",
        "三级手术总例数",
        "三级手术死亡患者人数",
        "四级手术总例数",
        "四级手术死亡患者人数",
        CASE
            WHEN "三级手术总例数" > 0 THEN
                round(
                    cast("三级手术死亡患者人数" AS double)
                    / cast("三级手术总例数" AS double) * 100,
                    4
                )
            ELSE 0
        END AS "三级手术患者死亡率(%)",
        CASE
            WHEN "四级手术总例数" > 0 THEN
                round(
                    cast("四级手术死亡患者人数" AS double)
                    / cast("四级手术总例数" AS double) * 100,
                    4
                )
            ELSE 0
        END AS "四级手术患者死亡率(%)"
    FROM interval_summary
)

SELECT
    "统计区间",
    "三级手术死亡患者人数" AS "分子_三级死亡",
    "三级手术总例数" AS "分母_三级手术",
    "三级手术患者死亡率(%)",
    "四级手术死亡患者人数" AS "分子_四级死亡",
    "四级手术总例数" AS "分母_四级手术",
    "四级手术患者死亡率(%)",
    CASE
        WHEN "三级手术患者死亡率(%)" > 0 THEN
            round(
                cast("四级手术患者死亡率(%)" AS double)
                / cast("三级手术患者死亡率(%)" AS double),
                4
            )
        ELSE NULL
    END AS "四级与三级手术患者死亡率比"
FROM interval_rates
ORDER BY "统计区间";

-- 修正点（与并发症发生率比分母对齐）：
-- 1) 分母仅 OPSSeqNo=1 主手术行
-- 2) MR_FP 改 EXISTS，避免一对多 JOIN 放大
-- 3) 死亡改 visit_death + VisitID 关联
-- 4) base 层按 VisitID+OPSSeqNo+MROPSID 聚合后再计数
-- 5) 分子保留：同区间 OPSSeqNo=1 内兼有三四级 → 死亡只归四级（方案A）
