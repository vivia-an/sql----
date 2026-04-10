-- Oracle 手麻输血明细 SQL → Presto 适配版
-- 血缘：sam_apply / sam_reg / sam_reg_op / sam_anar(聚合) → ipi/opc/hra00_department
--       sam_anar_enent(ev.s_mzsjlb_dm='31') + pub_jldw + pub_aboxx + pub_rhxx → 按申请展开多行输血记录
-- 说明：原 Oracle 上界 TO_DATE('2026-04-02 00:00:00') 为闭区间端点，varchar 比较时 4/2 当天非零点时刻可能超出；需全天可改为 '2026-04-02 23:59:59'
-- 内层已去掉未出现在 SELECT 中的 ig/og/aop 关联，避免多行放大导致 listagg 手术名称重复（若必须与 Oracle 逐字一致可再加回）
-- 可按需追加：a.health_service_org_id、oper_type、is_reject、s_sssyzt_dm 等

WITH p_sched AS (
    SELECT
        '2025-04-01 00:00:00' AS dt_start,
        '2026-04-02 00:00:00' AS dt_end
)
SELECT
    ieg.ipno AS "病案号",
    coalesce(ieg.ipi_registration_no, opc.opc_registration_no) AS "登记号",
    info.patient_name AS "姓名",
    info.birthday AS "出生日期",
    dpt.department_chinese_name AS "患者所在科室",
    info.oper_name AS "手术名称",
    info.oper_beging_date AS "手术开始",
    info.oper_end_date AS "手术结束",
    xueinfo.ordered_date AS "输血开始时间",
    xueinfo.end_date AS "输血结束时间",
    concat(coalesce(xueinfo.s_aboxx_cmc, ''), coalesce(xueinfo.s_rhxx_cmc, '')) AS "血型",
    xueinfo.event_text AS "输血类型",
    xueinfo.clsingledose AS "单次剂量_总和",
    xueinfo.s_jldw_cmc AS "单位",
    CAST('' AS VARCHAR) AS "血袋号"
FROM (
    SELECT
        a.id AS apply_id,
        coalesce(max(reg.ipi_registration_id), max(a.ipi_registration_id)) AS ipi_registration_id,
        coalesce(max(reg.opc_registration_id), max(a.ipi_registration_id)) AS opc_registration_id,
        max(ar.oper_beging_date) AS oper_beging_date,
        max(ar.oper_end_date) AS oper_end_date,
        coalesce(max(reg.patient_name), max(a.patient_name)) AS patient_name,
        coalesce(max(reg.birthday), max(a.birthday)) AS birthday,
        array_join(array_agg(o.operation_name ORDER BY o.operation_name), '；') AS oper_name,
        coalesce(max(reg.patient_dept_id), max(a.patient_dept_id)) AS dept_id
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg
        ON reg.id = a.id AND reg.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op o
        ON reg.id = o.sam_reg_id AND o.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
        ON a.id = ar.sam_apply_id AND ar.isdeleted = '0'
    WHERE a.isdeleted = '0'
      AND a.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND a.scheduled_date <= (SELECT dt_end FROM p_sched)
    GROUP BY a.id
) info
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ieg
    ON ieg.id = info.ipi_registration_id AND ieg.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.opc_registration opc
    ON opc.id = info.opc_registration_id AND opc.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department dpt
    ON dpt.id = info.dept_id AND dpt.isdeleted = '0'
INNER JOIN (
    SELECT
        ev.sam_apply_id AS apid,
        ev.event_text AS event_text,
        abo.s_aboxx_cmc AS s_aboxx_cmc,
        rh.s_rhxx_cmc AS s_rhxx_cmc,
        ev.single_dose AS clsingledose,
        ev.ordered_date AS ordered_date,
        ev.end_date AS end_date,
        pj.s_jldw_cmc AS s_jldw_cmc
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply ap
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ev
        ON ev.sam_apply_id = ap.id AND ev.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_jldw pj
        ON pj.s_jldw_dm = ev.single_dose_unit AND pj.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_aboxx abo
        ON abo.s_aboxx_dm = ev.s_aboxx_dm AND abo.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_rhxx rh
        ON rh.s_rhxx_dm = ev.s_rhxx_dm AND rh.isdeleted = '0'
    WHERE ap.isdeleted = '0'
      AND ap.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND ap.scheduled_date <= (SELECT dt_end FROM p_sched)
      AND ev.s_mzsjlb_dm = '31'
) xueinfo
    ON xueinfo.apid = info.apply_id;
