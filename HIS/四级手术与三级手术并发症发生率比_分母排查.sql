-- 三四级手术并发症指标 — 分母虚高排查（Presto / HID0101）
-- 与主 SQL 同区间：2025-07~12 / 2026-01~06
-- 目的：定位 MR_FPOPS 分母为何远高于业务预期（如四级半年 12 万+）

-- =============================================================================
-- Step1 基础量：行数 vs 去重键（2025-07~2026-06 全窗）
-- =============================================================================
SELECT
    '2025-07~2026-06' AS "窗口",
    count(*) AS "MR_FPOPS行数",
    count(DISTINCT ops."MR_FPOPS_MROPSID") AS "distinct_MROPSID",
    count(DISTINCT ops."MR_FPOPS_VisitID") AS "distinct_VisitID",
    count(DISTINCT concat(
        cast(ops."MR_FPOPS_VisitID" AS varchar), '#',
        trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '1'))
    )) AS "distinct_VisitID_OPSSeqNo",
    count(DISTINCT concat(
        cast(ops."MR_FPOPS_VisitID" AS varchar), '#',
        trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '1')), '#',
        trim(coalesce(cast(ops."MR_FPOPS_OPSCode" AS varchar), ''))
    )) AS "distinct_Visit_Seq_OPSCode"
FROM datacenter_db."MR_FPOPS" ops
INNER JOIN datacenter_db."MR_FP" fp
    ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND fp."MR_FP_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
  AND ops."MR_FPOPS_OPSDtTm" IS NOT NULL
  AND trim(cast(ops."MR_FPOPS_OPSDtTm" AS varchar)) <> ''
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01';

-- =============================================================================
-- Step2 按级别：当前主 SQL 分母口径
-- =============================================================================
SELECT
    CASE
        WHEN ops."MR_FPOPS_OPSDtTm" >= '2025-07-01' AND ops."MR_FPOPS_OPSDtTm" < '2026-01-01'
            THEN '2025-07-01~2025-12-31'
        WHEN ops."MR_FPOPS_OPSDtTm" >= '2026-01-01' AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
            THEN '2026-01-01~2026-06-30'
    END AS "统计区间",
    trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) AS "级别",
    count(*) AS "行数",
    count(DISTINCT ops."MR_FPOPS_MROPSID") AS "分母_MROPSID",
    count(DISTINCT ops."MR_FPOPS_VisitID") AS "就诊数",
    count(DISTINCT concat(
        cast(ops."MR_FPOPS_VisitID" AS varchar), '#',
        trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '1'))
    )) AS "Visit_Seq去重"
FROM datacenter_db."MR_FPOPS" ops
INNER JOIN datacenter_db."MR_FP" fp
    ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND fp."MR_FP_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
GROUP BY 1, 2
ORDER BY 1, 2;

-- =============================================================================
-- Step3 MROPSID 是否真唯一（重复 = 数仓重复同步）
-- =============================================================================
SELECT
    count(*) AS "重复MROPSID组数",
    sum(cnt - 1) AS "多余行数"
FROM (
    SELECT ops."MR_FPOPS_MROPSID" AS mropsid, count(*) AS cnt
    FROM datacenter_db."MR_FPOPS" ops
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
      AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
      AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
    GROUP BY 1
    HAVING count(*) > 1
) t;

-- =============================================================================
-- Step4 同一就诊多行三四级手术（OPSSeqNo 分布）
-- =============================================================================
SELECT
    trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '[空]')) AS "手术序号",
    trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) AS "级别",
    count(*) AS "行数",
    count(DISTINCT ops."MR_FPOPS_MROPSID") AS "MROPSID数"
FROM datacenter_db."MR_FPOPS" ops
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
GROUP BY 1, 2
ORDER BY 1, 2;

