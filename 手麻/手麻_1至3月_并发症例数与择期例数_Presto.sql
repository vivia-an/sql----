-- =============================================================================
-- 【标准需求】指定年度 1、2、3 月：手术并发症例数 + 择期手术例数（按月三行，缺月补 0）
-- 手麻：指定年度 1～3 月「手术并发症例数」与「择期手术例数」（按月）
-- =============================================================================
-- 【血缘（与仓库内手麻 SQL 一致）】
--   sam_apply a              手术申请（择期口径：coalesce(reg.is_emergency, a.is_emergency) IS DISTINCT FROM '1'）
--   sam_reg reg              登记（reg.id = a.id）
--   sam_anar ar              麻醉记录（ar.sam_apply_id = a.id）→ 入室时间 in_oproom_date 作统计月
--   sam_reg_op o             实际手术行（o.sam_reg_id = reg.id）
--   并发症（Hive 无 sam_reg_opcmpl 同步时用本表字段）← 手麻表结构.md I.1.23
--     main_o_and_o_ssbfz     有无手术并发症
--     main_o_and_o_ssbfznr   手术并发症-内容（代码）
--   （Oracle 侧另有子表 SAM_REG_OPCMPL，Hive 常不存在，故不用）
-- 【口径说明】
--   · 择期手术例数：当月至少有一条有效入室记录，且急诊标志不为 '1'（含 NULL 视为择期，与报表明细 CASE 一致）
--   · 并发症例数：sam_reg_op.sam_reg_id = a.id（勿用 reg.id：LEFT JOIN reg 为空时原写法会导致并发症恒为 0）
--     且（main_o_and_o_ssbfz 阳性 或 main_o_and_o_ssbfznr 非空）
--   · 仍为 0 时跑《手麻_并发症字段_探查_Presto.sql》看字段取值与登记覆盖率
--   · 若需「仅择期中的并发症」见列 elective_with_complication_cnt
-- 【时间】默认 substr(in_oproom_date,1,10) 落月；若入室时间为空可改用 scheduled_date（见文末注释）
-- 【环境】catalog/schema 与《手麻报表明细_Oracle转Presto.sql》一致：hid0101_orcl_operaanesthisa_emrhis
-- =============================================================================

WITH params AS (
    SELECT 2026 AS stat_year   -- 修改此处：统计哪一年的 1～3 月
),
month_list AS (
    SELECT m AS month_no
    FROM UNNEST(ARRAY[1, 2, 3]) AS t(m)
),
-- 申请级：入室日期、是否择期、是否有并发症（仅 sam_reg_op，不用未同步的 opcmpl 子表）
base AS (
    SELECT
        a.id AS apply_id,
        substr(trim(ar.in_oproom_date), 1, 10) AS in_oproom_d,
        coalesce(reg.is_emergency, a.is_emergency) AS is_emergency,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM hid0101_orcl_operaanesthisa_emrhis.sam_reg_op o
                WHERE o.sam_reg_id = a.id
                  AND o.isdeleted = '0'
                  AND (
                        lower(trim(coalesce(o.main_o_and_o_ssbfz, ''))) IN ('y', '1', 'yes', '是', '有')
                     OR (nullif(trim(o.main_o_and_o_ssbfznr), '') IS NOT NULL)
                  )
            ) THEN 1
            ELSE 0
        END AS has_complication
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
        ON a.id = ar.sam_apply_id
       AND ar.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg
        ON reg.id = a.id
       AND reg.isdeleted = '0'
    WHERE a.isdeleted = '0'
      AND nullif(trim(ar.in_oproom_date), '') IS NOT NULL
      AND length(trim(ar.in_oproom_date)) >= 10
      AND substr(trim(ar.in_oproom_date), 1, 4) = CAST((SELECT stat_year FROM params) AS VARCHAR)
      AND CAST(substr(trim(ar.in_oproom_date), 6, 2) AS INTEGER) BETWEEN 1 AND 3
),
agg AS (
    SELECT
        substr(in_oproom_d, 1, 7) AS year_month,
        CAST(substr(in_oproom_d, 6, 2) AS INTEGER) AS month_no,
        count(DISTINCT CASE WHEN is_emergency IS DISTINCT FROM '1' THEN apply_id END) AS elective_surgery_cnt,
        count(DISTINCT CASE WHEN has_complication = 1 THEN apply_id END) AS complication_case_cnt,
        count(DISTINCT CASE WHEN is_emergency IS DISTINCT FROM '1' AND has_complication = 1 THEN apply_id END) AS elective_with_complication_cnt
    FROM base
    GROUP BY 1, 2
)
SELECT
    ml.month_no AS "月份",
    concat(CAST((SELECT stat_year FROM params) AS VARCHAR), '-', lpad(CAST(ml.month_no AS VARCHAR), 2, '0')) AS "年月",
    coalesce(a.year_month, concat(CAST((SELECT stat_year FROM params) AS VARCHAR), '-', lpad(CAST(ml.month_no AS VARCHAR), 2, '0'))) AS ym,
    coalesce(a.complication_case_cnt, 0) AS "手术并发症例数",
    coalesce(a.elective_surgery_cnt, 0) AS "择期手术例数",
    coalesce(a.elective_with_complication_cnt, 0) AS "择期且并发症例数"
FROM month_list ml
LEFT JOIN agg a
    ON a.month_no = ml.month_no
ORDER BY ml.month_no;

-- ========== 若列名报错：SHOW COLUMNS FROM hid0101_orcl_operaanesthisa_emrhis.sam_reg_op LIKE '%ssbfz%'; 可能需双引号大写 ==========
-- ========== 无入室时间时改用排程月（与报表明细宽口径 B 接近）：==========
-- AND substr(trim(a.scheduled_date), 1, 4) = CAST((SELECT stat_year FROM params) AS VARCHAR)
-- AND CAST(substr(trim(a.scheduled_date), 6, 2) AS INTEGER) BETWEEN 1 AND 3
-- 并将 base 中 in_oproom_d 改为 substr(trim(a.scheduled_date),1,10)
