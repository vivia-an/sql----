-- =============================================================================
-- 住院患者非计划手术率（两区间 · 与 HIS 审定版同源）
-- =============================================================================
-- 公式：行非计划手术的住院患者人次数 / 同期住院患者总人次数 × 100%
-- ★ 请确认编辑器已加载本文件（开头应为 Visit_IPReg，勿用含 out_dt 的旧版）
-- 分母：Visit_IPReg 同期出院（VisitID 去重，MedOrgCode=HID0101）
-- 分子：Apply_OPS.PlanAgainOPSFlag = '非计划再次手术'（HIS 实测可用口径）
-- 手麻 sam_apply 桥接分子见：非计划再入院_分子明细_Presto.sql
-- 排查：非计划再入院_排查_Presto.sql
-- =============================================================================

WITH
interval_list AS (
    SELECT '2025-07-01~2025-12-31' AS stat_interval
    UNION ALL
    SELECT '2026-01-01~2026-06-30'
),
base_inpatients AS (
    SELECT
        CASE
            WHEN v."Visit_IPReg_OutHospDtTm" >= '2025-07-01' AND v."Visit_IPReg_OutHospDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN v."Visit_IPReg_OutHospDtTm" >= '2026-01-01' AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS stat_interval,
        v."Visit_IPReg_VisitID" AS visit_id
    FROM datacenter_db."Visit_IPReg" v
    WHERE v."Visit_IPReg_MedOrgCode" = 'HID0101'
      AND v."Visit_IPReg_OutHospDtTm" IS NOT NULL
      AND v."Visit_IPReg_OutHospDtTm" != ''
      AND v."Visit_IPReg_IsDeleted" = '0'
      AND v."Visit_IPReg_InHospDtTm" IS NOT NULL
      AND v."Visit_IPReg_InHospDtTm" != ''
      AND v."Visit_IPReg_OutHospDtTm" >= '2025-07-01'
      AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01'
),
unplanned_surgery_patients AS (
    SELECT DISTINCT
        CASE
            WHEN v."Visit_IPReg_OutHospDtTm" >= '2025-07-01' AND v."Visit_IPReg_OutHospDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN v."Visit_IPReg_OutHospDtTm" >= '2026-01-01' AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS stat_interval,
        v."Visit_IPReg_VisitID" AS visit_id
    FROM datacenter_db."Visit_IPReg" v
    INNER JOIN datacenter_db."Apply_OPS" p
        ON v."Visit_IPReg_VisitID" = p."Apply_OPS_VisitID"
    WHERE v."Visit_IPReg_MedOrgCode" = 'HID0101'
      AND p."Apply_OPS_MedOrgCode" = 'HID0101'
      AND v."Visit_IPReg_OutHospDtTm" IS NOT NULL
      AND v."Visit_IPReg_OutHospDtTm" != ''
      AND v."Visit_IPReg_IsDeleted" = '0'
      AND p."Apply_OPS_IsDeleted" = '0'
      AND v."Visit_IPReg_InHospDtTm" IS NOT NULL
      AND v."Visit_IPReg_InHospDtTm" != ''
      AND v."Visit_IPReg_OutHospDtTm" >= '2025-07-01'
      AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01'
      AND p."Apply_OPS_PlanAgainOPSFlag" = '非计划再次手术'
),
interval_stats AS (
    SELECT
        b.stat_interval,
        count(DISTINCT b.visit_id) AS denom_cnt,
        count(DISTINCT u.visit_id) AS numer_cnt
    FROM base_inpatients b
    LEFT JOIN unplanned_surgery_patients u
        ON b.stat_interval = u.stat_interval
       AND b.visit_id = u.visit_id
    WHERE b.stat_interval IS NOT NULL
    GROUP BY b.stat_interval
)
SELECT
    il.stat_interval AS "统计区间",
    coalesce(s.numer_cnt, 0) AS "分子_行非计划手术住院患者人次数",
    coalesce(s.denom_cnt, 0) AS "分母_同期出院住院患者总人次数",
    CASE
        WHEN coalesce(s.denom_cnt, 0) > 0 THEN round(cast(coalesce(s.numer_cnt, 0) AS double) / cast(s.denom_cnt AS double) * 100, 2)
        ELSE 0
    END AS "住院患者非计划手术率(%)"
FROM interval_list il
LEFT JOIN interval_stats s
    ON il.stat_interval = s.stat_interval
ORDER BY il.stat_interval;
