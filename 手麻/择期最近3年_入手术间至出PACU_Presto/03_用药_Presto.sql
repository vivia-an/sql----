-- =============================================================================
-- 文件：03_用药_Presto.sql
-- 源：手麻原始sql/用药(1).txt（Oracle，单段模板）
-- 引擎：Presto
-- 库：hid0101_orcl_operaanesthisa_emrhis
-- 形态：一张可直接执行的大表（无占位符）。原模板要传入 ${ipi}/${start}/${end}，本版改为
--   - 去掉 ipi 过滤 → 覆盖 cohort 内所有择期患者
--   - 用 cohort 与 01 对齐 + p_sched；用药事件与「入室~出PACU」区间重叠才输出
--   - 仅保留麻醉用药事件 (is_rec_enent='2' AND s_mzsjlb_dm='22')
--
-- 口径：与 01 —— cohort 完全一致；用药事件仅需与「入室~出PACU」时间段有重叠（ordered_date/end_date ∩ [in_oproom,rec_out]）
-- 行级：one row per 用药事件 (sam_anar_enent.id)，且事件时间与路径窗重叠
-- =============================================================================

WITH p_sched AS (
    SELECT
        '2023-05-14 00:00:00' AS dt_start,
        '2026-05-14 23:59:59' AS dt_end
),
-- ① cohort：与 01_手术信息查询报表 info 子查询 WHERE 完全一致
cohort AS (
    SELECT
        a.id                                                              AS apply_id,
        ar.id                                                             AS anar_id,
        coalesce(reg.ipi_registration_id, a.ipi_registration_id)          AS ipi_id,
        coalesce(reg.patient_name,        a.patient_name)                 AS patient_name,
        coalesce(reg.patient_dept_id,     a.patient_dept_id)              AS dept_id,
        coalesce(reg.sam_room_id,         a.sam_room_id)                  AS room_id,
        coalesce(reg.bed_no,              a.bed_no)                       AS bed_no,
        coalesce(reg.s_xb_dm,             a.s_xb_dm)                      AS s_xb_dm,
        coalesce(reg.birthday,            a.birthday)                     AS birthday,
        a.scheduled_date                                                  AS scheduled_date,
        ar.in_oproom_date                                                 AS in_oproom_date,
        ar.out_oproom_date                                                AS out_oproom_date,
        ar.rec_in_date                                                    AS rec_in_date,
        ar.rec_out_date                                                   AS rec_out_date,
        ar.height                                                         AS height,
        ar.weight                                                         AS weight
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
            ON a.id = ar.sam_apply_id AND ar.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg
            ON reg.id = a.id AND reg.isdeleted = '0'
    WHERE a.isdeleted = '0'
      AND a.health_service_org_id = 'HXSSMZK'
      AND a.sam_room_id NOT IN ('73')
      AND (
               a.oper_type = 'ROOM_OPER'
            OR (a.oper_type IN ('NJ_OPER', 'QZJ_OPER') AND a.patient_source = '03')
           )
      AND coalesce(reg.is_emergency, a.is_emergency) IS DISTINCT FROM '1'
      AND nullif(trim(ar.in_oproom_date), '') IS NOT NULL
      AND nullif(trim(ar.rec_out_date),  '') IS NOT NULL
      AND length(trim(ar.in_oproom_date)) >= 10
      AND length(trim(ar.rec_out_date))  >= 10
      AND a.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND a.scheduled_date <= (SELECT dt_end   FROM p_sched)
),
-- ② oper_name：手术名称聚合 (sam_reg_op 优先,fallback sam_apply_op)
oper_name AS (
    SELECT
        c.apply_id,
        coalesce(
            array_join(array_agg(DISTINCT sro.operation_name) FILTER (WHERE sro.operation_name IS NOT NULL), '+'),
            array_join(array_agg(DISTINCT sao.operation_name) FILTER (WHERE sao.operation_name IS NOT NULL), '+')
        ) AS operation_name
    FROM cohort c
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op sro
            ON sro.sam_reg_id  = c.apply_id AND sro.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply_op sao
            ON sao.sam_apply_id = c.apply_id AND sao.isdeleted = '0'
    GROUP BY c.apply_id
)
SELECT
    c.apply_id                                                         AS "手术ID",                 -- sam_apply.id
    ir.ipi_registration_no                                             AS "住院登记号",              -- ipi_registration.ipi_registration_no
    coalesce(ir.patient_name, c.patient_name)                          AS "姓名",                    -- ipi_registration.patient_name / cohort.patient_name
    -- 年龄（入室年 − 出生年；varchar 安全计算）
    CASE
        WHEN length(trim(coalesce(c.in_oproom_date,''))) >= 4
         AND length(trim(coalesce(ir.birthday,''))) >= 4
        THEN cast(
            cast(substr(trim(c.in_oproom_date), 1, 4) AS integer)
          - cast(substr(trim(ir.birthday),       1, 4) AS integer)
            AS varchar
        )
        ELSE ''
    END                                                                AS "年龄",                    -- 派生：sam_anar.in_oproom_date − ipi_registration.birthday
    xb.s_xb_cmc                                                        AS "性别",                    -- gb_t_2261_1_2003.s_xb_cmc
    c.height                                                           AS "身高",                    -- sam_anar.height
    c.weight                                                           AS "体重",                    -- sam_anar.weight
    hd.department_chinese_name                                         AS "科室",                    -- hra00_department.department_chinese_name
    c.bed_no                                                           AS "床号",                    -- coalesce(sam_reg.bed_no, sam_apply.bed_no)
    rm.oper_room                                                       AS "手术间",                  -- sam_room.oper_room
    on1.operation_name                                                 AS "手术名称",                -- sam_reg_op/sam_apply_op listagg
    c.scheduled_date                                                   AS "手术日期",                -- sam_apply.scheduled_date
    c.in_oproom_date                                                   AS "入手术间时间",            -- sam_anar.in_oproom_date
    c.out_oproom_date                                                  AS "出手术间时间",            -- sam_anar.out_oproom_date
    c.rec_in_date                                                      AS "入PACU时间",              -- sam_anar.rec_in_date
    c.rec_out_date                                                     AS "出PACU时间",              -- sam_anar.rec_out_date
    t.id                                                               AS "用药事件ID",              -- sam_anar_enent.id
    t.event_text                                                       AS "药品名称",                -- sam_anar_enent.event_text
    t.single_dose                                                      AS "用量",                    -- sam_anar_enent.single_dose
    t.density                                                          AS "浓度",                    -- sam_anar_enent.density
    -- 原 Oracle 的 nvl2(density, density*10, 1)
    CASE
        WHEN nullif(trim(t.density), '') IS NOT NULL
        THEN cast(try_cast(t.density AS double) * 10 AS varchar)
        ELSE '1'
    END                                                                AS "density_value",          -- 派生
    coalesce(pj3.s_jldw_cmc, pj2.s_jldw_cmc)                           AS "用药单位",                -- pub_jldw.s_jldw_cmc
    substr(t.ordered_date, 1, 10)                                      AS "用药日期",                -- sam_anar_enent.ordered_date(前 10)
    t.ordered_date                                                     AS "开始时间",                -- sam_anar_enent.ordered_date
    t.end_date                                                         AS "结束时间",                -- sam_anar_enent.end_date
    -- 持续时长（分钟,保留 2 位）
    CASE
        WHEN try(date_parse(substr(t.ordered_date,1,19), '%Y-%m-%d %H:%i:%s')) IS NOT NULL
         AND try(date_parse(substr(t.end_date,    1,19), '%Y-%m-%d %H:%i:%s')) IS NOT NULL
        THEN round(
            cast(
                date_diff(
                    'second',
                    date_parse(substr(t.ordered_date,1,19), '%Y-%m-%d %H:%i:%s'),
                    date_parse(substr(t.end_date,    1,19), '%Y-%m-%d %H:%i:%s')
                ) AS double
            ) / 60.0,
            2
        )
    END                                                                AS "持续时间_分钟",            -- 派生：end_date − ordered_date
    t.duration                                                         AS "是否持续用药",            -- sam_anar_enent.duration (1=持续/0=单次)
    CASE t.duration WHEN '1' THEN '持续用药' ELSE '单次用药' END        AS "用药方式",                -- 派生
    dnd.is_weight_relate                                               AS "是否与体重有关",          -- drm_nuu_ds.is_weight_relate
    dnd.is_speed_relate                                                AS "是否与速度有关",          -- drm_nuu_ds.is_speed_relate
    dnd.udu_du_scale                                                   AS "最后转换比",              -- drm_nuu_ds.udu_du_scale
    pj1.s_jldw_cmc                                                     AS "最后单位",                -- pub_jldw.s_jldw_cmc (by drm_dictionary.single_dose_unit)
    dd.drug_chemistry_name                                             AS "化学名称"                 -- drm_dictionary.drug_chemistry_name
