-- 麻醉记录/手术事件 — 全放开一年量探测（单条 SQL，验是否接近 25 万）
-- 窗口A：2025-07-01 ~ 2026-06-30 | 窗口B：2025 自然年

SELECT
    "时间窗口",
    "口径",
    "数据源",
    "行数",
    "distinct_计数"
FROM (
    SELECT
        'A_2025-07~2026-06' AS "时间窗口",
        '01_全表无过滤' AS "口径",
        'OPS_EventMainRecord' AS "数据源",
        count(*) AS "行数",
        count(DISTINCT ops."OPS_EventMainRecord_OPSEventID") AS "distinct_计数"
    FROM datacenter_db."OPS_EventMainRecord" ops

    UNION ALL
    SELECT 'A_2025-07~2026-06', '02_仅麻醉开始落窗', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'

    UNION ALL
    SELECT 'A_2025-07~2026-06', '03_仅手术开始落窗', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_OPSBeginDtTm" >= '2025-07-01'
      AND ops."OPS_EventMainRecord_OPSBeginDtTm" < '2026-07-01'

    UNION ALL
    SELECT 'A_2025-07~2026-06', '04_HID0101+麻醉开始落窗', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'

    UNION ALL
    SELECT 'A_2025-07~2026-06', '05_HID0101+IsDeleted=0+麻醉开始', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
      AND coalesce(ops."OPS_EventMainRecord_IsDeleted", '0') = '0'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'

    UNION ALL
    SELECT 'A_2025-07~2026-06', '06_修正主SQL分母(起止合法+住院)', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
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

    UNION ALL
    SELECT 'A_2025-07~2026-06', '07_全放开+麻醉开始(无院区删除住院)', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_NarcosisBeginDtTm" IS NOT NULL
      AND trim(ops."OPS_EventMainRecord_NarcosisBeginDtTm") <> ''
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'

    UNION ALL
    SELECT 'A_2025-07~2026-06', '08_全放开+手术开始(无院区删除住院)', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_OPSBeginDtTm" IS NOT NULL
      AND trim(ops."OPS_EventMainRecord_OPSBeginDtTm") <> ''
      AND ops."OPS_EventMainRecord_OPSBeginDtTm" >= '2025-07-01'
      AND ops."OPS_EventMainRecord_OPSBeginDtTm" < '2026-07-01'

    UNION ALL
    SELECT 'B_2025自然年', '09_全放开+麻醉开始落2025', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-01-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-01-01'

    UNION ALL
    SELECT 'B_2025自然年', '10_全放开+手术开始落2025', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_OPSBeginDtTm" >= '2025-01-01'
      AND ops."OPS_EventMainRecord_OPSBeginDtTm" < '2026-01-01'

    UNION ALL
    SELECT 'B_2025自然年', '11_HID0101+麻醉开始2025', 'OPS_EventMainRecord',
        count(*), count(DISTINCT ops."OPS_EventMainRecord_OPSEventID")
    FROM datacenter_db."OPS_EventMainRecord" ops
    WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-01-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-01-01'

    UNION ALL
    SELECT 'A_2025-07~2026-06', '12_申请手术同窗口', 'Apply_OPS',
        count(*), count(DISTINCT a."Apply_OPS_ApplyOPSID")
    FROM datacenter_db."Apply_OPS" a
    WHERE a."Apply_OPS_MedOrgCode" = 'HID0101'
      AND coalesce(a."Apply_OPS_IsDeleted", '0') = '0'
      AND a."Apply_OPS_OPSDtTm" >= '2025-07-01'
      AND a."Apply_OPS_OPSDtTm" < '2026-07-01'

    UNION ALL
    SELECT 'A_2025-07~2026-06', '13_病案手术行同窗口', 'MR_FPOPS',
        count(*), count(DISTINCT o."MR_FPOPS_MROPSID")
    FROM datacenter_db."MR_FPOPS" o
    WHERE o."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND coalesce(o."MR_FPOPS_IsDeleted", '0') = '0'
      AND o."MR_FPOPS_OPSDtTm" >= '2025-07-01'
      AND o."MR_FPOPS_OPSDtTm" < '2026-07-01'
) t
ORDER BY "时间窗口", "口径";
