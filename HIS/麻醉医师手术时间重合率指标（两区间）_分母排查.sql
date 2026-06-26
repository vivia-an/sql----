-- 麻醉医师手术时间重合率 — 麻醉记录单偏少排查（Presto / HID0101）
-- 与主 SQL 同区间：2025-07~12 / 2026-01~06
-- 目的：量化各过滤条件剔除了多少「住院手术/麻醉记录」

-- =============================================================================
-- Step0 主 SQL 当前分母（对照基准）
-- =============================================================================
WITH base_current AS (
    SELECT
        CASE
            WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
             AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2026-01-01'
             AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        ops."OPS_EventMainRecord_OPSEventID" AS event_id
    FROM datacenter_db."OPS_EventMainRecord" ops
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON ops."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
    WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
      AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
      AND coalesce(ops."OPS_EventMainRecord_IsDeleted", '0') = '0'
      AND coalesce(ip."Visit_IPReg_IsDeleted", '0') = '0'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" IS NOT NULL
      AND trim(ops."OPS_EventMainRecord_NarcosisBeginDtTm") <> ''
      AND ops."OPS_EventMainRecord_NarcosisEndDtTm" IS NOT NULL
      AND trim(ops."OPS_EventMainRecord_NarcosisEndDtTm") <> ''
      AND ops."OPS_EventMainRecord_NarcosisDoctCode" IS NOT NULL
      AND trim(ops."OPS_EventMainRecord_NarcosisDoctCode") <> ''
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm"
          < ops."OPS_EventMainRecord_NarcosisEndDtTm"
)
SELECT "统计区间", count(DISTINCT event_id) AS "当前主SQL分母"
FROM base_current
WHERE "统计区间" IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- =============================================================================
-- Step1 住院手术事件总量（仅 HID0101 + 住院登记 + 麻醉开始落区间）
-- =============================================================================
SELECT
    CASE
        WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-01-01'
            THEN '2025-07-01~2025-12-31'
        WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2026-01-01'
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
            THEN '2026-01-01~2026-06-30'
    END AS "统计区间",
    count(DISTINCT ops."OPS_EventMainRecord_OPSEventID") AS "有麻醉开始时间"
FROM datacenter_db."OPS_EventMainRecord" ops
INNER JOIN datacenter_db."Visit_IPReg" ip
    ON ops."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
  AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
  AND coalesce(ops."OPS_EventMainRecord_IsDeleted", '0') = '0'
  AND coalesce(ip."Visit_IPReg_IsDeleted", '0') = '0'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" IS NOT NULL
  AND trim(ops."OPS_EventMainRecord_NarcosisBeginDtTm") <> ''
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
GROUP BY 1
ORDER BY 1;

-- =============================================================================
-- Step2 逐步加条件：看每一步少多少
-- =============================================================================
SELECT
    CASE
        WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-01-01'
            THEN '2025-07-01~2025-12-31'
        WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2026-01-01'
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
            THEN '2026-01-01~2026-06-30'
    END AS "统计区间",
    count(DISTINCT ops."OPS_EventMainRecord_OPSEventID") AS "全量住院事件",
    count(DISTINCT CASE
        WHEN ops."OPS_EventMainRecord_NarcosisEndDtTm" IS NOT NULL
         AND trim(ops."OPS_EventMainRecord_NarcosisEndDtTm") <> ''
        THEN ops."OPS_EventMainRecord_OPSEventID"
    END) AS "+有麻醉结束",
    count(DISTINCT CASE
        WHEN ops."OPS_EventMainRecord_NarcosisEndDtTm" IS NOT NULL
         AND trim(ops."OPS_EventMainRecord_NarcosisEndDtTm") <> ''
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm"
             < ops."OPS_EventMainRecord_NarcosisEndDtTm"
        THEN ops."OPS_EventMainRecord_OPSEventID"
    END) AS "+起止合法",
    count(DISTINCT CASE
        WHEN ops."OPS_EventMainRecord_NarcosisEndDtTm" IS NOT NULL
         AND trim(ops."OPS_EventMainRecord_NarcosisEndDtTm") <> ''
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm"
             < ops."OPS_EventMainRecord_NarcosisEndDtTm"
         AND trim(coalesce(ops."OPS_EventMainRecord_NarcosisDoctCode", '')) <> ''
        THEN ops."OPS_EventMainRecord_OPSEventID"
    END) AS "+第一麻醉医师代码",
    count(DISTINCT CASE
        WHEN ops."OPS_EventMainRecord_NarcosisEndDtTm" IS NOT NULL
         AND trim(ops."OPS_EventMainRecord_NarcosisEndDtTm") <> ''
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm"
             < ops."OPS_EventMainRecord_NarcosisEndDtTm"
         AND (
                trim(coalesce(ops."OPS_EventMainRecord_NarcosisDoctCode", '')) <> ''
             OR trim(coalesce(ops."OPS_EventMainRecord_SecondNarcosisDoctCode", '')) <> ''
             OR trim(coalesce(ops."OPS_EventMainRecord_ThirdNarcosisDoctCode", '')) <> ''
             )
        THEN ops."OPS_EventMainRecord_OPSEventID"
    END) AS "+含二三麻醉医师代码"
