-- =============================================================================
-- 探查：并发症统计为 0 的原因 — 登记覆盖率 + sam_reg_op 字段分布（与主统计同时间窗）
-- 与《手麻_1至3月_并发症例数与择期例数_Presto.sql》中 params.stat_year 保持一致后执行
-- =============================================================================

WITH params AS (
    SELECT 2026 AS stat_year
),
win_apply AS (
    SELECT DISTINCT a.id AS apply_id
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
        ON a.id = ar.sam_apply_id AND ar.isdeleted = '0'
    WHERE a.isdeleted = '0'
      AND nullif(trim(ar.in_oproom_date), '') IS NOT NULL
      AND length(trim(ar.in_oproom_date)) >= 10
      AND substr(trim(ar.in_oproom_date), 1, 4) = CAST((SELECT stat_year FROM params) AS VARCHAR)
      AND CAST(substr(trim(ar.in_oproom_date), 6, 2) AS INTEGER) BETWEEN 1 AND 3
),
reg_cov AS (
    SELECT
        count(*) AS apply_in_window,
        count(reg.id) AS apply_with_sam_reg,
        count(*) - count(reg.id) AS apply_without_sam_reg
    FROM win_apply w
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg
        ON reg.id = w.apply_id AND reg.isdeleted = '0'
),
op_in_window AS (
    SELECT o.*
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_reg_op o
    INNER JOIN win_apply w ON o.sam_reg_id = w.apply_id
    WHERE o.isdeleted = '0'
)
SELECT
    (SELECT apply_in_window FROM reg_cov) AS "时间窗内申请数",
    (SELECT apply_with_sam_reg FROM reg_cov) AS "其中有sam_reg的申请数",
    (SELECT apply_without_sam_reg FROM reg_cov) AS "无sam_reg的申请数_旧SQL用reg.id关联并发症会全0",
    (SELECT count(*) FROM op_in_window) AS "时间窗内sam_reg_op行数",
    (SELECT count_if(nullif(trim(main_o_and_o_ssbfznr), '') IS NOT NULL) FROM op_in_window) AS "并发症代码非空行数",
    (SELECT count_if(
            lower(trim(coalesce(main_o_and_o_ssbfz, ''))) IN ('y', '1', 'yes', '是', '有')
         OR nullif(trim(main_o_and_o_ssbfznr), '') IS NOT NULL
     ) FROM op_in_window) AS "按主SQL阳性规则命中行数"
;

-- ========== 若需看 main_o_and_o_ssbfz 原始取值 Top： ==========
-- SELECT trim(coalesce(main_o_and_o_ssbfz, '')) AS v, count(*) AS c
-- FROM op_in_window GROUP BY 1 ORDER BY c DESC LIMIT 30;
-- （把 op_in_window 展开为与上面相同的 JOIN 条件即可单段执行）