-- =============================================================================
-- Step5 操作类型分布（是否把「操作」当「手术」计入）
-- =============================================================================
SELECT
    trim(coalesce(cast(ops."MR_FPOPS_OperateTypeDesc" AS varchar), '[空]')) AS "操作类型",
    trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) AS "级别",
    count(DISTINCT ops."MR_FPOPS_MROPSID") AS "MROPSID数"
FROM datacenter_db."MR_FPOPS" ops
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 30;

-- =============================================================================
-- Step6 MR_FP 一对多：是否因 JOIN 放大（distinct MROPSID 应不变）
-- =============================================================================
SELECT
    count(DISTINCT ops."MR_FPOPS_VisitID") AS "涉及就诊数",
    count(DISTINCT ops."MR_FPOPS_MROPSID") AS "MROPSID数",
    count(*) AS "JOIN后行数",
    round(cast(count(*) AS double) / nullif(count(DISTINCT ops."MR_FPOPS_MROPSID"), 0), 2) AS "行数/MROPSID"
FROM datacenter_db."MR_FPOPS" ops
INNER JOIN datacenter_db."MR_FP" fp
    ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
   AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01';

SELECT
    fp_cnt,
    count(*) AS "就诊数"
FROM (
    SELECT ops."MR_FPOPS_VisitID" AS vid, count(DISTINCT fp."MR_FP_MRID") AS fp_cnt
    FROM datacenter_db."MR_FPOPS" ops
    INNER JOIN datacenter_db."MR_FP" fp
        ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
       AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
      AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
      AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
    GROUP BY 1
) t
GROUP BY 1
ORDER BY 1;

-- =============================================================================
-- Step7 与 OPS_EventMainRecord 对照（手麻/HIS 其他指标常用 OPSEventID）
-- =============================================================================
SELECT
    'MR_FPOPS_MROPSID' AS "口径",
    trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) AS "级别",
    count(DISTINCT ops."MR_FPOPS_MROPSID") AS "例数"
FROM datacenter_db."MR_FPOPS" ops
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
GROUP BY 2
UNION ALL
SELECT
    'OPS_EventMainRecord_OPSEventID',
    trim(cast(evt."OPS_EventMainRecord_OPSLevelCode" AS varchar)),
    count(DISTINCT evt."OPS_EventMainRecord_OPSEventID")
FROM datacenter_db."OPS_EventMainRecord" evt
INNER JOIN datacenter_db."Visit_IPReg" ip
    ON evt."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
WHERE evt."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
  AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
  AND coalesce(cast(evt."OPS_EventMainRecord_IsDeleted" AS varchar), '0') = '0'
  AND coalesce(cast(ip."Visit_IPReg_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(evt."OPS_EventMainRecord_OPSLevelCode" AS varchar)) IN ('3', '4')
  AND evt."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
  AND evt."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
GROUP BY 2
ORDER BY 1, 2;

-- =============================================================================
-- Step8 仅 OPSSeqNo=1 时分母（病案首页「第一手术」口径试探）
-- =============================================================================
SELECT
    CASE
        WHEN ops."MR_FPOPS_OPSDtTm" >= '2025-07-01' AND ops."MR_FPOPS_OPSDtTm" < '2026-01-01'
            THEN '2025-07-01~2025-12-31'
        WHEN ops."MR_FPOPS_OPSDtTm" >= '2026-01-01' AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
            THEN '2026-01-01~2026-06-30'
    END AS "统计区间",
    trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) AS "级别",
    count(DISTINCT ops."MR_FPOPS_MROPSID") AS "全三四级_MROPSID",
    count(DISTINCT CASE
        WHEN trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '1')) = '1'
        THEN ops."MR_FPOPS_MROPSID"
    END) AS "仅Seq1_MROPSID"
FROM datacenter_db."MR_FPOPS" ops
INNER JOIN datacenter_db."MR_FP" fp
    ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
  AND fp."MR_FP_MedOrgCode" = 'HID0101'
  AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
  AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
  AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
  AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
  AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
GROUP BY 1, 2
ORDER BY 1, 2;
