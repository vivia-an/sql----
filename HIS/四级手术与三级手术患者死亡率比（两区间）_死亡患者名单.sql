-- 四级手术与三级手术患者死亡率比 — 死亡患者名单（两区间）
-- 口径与主指标一致；每人每区间仅 1 行
--   分母筛选：OPSSeqNo=1、MR_FP EXISTS、三四级主手术
--   兼有判定（方案A）：仅 OPSSeqNo=1 内兼有三四级 → 死亡计入四级
--   死亡：MR_FP 离院方式含「死亡/亡」

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
        trim(cast(ops."MR_FPOPS_OPSLevelName" AS varchar)) AS "手术级别名称",
        trim(cast(ops."MR_FPOPS_PlanOPSName" AS varchar)) AS "手术名称",
        ops."MR_FPOPS_OPSDtTm" AS "手术日期"
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
        max(o."手术名称") AS "手术名称",
        max(o."手术日期") AS "手术日期",
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

visit_death_alloc AS (
    SELECT
        "统计区间",
        "就诊ID",
        max("死亡标识") AS "死亡标识",
        max(CASE WHEN "手术级别代码" = '4' THEN 1 ELSE 0 END) AS has_level4,
        max(CASE WHEN "手术级别代码" = '3' THEN 1 ELSE 0 END) AS has_level3
    FROM base_surgery_data
    GROUP BY "统计区间", "就诊ID"
),

visit_surgery_summary AS (
    SELECT
        "统计区间",
        "就诊ID",
        array_join(array_sort(array_distinct(array_agg("手术级别代码"))), ',') AS "主手术级别汇总",
        array_join(
            array_distinct(array_agg(concat('L', "手术级别代码", ':', coalesce("手术名称", '')))),
            ' | '
        ) AS "主手术明细",
        min("手术日期") AS "最早主手术日期",
        max("手术日期") AS "最晚主手术日期"
    FROM base_surgery_data
    GROUP BY "统计区间", "就诊ID"
)

SELECT
    d."统计区间",
    d."就诊ID",
    trim(cast(fp."MR_FP_VisitNo" AS varchar)) AS "住院号",
    trim(cast(fp."MR_FP_PersName" AS varchar)) AS "患者姓名",
    CASE
        WHEN d.has_level4 = 1 THEN '四级'
        ELSE '三级'
    END AS "死亡计入级别",
    CASE
        WHEN d.has_level3 = 1 AND d.has_level4 = 1 THEN '是'
        ELSE '否'
    END AS "兼有三四级",
    vs."主手术级别汇总",
    vs."主手术明细",
    vs."最早主手术日期",
    vs."最晚主手术日期",
    trim(cast(fp."MR_FP_OutHospModeName" AS varchar)) AS "离院方式名称",
    trim(cast(fp."MR_FP_OutHospModeCode" AS varchar)) AS "离院方式代码",
    fp."MR_FP_OutHospDtTm" AS "出院日期"
FROM visit_death_alloc d
INNER JOIN datacenter_db."MR_FP" fp
    ON d."就诊ID" = fp."MR_FP_VisitID"
   AND fp."MR_FP_MedOrgCode" = 'HID0101'
   AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
LEFT JOIN visit_surgery_summary vs
    ON d."统计区间" = vs."统计区间"
   AND d."就诊ID" = vs."就诊ID"
WHERE d."死亡标识" = 1
ORDER BY d."统计区间", d."就诊ID";
