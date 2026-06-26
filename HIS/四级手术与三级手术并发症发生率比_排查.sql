-- 四级/三级手术并发症分子 — 完整排查（Presto / datacenter_db / HID0101）
-- 与主指标 SQL 口径一致，可单独整段执行

-- =============================================================================
-- 1) 病案字段分布：Flag / Desc
-- =============================================================================
SELECT trim(cast(fp."MR_FP_OPSComplicationFlag" AS varchar)) AS flag取值, count(*) AS 条数
FROM datacenter_db."MR_FP" fp
WHERE fp."MR_FP_MedOrgCode" = 'HID0101'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20;

SELECT
    CASE
        WHEN nullif(trim(cast(fp."MR_FP_OPSComplicationDesc" AS varchar)), '') IS NULL THEN '[空]'
        ELSE '[有值]'
    END AS desc取值,
    count(*) AS 条数
FROM datacenter_db."MR_FP" fp
WHERE fp."MR_FP_MedOrgCode" = 'HID0101'
GROUP BY 1;

-- =============================================================================
-- 2) 三源拆分 + 合并分子（两区间 × 三/四级，与主 SQL 同口径）
-- =============================================================================
WITH
complication_icd_exact AS (
    SELECT icd_code
    FROM (
        VALUES
            ('I26'), ('I80.1'), ('I80.2'), ('I82.8'),
            ('A40'), ('A41'),
            ('T81.411'), ('B37.7'), ('B49.x00x019'),
            ('T81.0'), ('T81.3'),
            ('R96.0'), ('R96.1'), ('I46.1'), ('J95.800x004'),
            ('T81.4'), ('T81.5'), ('T81.6'),
            ('T88.2'), ('T88.3'), ('T88.4'), ('T88.5'),
            ('J95.1'), ('J95.2'), ('J95.3'), ('J95.4'), ('J95.8'), ('J95.9'),
            ('J98.4'),
            ('T81.2'), ('N17'), ('N99.0'), ('K91'),
            ('I97.0'), ('I97.1'), ('I97.8'), ('I97.9'),
            ('G97.0'), ('G97.1'), ('G97.2'), ('G97.8'), ('G97.9'),
            ('H59.0'), ('H59.8'), ('H59.9'), ('H95.0'), ('H95.1'), ('H95.8'), ('H95.9'),
            ('M96'), ('N98'), ('K11.4'),
            ('T86'), ('T87.0'), ('T87.1'), ('T87.2'), ('T87.3'), ('T87.4'), ('T87.5'), ('T87.6'),
            ('T81.1'), ('T81.7'), ('T81.8'), ('T81.9')
    ) t(icd_code)
),

visit_complication AS (
    SELECT DISTINCT
        diag."Visit_Diag_VisitID" AS visit_id
    FROM datacenter_db."Visit_Diag" diag
    WHERE diag."Visit_Diag_MedOrgCode" = 'HID0101'
      AND coalesce(cast(diag."Visit_Diag_IsDeleted" AS varchar), '0') = '0'
      AND (
            trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) IN (
                SELECT icd_code FROM complication_icd_exact
            )
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T88%'
          )
),

surgery_base AS (
    SELECT
        CASE
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
             AND ops."MR_FPOPS_OPSDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2026-01-01'
             AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        ops."MR_FPOPS_MROPSID" AS mropsid,
        ops."MR_FPOPS_VisitID" AS visit_id,
        trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) AS ops_level,
        trim(coalesce(cast(fp."MR_FP_OPSComplicationFlag" AS varchar), '')) AS compl_flag,
        trim(coalesce(cast(fp."MR_FP_OPSComplicationDesc" AS varchar), '')) AS compl_desc,
        CASE WHEN vc.visit_id IS NOT NULL THEN 1 ELSE 0 END AS icd_hit
    FROM datacenter_db."MR_FPOPS" ops
    INNER JOIN datacenter_db."MR_FP" fp
        ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
    LEFT JOIN visit_complication vc
        ON ops."MR_FPOPS_VisitID" = vc.visit_id
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND fp."MR_FP_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      AND ops."MR_FPOPS_OPSDtTm" IS NOT NULL
      AND trim(cast(ops."MR_FPOPS_OPSDtTm" AS varchar)) <> ''
      AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
      AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
      AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
)

