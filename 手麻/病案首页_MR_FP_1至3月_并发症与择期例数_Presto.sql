-- =============================================================================
-- 病案首页（DataCenter）：指定年度 1～3 月「手术并发症例数」与「择期手术例数」（按月）
-- =============================================================================
-- 【血缘】datacenter_db.MR_FP（出院时间、扩展区择期/并发症标识）↔ MR_FPOPS（手术行）
-- 【对齐 his基本表结构 / datacenter】MR_FP 扩展字段：MR_FP_Exp_ElectiveOPSFlag1～4、
--        MR_FP_Exp_OPSComplicationFlag1～4（见 Datacenter/datacenter 病案首页扩展段）
-- 【时间】默认按病案出院时间 MR_FP_OutHospDtTm 落月（对齐你提供的 MROPS_FOutDate 出院口径）；
--        若需按手术时间 MR_FPOPS_OPSDtTm，见文末注释。
-- 【择期】按手术序号 MR_FPOPS_OPSSeqNo 对应扩展区 1～4 档的「择期手术标识」；
--        取值含 '1'、'√' 视为择期（请按现场字典收紧）。
-- 【并发症】同序号档「手术并发症标识」任一为阳性则该手术行计并发症。
-- 【差异】与手麻库 sam_* 口径可能不一致；手麻侧请用《手麻_1至3月_并发症例数与择期例数_Presto.sql》。
-- =============================================================================

WITH params AS (
    SELECT 2026 AS stat_year
),
month_list AS (
    SELECT m AS month_no FROM UNNEST(ARRAY[1, 2, 3]) AS t(m)
),
ops AS (
    SELECT
        o."MR_FPOPS_MROPSID" AS mrops_id,
        o."MR_FPOPS_VisitID" AS visit_id,
        o."MR_FPOPS_OPSSeqNo" AS op_seq,
        fp."MR_FP_OutHospDtTm" AS out_dt,
        -- 序号 1～4 → 对应扩展列
        CASE trim(coalesce(o."MR_FPOPS_OPSSeqNo", '1'))
            WHEN '1' THEN trim(coalesce(fp."MR_FP_Exp_ElectiveOPSFlag1", ''))
            WHEN '2' THEN trim(coalesce(fp."MR_FP_Exp_ElectiveOPSFlag2", ''))
            WHEN '3' THEN trim(coalesce(fp."MR_FP_Exp_ElectiveOPSFlag3", ''))
            WHEN '4' THEN trim(coalesce(fp."MR_FP_Exp_ElectiveOPSFlag4", ''))
            ELSE trim(coalesce(fp."MR_FP_Exp_ElectiveOPSFlag1", ''))
        END AS elective_raw,
        CASE trim(coalesce(o."MR_FPOPS_OPSSeqNo", '1'))
            WHEN '1' THEN trim(coalesce(fp."MR_FP_Exp_OPSComplicationFlag1", ''))
            WHEN '2' THEN trim(coalesce(fp."MR_FP_Exp_OPSComplicationFlag2", ''))
            WHEN '3' THEN trim(coalesce(fp."MR_FP_Exp_OPSComplicationFlag3", ''))
            WHEN '4' THEN trim(coalesce(fp."MR_FP_Exp_OPSComplicationFlag4", ''))
            ELSE trim(coalesce(fp."MR_FP_Exp_OPSComplicationFlag1", ''))
        END AS compl_raw
    FROM datacenter_db."MR_FPOPS" o
    INNER JOIN datacenter_db."MR_FP" fp
        ON o."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
    WHERE o."MR_FPOPS_IsDeleted" = '0'
      AND fp."MR_FP_IsDeleted" = '0'
      AND fp."MR_FP_OutHospDtTm" IS NOT NULL
      AND substring(cast(fp."MR_FP_OutHospDtTm" AS varchar), 1, 4) = cast((SELECT stat_year FROM params) AS varchar)
      AND cast(substring(cast(fp."MR_FP_OutHospDtTm" AS varchar), 6, 2) AS integer) BETWEEN 1 AND 3
),
flagged AS (
    SELECT
        mrops_id,
        substring(cast(out_dt AS varchar), 1, 7) AS year_month,
        cast(substring(cast(out_dt AS varchar), 6, 2) AS integer) AS month_no,
        elective_raw IN ('1', '√', '是', 'Y', 'y') AS is_elective,
        compl_raw IN ('1', '√', '是', 'Y', 'y') AS has_complication
    FROM ops
),
agg AS (
    SELECT
        month_no,
        max(year_month) AS year_month,
        count(DISTINCT CASE WHEN has_complication THEN mrops_id END) AS complication_case_cnt,
        count(DISTINCT CASE WHEN is_elective THEN mrops_id END) AS elective_surgery_cnt,
        count(DISTINCT CASE WHEN is_elective AND has_complication THEN mrops_id END) AS elective_with_complication_cnt
    FROM flagged
    GROUP BY month_no
)
SELECT
    ml.month_no AS "月份",
    concat(
        cast((SELECT stat_year FROM params) AS varchar), '-',
        lpad(cast(ml.month_no AS varchar), 2, '0')
    ) AS "年月",
    coalesce(a.year_month, concat(
        cast((SELECT stat_year FROM params) AS varchar), '-',
        lpad(cast(ml.month_no AS varchar), 2, '0')
    )) AS ym,
    coalesce(a.complication_case_cnt, 0) AS "手术并发症例数_MR_FP扩展",
    coalesce(a.elective_surgery_cnt, 0) AS "择期手术例数_MR_FP扩展",
    coalesce(a.elective_with_complication_cnt, 0) AS "择期且并发症例数"
FROM month_list ml
LEFT JOIN agg a ON a.month_no = ml.month_no
ORDER BY ml.month_no;

-- ========== 按手术时间统计（与出院月二选一）==========
-- 将 ops 子查询中 fp."MR_FP_OutHospDtTm" 条件改为 o."MR_FPOPS_OPSDtTm"，并同步 substring 字段。
