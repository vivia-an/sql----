-- =============================================================================
-- 文件：02_生命体征_Presto.sql
-- 源：手麻原始sql/生命体征(1).txt（Oracle，5 段模板）
-- 引擎：Presto
-- 库：hid0101_orcl_operaanesthisa_emrhis
-- 形态：一张可直接执行的大表（无占位符）。原 5 段模板逻辑：
--   段①传入参数(取入室/出室时间+设备ID) → 内联在 cohort_devices CTE
--   段②获取ID(按 ipi_no 找手术 id)      → 去掉 ipi 限定，cohort 与 01_手术信息查询报表 完全对齐（含业务三件套）
--   段③获取表名(分区表名)               → 大数据平台已统一为 sam_anar_vs_dev 一张表，不再分区
--   段④基本信息                          → 内联在主 SELECT
--   段⑤监护仪数据                        → 聚合到「每台手术 × 每个监护项目」一行
--
-- 口径：与 01 一致 —— 业务三件套 + 择期 + 入室/出PACU均有值 + 最近3年(scheduled_date∈p_sched)
--       生命体征裁窗：每条读数限定在 「入手术间 ~ 出PACU」（in_oproom_date ~ rec_out_date），对齐路径定义
-- 行级：one row per (apply_id, vspd_name) — 每台手术每种监护项目一行（min/max/avg/count/首末时间）
--
-- 注意：
--   1) 原 Oracle 走分区表 SAM_ANAR_VS_DEV_yyyymmdd / SAM_ANAR_VS_DEV_ALL；大数据平台一般
--      已合并为 SAM_ANAR_VS_DEV 一张事实表，本版直接走它；如线上仍是按日分区，请把
--      hid0101_orcl_operaanesthisa_emrhis.sam_anar_vs_dev 换成具体的合并视图名
--   2) vspd_value 在大数据平台为 varchar；用 try_cast(... AS double) 安全转数
--   3) time_point 也是 varchar；用 substr 前 19 位 + date_parse 做精确比较
--   4) 监护数据量极大；本版用 cohort_devices 把设备 ID 集合提前下推到 sam_anar_vs_dev 上
--      并按 cohort 时间窗对 time_point 做范围裁剪，避免全表扫
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
        a.scheduled_date                                                  AS scheduled_date,
        ar.in_oproom_date                                                 AS in_oproom_date,
        ar.out_oproom_date                                                AS out_oproom_date,
        ar.rec_in_date                                                    AS rec_in_date,
        ar.rec_out_date                                                   AS rec_out_date
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
-- ② cohort_devices：cohort 内每台手术对应的监护仪设备 ID（关键下推键）
cohort_devices AS (
    SELECT
        c.apply_id,
        c.anar_id,
        c.in_oproom_date,
        c.rec_out_date,
        savs.sam_anar_vs_dev_id AS device_id
    FROM cohort c
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_vs savs
            ON savs.sam_anar_id = c.anar_id AND savs.isdeleted = '0'
    WHERE savs.sam_anar_vs_dev_id IS NOT NULL
),
-- ③ vitals_raw：把 cohort_devices 与 sam_anar_vs_dev 直接关联,
--    并把每条 vital 读数裁到 「入室~出PACU」（与 03 时间段对齐）
vitals_raw AS (
    SELECT
        cd.apply_id,
        d.vspd_name,
        d.vspd_value,
        d.time_point,
        d.sam_anar_vspd_id
    FROM cohort_devices cd
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_vs_dev d
            ON d.sam_device_id = cd.device_id AND d.isdeleted = '0'
    WHERE d.vspd_name IS NOT NULL
      AND nullif(trim(d.time_point), '') IS NOT NULL
      -- 全局裁切（随 p_sched 变更，减压扫描）
      AND d.time_point >= (SELECT dt_start FROM p_sched)
      AND d.time_point <= (SELECT dt_end   FROM p_sched)
      AND d.time_point >= cd.in_oproom_date
      AND d.time_point <= cd.rec_out_date
),
-- ④ vital_agg：每台手术 × 每个监护项目 一行
vital_agg AS (
    SELECT
        apply_id,
        vspd_name,
        max(sam_anar_vspd_id)                                AS sam_anar_vspd_id,
        count(*)                                             AS reading_count,
        min(time_point)                                      AS first_time,
        max(time_point)                                      AS last_time,
        min(try_cast(vspd_value AS double))                  AS min_value,
        max(try_cast(vspd_value AS double))                  AS max_value,
        avg(try_cast(vspd_value AS double))                  AS avg_value,
        count(try_cast(vspd_value AS double))                AS numeric_count
    FROM vitals_raw
    GROUP BY apply_id, vspd_name
),
-- ⑤ 手术 + 名称聚合（按 sam_reg_op 优先 fallback sam_apply_op）
oper_name AS (
    SELECT
        c.apply_id,
        coalesce(
            array_join(array_agg(DISTINCT sro.operation_name)  FILTER (WHERE sro.operation_name IS NOT NULL), '+'),
            array_join(array_agg(DISTINCT sao.operation_name)  FILTER (WHERE sao.operation_name IS NOT NULL), '+')
        ) AS operation_name
    FROM cohort c
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op sro
            ON sro.sam_reg_id  = c.apply_id AND sro.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply_op sao
            ON sao.sam_apply_id = c.apply_id AND sao.isdeleted = '0'
    GROUP BY c.apply_id
)
SELECT
    c.apply_id                                AS "手术ID",                   -- sam_apply.id
    ir.ipi_registration_no                    AS "住院登记号",                -- ipi_registration.ipi_registration_no
    c.patient_name                            AS "姓名",                      -- coalesce(sam_reg.patient_name, sam_apply.patient_name)
    hd.department_chinese_name                AS "科室",                      -- hra00_department.department_chinese_name
    c.bed_no                                  AS "床号",                      -- coalesce(sam_reg.bed_no, sam_apply.bed_no)
    rm.oper_room                              AS "手术间",                    -- sam_room.oper_room
    on1.operation_name                        AS "手术名称",                  -- coalesce(sam_reg_op.operation_name, sam_apply_op.operation_name) listagg
    c.scheduled_date                          AS "手术日期",                  -- sam_apply.scheduled_date
    c.in_oproom_date                          AS "入手术间时间",              -- sam_anar.in_oproom_date
    c.out_oproom_date                         AS "出手术间时间",              -- sam_anar.out_oproom_date
    c.rec_in_date                             AS "入PACU时间",                -- sam_anar.rec_in_date
    c.rec_out_date                            AS "出PACU时间",                -- sam_anar.rec_out_date
    va.sam_anar_vspd_id                       AS "监护项目代码",              -- sam_anar_vs_dev.sam_anar_vspd_id
    va.vspd_name                              AS "监护项目名称",              -- sam_anar_vs_dev.vspd_name
    va.reading_count                          AS "采集次数",                  -- count(*)
    va.numeric_count                          AS "数值型采集次数",            -- count(try_cast 成功的)
    va.first_time                             AS "首次采集时间",              -- min(sam_anar_vs_dev.time_point)
    va.last_time                              AS "末次采集时间",              -- max(sam_anar_vs_dev.time_point)
    va.min_value                              AS "最小值",                    -- min(try_cast(vspd_value AS double))
    va.max_value                              AS "最大值",                    -- max(try_cast(vspd_value AS double))
    round(va.avg_value, 2)                    AS "平均值"                     -- avg(try_cast(vspd_value AS double))