FROM datacenter_db."OPS_EventMainRecord" ops
INNER JOIN datacenter_db."Visit_IPReg" ip
    ON ops."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
  AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
  AND coalesce(ops."OPS_EventMainRecord_IsDeleted", '0') = '0'
  AND coalesce(ip."Visit_IPReg_IsDeleted", '0') = '0'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" IS NOT NULL
  AND trim(ops."OPS_EventMainRecord_NarcosisBeginDtTm") <> ''
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
GROUP BY 1
ORDER BY 1;

-- =============================================================================
-- Step3 第一麻醉代码空、但第二/三麻醉代码有值（当前被整例剔除）
-- =============================================================================
SELECT
    CASE
        WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-01-01'
            THEN '2025-07-01~2025-12-31'
        WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2026-01-01'
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
            THEN '2026-01-01~2026-06-30'
    END AS "统计区间",
    count(DISTINCT ops."OPS_EventMainRecord_OPSEventID") AS "仅二三麻醉有代码"
FROM datacenter_db."OPS_EventMainRecord" ops
INNER JOIN datacenter_db."Visit_IPReg" ip
    ON ops."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
  AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
  AND coalesce(ops."OPS_EventMainRecord_IsDeleted", '0') = '0'
  AND coalesce(ip."Visit_IPReg_IsDeleted", '0') = '0'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" IS NOT NULL
  AND trim(ops."OPS_EventMainRecord_NarcosisBeginDtTm") <> ''
  AND ops."OPS_EventMainRecord_NarcosisEndDtTm" IS NOT NULL
  AND trim(ops."OPS_EventMainRecord_NarcosisEndDtTm") <> ''
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm"
      < ops."OPS_EventMainRecord_NarcosisEndDtTm"
  AND trim(coalesce(ops."OPS_EventMainRecord_NarcosisDoctCode", '')) = ''
  AND (
        trim(coalesce(ops."OPS_EventMainRecord_SecondNarcosisDoctCode", '')) <> ''
     OR trim(coalesce(ops."OPS_EventMainRecord_ThirdNarcosisDoctCode", '')) <> ''
      )
GROUP BY 1
ORDER BY 1;

-- =============================================================================
-- Step4 无 Visit_IPReg 关联（INNER JOIN 整例丢失）
-- =============================================================================
SELECT
    CASE
        WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-01-01'
            THEN '2025-07-01~2025-12-31'
        WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2026-01-01'
         AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
            THEN '2026-01-01~2026-06-30'
    END AS "统计区间",
    count(DISTINCT ops."OPS_EventMainRecord_OPSEventID") AS "无住院登记关联"
FROM datacenter_db."OPS_EventMainRecord" ops
LEFT JOIN datacenter_db."Visit_IPReg" ip
    ON ops."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
   AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
   AND coalesce(ip."Visit_IPReg_IsDeleted", '0') = '0'
WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
  AND coalesce(ops."OPS_EventMainRecord_IsDeleted", '0') = '0'
  AND ip."Visit_IPReg_VisitID" IS NULL
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
  AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" IS NOT NULL
  AND trim(ops."OPS_EventMainRecord_NarcosisBeginDtTm") <> ''
GROUP BY 1
ORDER BY 1;

-- =============================================================================
-- Step5 麻醉起止缺失（有手术起止、无麻醉起止）
-- =============================================================================
SELECT
    CASE
        WHEN ops."OPS_EventMainRecord_OPSBeginDtTm" >= '2025-07-01'
         AND ops."OPS_EventMainRecord_OPSBeginDtTm" < '2026-01-01'
            THEN '2025-07-01~2025-12-31'
        WHEN ops."OPS_EventMainRecord_OPSBeginDtTm" >= '2026-01-01'
         AND ops."OPS_EventMainRecord_OPSBeginDtTm" < '2026-07-01'
            THEN '2026-01-01~2026-06-30'
    END AS "统计区间",
    count(DISTINCT ops."OPS_EventMainRecord_OPSEventID") AS "有手术无麻醉时间"
FROM datacenter_db."OPS_EventMainRecord" ops
INNER JOIN datacenter_db."Visit_IPReg" ip
    ON ops."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
  AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
  AND coalesce(ops."OPS_EventMainRecord_IsDeleted", '0') = '0'
  AND coalesce(ip."Visit_IPReg_IsDeleted", '0') = '0'
  AND ops."OPS_EventMainRecord_OPSBeginDtTm" >= '2025-07-01'
  AND ops."OPS_EventMainRecord_OPSBeginDtTm" < '2026-07-01'
  AND ops."OPS_EventMainRecord_OPSBeginDtTm" IS NOT NULL
  AND trim(ops."OPS_EventMainRecord_OPSBeginDtTm") <> ''
  AND (
        ops."OPS_EventMainRecord_NarcosisBeginDtTm" IS NULL
     OR trim(ops."OPS_EventMainRecord_NarcosisBeginDtTm") = ''
     OR ops."OPS_EventMainRecord_NarcosisEndDtTm" IS NULL
     OR trim(ops."OPS_EventMainRecord_NarcosisEndDtTm") = ''
      )
GROUP BY 1
ORDER BY 1;