SELECT
    "统计区间",
    ops_level AS "手术级别",
    count(DISTINCT mropsid) AS "手术总数_分母",
    count(DISTINCT CASE
        WHEN compl_flag IN ('1', '是', '√', 'Y', 'y') THEN mropsid
    END) AS "分子_标志阳性",
    count(DISTINCT CASE
        WHEN compl_desc <> '' THEN mropsid
    END) AS "分子_描述非空",
    count(DISTINCT CASE
        WHEN icd_hit = 1 THEN mropsid
    END) AS "分子_ICD命中",
    count(DISTINCT CASE
        WHEN compl_flag IN ('1', '是', '√', 'Y', 'y')
          OR compl_desc <> ''
          OR icd_hit = 1
        THEN mropsid
    END) AS "分子_合并",
    count(DISTINCT CASE
        WHEN compl_desc <> '' AND icd_hit = 1 THEN mropsid
    END) AS "分子_Desc与ICD交集",
    count(DISTINCT CASE
        WHEN compl_desc <> '' AND icd_hit = 0 THEN mropsid
    END) AS "分子_仅Desc",
    count(DISTINCT CASE
        WHEN compl_desc = '' AND icd_hit = 1 THEN mropsid
    END) AS "分子_仅ICD"
FROM surgery_base
WHERE "统计区间" IS NOT NULL
GROUP BY "统计区间", ops_level
ORDER BY "统计区间", ops_level;

-- =============================================================================
-- 3) 就诊维度：有并发症的就诊数（对比手术行分子是否被放大）
-- =============================================================================
WITH
complication_icd_exact AS (
    SELECT icd_code
    FROM (
        VALUES
            ('I26'), ('I80.1'), ('I80.2'), ('I82.8'),
            ('A40'), ('A41'),
            ('T81.411'), ('B37.7'), ('B49.x00x019'),
            ('T81.0'), ('T81.3'),
            ('R96.0'), ('R96.1'), ('I46.1'), ('J95.800x004'),
            ('T81.4'), ('T81.5'), ('T81.6'),
            ('T88.2'), ('T88.3'), ('T88.4'), ('T88.5'),
            ('J95.1'), ('J95.2'), ('J95.3'), ('J95.4'), ('J95.8'), ('J95.9'),
            ('J98.4'),
            ('T81.2'), ('N17'), ('N99.0'), ('K91'),
            ('I97.0'), ('I97.1'), ('I97.8'), ('I97.9'),
            ('G97.0'), ('G97.1'), ('G97.2'), ('G97.8'), ('G97.9'),
            ('H59.0'), ('H59.8'), ('H59.9'), ('H95.0'), ('H95.1'), ('H95.8'), ('H95.9'),
            ('M96'), ('N98'), ('K11.4'),
            ('T86'), ('T87.0'), ('T87.1'), ('T87.2'), ('T87.3'), ('T87.4'), ('T87.5'), ('T87.6'),
            ('T81.1'), ('T81.7'), ('T81.8'), ('T81.9')
    ) t(icd_code)
),

visit_complication AS (
    SELECT DISTINCT
        diag."Visit_Diag_VisitID" AS visit_id
    FROM datacenter_db."Visit_Diag" diag
    WHERE diag."Visit_Diag_MedOrgCode" = 'HID0101'
      AND coalesce(cast(diag."Visit_Diag_IsDeleted" AS varchar), '0') = '0'
      AND (
            trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) IN (
                SELECT icd_code FROM complication_icd_exact
            )
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T88%'
          )
),

surgery_base AS (
    SELECT
        CASE
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
             AND ops."MR_FPOPS_OPSDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2026-01-01'
             AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        ops."MR_FPOPS_VisitID" AS visit_id,
        trim(coalesce(cast(fp."MR_FP_OPSComplicationDesc" AS varchar), '')) AS compl_desc,
        CASE WHEN vc.visit_id IS NOT NULL THEN 1 ELSE 0 END AS icd_hit
    FROM datacenter_db."MR_FPOPS" ops
    INNER JOIN datacenter_db."MR_FP" fp
        ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
    LEFT JOIN visit_complication vc
        ON ops."MR_FPOPS_VisitID" = vc.visit_id
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND fp."MR_FP_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
      AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
      AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
)

SELECT
    "统计区间",
    count(DISTINCT visit_id) AS "三四级手术涉及就诊数",
    count(DISTINCT CASE WHEN compl_desc <> '' THEN visit_id END) AS "就诊_Desc非空",
    count(DISTINCT CASE WHEN icd_hit = 1 THEN visit_id END) AS "就诊_ICD命中",
    count(DISTINCT CASE
        WHEN compl_desc <> '' OR icd_hit = 1 THEN visit_id
    END) AS "就诊_合并"
FROM surgery_base
WHERE "统计区间" IS NOT NULL
GROUP BY "统计区间"
ORDER BY "统计区间";