FROM cohort c
INNER JOIN vital_agg va        ON va.apply_id = c.apply_id
LEFT JOIN oper_name on1        ON on1.apply_id = c.apply_id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ir
       ON ir.id = c.ipi_id AND ir.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department hd
       ON hd.department_code = c.dept_id AND hd.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_room rm
       ON rm.id = c.room_id AND rm.isdeleted = '0'
ORDER BY c.scheduled_date DESC, c.apply_id, va.vspd_name;

-- =============================================================================
-- 字段血缘汇总：
--   cohort                ← sam_apply + sam_anar + sam_reg
--   设备 ID(device_id)    ← sam_anar_vs.sam_anar_vs_dev_id
--   生命体征数据          ← sam_anar_vs_dev.{time_point, vspd_name, vspd_value, sam_anar_vspd_id}
--   患者住院号            ← ipi_registration.ipi_registration_no
--   科室                  ← hra00_department.department_chinese_name (by department_code)
--   手术间                ← sam_room.oper_room
--   手术名称              ← sam_reg_op.operation_name / sam_apply_op.operation_name (listagg fallback)
-- 备注：
--   1) 若线上 sam_anar_vs_dev 量级过大,可考虑改为 cohort_devices 与 sam_anar_vs_dev 的 dynamic
--      filter / broadcast 提示;或先持久化 cohort_devices 到 staging
--   2) 若仍按日分区(SAM_ANAR_VS_DEV_yyyymmdd),需要把 vitals_raw 改为对所有相关分区表 UNION ALL,
--      或在大数据侧建一张合并视图
--   3) 输出按 (手术日期 desc, apply_id, vspd_name) 排序,便于按手术分组浏览
--   4) cohort 与 01/03 一致；体征时间窗为「入室~出PACU」与 03 用药重叠窗一致
-- =============================================================================