FROM cohort c
INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent t
        ON t.sam_anar_id = c.anar_id
       AND t.isdeleted   = '0'
       AND t.is_rec_enent = '2'
       AND t.s_mzsjlb_dm  = '22'           -- 麻醉用药事件
       AND nullif(trim(t.ordered_date), '') IS NOT NULL
       AND try(date_parse(substr(trim(t.ordered_date), 1, 19), '%Y-%m-%d %H:%i:%s')) IS NOT NULL
       AND try(date_parse(substr(trim(c.in_oproom_date), 1, 19), '%Y-%m-%d %H:%i:%s')) IS NOT NULL
       AND try(date_parse(substr(trim(c.rec_out_date), 1, 19), '%Y-%m-%d %H:%i:%s')) IS NOT NULL
       AND try(date_parse(substr(trim(coalesce(nullif(trim(t.end_date), ''), t.ordered_date)), 1, 19), '%Y-%m-%d %H:%i:%s'))
           IS NOT NULL
       AND try(date_parse(substr(trim(t.ordered_date), 1, 19), '%Y-%m-%d %H:%i:%s'))
           <= try(date_parse(substr(trim(c.rec_out_date), 1, 19), '%Y-%m-%d %H:%i:%s'))
       AND try(date_parse(substr(trim(coalesce(nullif(trim(t.end_date), ''), t.ordered_date)), 1, 19), '%Y-%m-%d %H:%i:%s'))
           >= try(date_parse(substr(trim(c.in_oproom_date), 1, 19), '%Y-%m-%d %H:%i:%s'))