-- =============================================================================
-- 4) 口径对比：Exp按手术序号 vs ICD就诊级（验证800~900/年）
-- =============================================================================
WITH
complication_icd_exact AS (
    SELECT icd_code
    FROM (
        VALUES
            ('I26'), ('I80.1'), ('I80.2'), ('I82.8'),
            ('A40'), ('A41'),
            ('T81.411'), ('B37.7'), ('B49.x00x019'),
            ('T81.0'), ('T81.3'),
            ('R96.0'), ('R96.1'), ('I46.1'), ('J95.800x004'),
            ('T81.4'), ('T81.5'), ('T81.6'),
            ('T88.2'), ('T88.3'), ('T88.4'), ('T88.5'),
            ('J95.1'), ('J95.2'), ('J95.3'), ('J95.4'), ('J95.8'), ('J95.9'),
            ('J98.4'),
            ('T81.2'), ('N17'), ('N99.0'), ('K91'),
            ('I97.0'), ('I97.1'), ('I97.8'), ('I97.9'),
            ('G97.0'), ('G97.1'), ('G97.2'), ('G97.8'), ('G97.9'),
            ('H59.0'), ('H59.8'), ('H59.9'), ('H95.0'), ('H95.1'), ('H95.8'), ('H95.9'),
            ('M96'), ('N98'), ('K11.4'),
            ('T86'), ('T87.0'), ('T87.1'), ('T87.2'), ('T87.3'), ('T87.4'), ('T87.5'), ('T87.6'),
            ('T81.1'), ('T81.7'), ('T81.8'), ('T81.9')
    ) t(icd_code)
),

visit_complication AS (
    SELECT DISTINCT diag."Visit_Diag_VisitID" AS visit_id
    FROM datacenter_db."Visit_Diag" diag
    WHERE diag."Visit_Diag_MedOrgCode" = 'HID0101'
      AND coalesce(cast(diag."Visit_Diag_IsDeleted" AS varchar), '0') = '0'
      AND (
            trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) IN (SELECT icd_code FROM complication_icd_exact)
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T88%'
          )
),

surgery_base AS (
    SELECT
        CASE
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2025-07-01' AND ops."MR_FPOPS_OPSDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN ops."MR_FPOPS_OPSDtTm" >= '2026-01-01' AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        ops."MR_FPOPS_MROPSID" AS mropsid,
        ops."MR_FPOPS_VisitID" AS visit_id,
        trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) AS ops_level,
        CASE trim(coalesce(cast(ops."MR_FPOPS_OPSSeqNo" AS varchar), '1'))
            WHEN '1' THEN trim(coalesce(cast(fp."MR_FP_Exp_OPSComplicationFlag1" AS varchar), ''))
            WHEN '2' THEN trim(coalesce(cast(fp."MR_FP_Exp_OPSComplicationFlag2" AS varchar), ''))
            WHEN '3' THEN trim(coalesce(cast(fp."MR_FP_Exp_OPSComplicationFlag3" AS varchar), ''))
            WHEN '4' THEN trim(coalesce(cast(fp."MR_FP_Exp_OPSComplicationFlag4" AS varchar), ''))
            ELSE trim(coalesce(cast(fp."MR_FP_Exp_OPSComplicationFlag1" AS varchar), ''))
        END AS exp_flag,
        CASE WHEN vc.visit_id IS NOT NULL THEN 1 ELSE 0 END AS icd_hit
    FROM datacenter_db."MR_FPOPS" ops
    INNER JOIN datacenter_db."MR_FP" fp ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
    LEFT JOIN visit_complication vc ON ops."MR_FPOPS_VisitID" = vc.visit_id
    WHERE ops."MR_FPOPS_MedOrgCode" = 'HID0101'
      AND fp."MR_FP_MedOrgCode" = 'HID0101'
      AND coalesce(cast(ops."MR_FPOPS_IsDeleted" AS varchar), '0') = '0'
      AND coalesce(cast(fp."MR_FP_IsDeleted" AS varchar), '0') = '0'
      AND trim(cast(ops."MR_FPOPS_OPSLevelCode" AS varchar)) IN ('3', '4')
      AND ops."MR_FPOPS_OPSDtTm" >= '2025-07-01'
      AND ops."MR_FPOPS_OPSDtTm" < '2026-07-01'
)

SELECT
    "统计区间",
    count(DISTINCT mropsid) AS "三四级手术总例数",
    count(DISTINCT CASE WHEN exp_flag IN ('1','√','是','Y','y') THEN mropsid END) AS "分子_Exp按手术序号",
    count(DISTINCT CASE WHEN icd_hit = 1 THEN mropsid END) AS "分子_ICD就诊级",
    count(DISTINCT CASE WHEN exp_flag IN ('1','√','是','Y','y') THEN visit_id END) AS "Exp阳性就诊数",
    count(DISTINCT CASE WHEN icd_hit = 1 THEN visit_id END) AS "ICD阳性就诊数",
    round(
        cast(count(DISTINCT CASE WHEN icd_hit = 1 THEN mropsid END) AS double)
        / nullif(cast(count(DISTINCT CASE WHEN exp_flag IN ('1','√','是','Y','y') THEN mropsid END) AS double), 0),
        2
    ) AS "ICD对Exp放大倍数"
FROM surgery_base
WHERE "统计区间" IS NOT NULL
GROUP BY "统计区间"
ORDER BY "统计区间";