LEFT JOIN oper_name on1                  ON on1.apply_id = c.apply_id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.drm_nuu_ds dnd
        ON t.single_dose_unit = dnd.id AND dnd.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.drm_dictionary dd
        ON dd.id = t.drug_id AND dd.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_jldw pj1
        ON pj1.s_jldw_dm = dd.single_dose_unit AND pj1.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_jldw pj2
        ON pj2.s_jldw_dm = t.single_dose_unit  AND pj2.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_jldw pj3
        ON pj3.s_jldw_dm = dnd.udu             AND pj3.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ir
        ON ir.id = c.ipi_id AND ir.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.gb_t_2261_1_2003 xb
        ON xb.s_xb_dm = c.s_xb_dm AND xb.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department hd
        ON hd.department_code = c.dept_id AND hd.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_room rm
        ON rm.id = c.room_id AND rm.isdeleted = '0'
ORDER BY c.scheduled_date DESC, c.apply_id, t.ordered_date;

-- =============================================================================
-- 字段血缘汇总：
--   cohort                ← sam_apply + sam_anar + sam_reg
--   用药事件              ← sam_anar_enent (filter: is_rec_enent='2' AND s_mzsjlb_dm='22')
--   药品字典/化学名/最后单位 ← drm_nuu_ds + drm_dictionary + pub_jldw(1/2/3)
--   患者住院号/生日(年龄)/姓名 ← ipi_registration
--   性别中文              ← gb_t_2261_1_2003 (by sam_reg.s_xb_dm / sam_apply.s_xb_dm)
--   科室/手术间/手术名称  ← hra00_department + sam_room + sam_reg_op/sam_apply_op
-- 备注：
--   1) 与 01 同一 cohort；与 02 同路径窗（入室~出PACU）对齐用药重叠区间
--   2) 与原 Oracle 区别：去掉 ipi 单体入参,cohort+p_sched 划定人群；入室~出PACU 外的事件已剔除
--   3) duration 与 try_cast 兼容 '1'/'0' 与 1/0 两种 varchar 字面
-- =============================================================================
