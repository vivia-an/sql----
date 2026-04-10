-- Oracle 手麻明细 SQL → Presto 适配版
-- 血缘：SAM_APPLY / SAM_REG / SAM_REG_OP / SAM_APPLY_OP / SAM_ANAR / HRM_EMPLOYEE / HRA00_DEPARTMENT / SAM_ROOM
--       SAM_EMR_REC+SAM_EMR_REC_NV(麻醉方式) / SAM_ANAR_ENENT(术后运转、出血量) / PUB_JLDW / GB_T_2261_1_2003 / PUB_SSSYZT
--       IPI_REGISTRATION / OPC_REGISTRATION
--       PRO_SEND_ORDER + SYS_USER（非手麻库，catalog/schema 需按环境替换）
-- 说明：平台字段多为 varchar；日期比较与 date_parse 按实际格式可微调；原 Oracle 结束日为 2024-12-30 00:00:00 易漏数，此处改为 12 月整月可改回变量区
-- 原 Oracle 子查询中 oper_time 与 blood_loss 均取 blood_loss，本版「手术预计时长」改为 max(a.op_time)（若需与 Oracle 完全一致可改回 blood_loss）
-- 可按需追加：a.health_service_org_id / a.oper_type='ROOM_OPER' / a.is_reject / a.s_sssyzt_dm 等业务过滤（见 AI大模型SQL生成指南 / 手麻SQL字段血缘）
-- 派运/用户库：请将 CATALOG_TRANSPORT、CATALOG_CDXT 替换为实际 Presto catalog（若与手麻同库可改为 hid0101_orcl_operaanesthisa_emrhis）

WITH p_sched AS (
    SELECT
        '2024-12-01 00:00:00' AS dt_start,
        '2024-12-31 23:59:59' AS dt_end
)
SELECT
    ieg.ipno AS "病案号",
    coalesce(ieg.ipi_registration_no, opc.opc_registration_no) AS "登记号",
    info.patient_name AS "姓名",
    xb.s_xb_cmc AS "性别",
    info.birthday AS "出生日期",
    ar.height AS "身高",
    ar.weight AS "体重",
    (CASE WHEN info.is_emergency = '1' THEN '急诊' ELSE '择期' END) AS "手术类别",
    mzfs.mzfs_cmc AS "麻醉方式",
    info.asadm AS "ASA分级",
    CAST('' AS VARCHAR) AS "急诊手术分级",
    rank() OVER (
        PARTITION BY info.room_id, info.scheduled_date
        ORDER BY info.in_oproom_date, info.oper_beging_date
    ) AS "台次",
    CAST('' AS VARCHAR) AS "首台",
    CAST('' AS VARCHAR) AS "末台",
    CAST('' AS VARCHAR) AS "周末",
    dpt.department_chinese_name AS "患者所在科室",
    info.in_oproom_date AS "手术日期",
    rm.oper_room AS "手术间",
    concat(rm.building, rm.floor) AS "手术间位置",
    info.main_diag AS "术前诊断",
    info.oper_name AS "手术名称",
    hzqx.tw_place AS "术后运转地点",
    info.qkdj AS "切口等级",
    mzem.employee_name AS "麻醉医生",
    mzem.id AS "麻醉医生工号",
    mzem1.employee_name AS "麻醉助手1",
    mzem1.id AS "麻醉助手1工号",
    mzem2.employee_name AS "麻醉助手2",
    mzem2.id AS "麻醉助手2工号",
    xhdoc1.employee_name AS "巡回护士1",
    xhdoc1.id AS "巡回护士1工号",
    xhdoc2.employee_name AS "巡回护士2",
    xhdoc2.id AS "巡回护士2工号",
    xsdoc1.employee_name AS "洗手护士1",
    xsdoc1.id AS "洗手护士1工号",
    xsdoc2.employee_name AS "洗手护士2",
    xsdoc2.id AS "洗手护士2工号",
    ssem.employee_name AS "手术医生",
    ssem.id AS "手术医生工号",
    ssem1.employee_name AS "手术助手1",
    ssem1.id AS "手术助手1工号",
    ssem2.employee_name AS "手术助手2",
    ssem2.id AS "手术助手2工号",
    docdept.department_chinese_name AS "医生科室",
    CASE
        WHEN try(date_parse(nullif(trim(info.oper_beging_date), ''), '%Y-%m-%d %H:%i:%s')) IS NOT NULL
        THEN round(
            cast(
                date_diff(
                    'second',
                    date_parse(nullif(trim(info.oper_beging_date), ''), '%Y-%m-%d %H:%i:%s'),
                    coalesce(
                        try(date_parse(nullif(trim(info.oper_end_date), ''), '%Y-%m-%d %H:%i:%s')),
                        current_timestamp
                    )
                ) AS DOUBLE
            ) / 3600.0,
            2
        )
    END AS "手术时长",
    cbu_jie.realname AS "接单人（接）",
    pso_jie.send_order_time AS "派单时间（接）",
    pso_jie.order_receiving_time AS "接单时间（接）",
    pso_jie.start_place_arrive_time AS "到达出发地时间（接）",
    pso_jie.send_order_arrive_time AS "接到患者时间（接）",
    CAST('' AS VARCHAR) AS "到达手术室时间（接）",
    pso_jie.burglary_time AS "到达手术间时间（接）",
    pso_jie.send_order_finish_time AS "完成订单时间（接）",
    info.oper_beging_date AS "手术开始",
    info.oper_end_date AS "手术结束",
    info.ana_beging_date AS "麻醉开始",
    info.ana_end_date AS "麻醉结束",
    info.in_oproom_date AS "进手术间",
    info.out_oproom_date AS "出手术间",
    CAST('' AS VARCHAR) AS "建立人工气道",
    CAST('' AS VARCHAR) AS "拆除人工气道",
    info.oper_time AS "手术预计时长",
    info.blood_loss AS "预估出血量",
    xueinfo.clsingledose AS "实际出血量",
    info.rec_in_date AS "到达PACU时间",
    info.rec_out_date AS "出PACU时间",
    cbu_song.realname AS "接单人（送）",
    pso_song.send_order_time AS "派单时间（送）",
    pso_song.order_receiving_time AS "接单时间（送）",
    pso_song.start_place_arrive_time AS "到达出发地时间（送）",
    pso_song.send_order_arrive_time AS "接到患者时间（送）",
    pso_song.burglary_time AS "到达目的地时间（送）",
    pso_song.send_order_finish_time AS "完成订单时间（送）",
    CAST('' AS VARCHAR) AS "小恢复室事件时间",
    CAST('' AS VARCHAR) AS "入小恢复室时间",
    reqrm.oper_room AS "预计手术间",
    CAST('' AS VARCHAR) AS "变更手术间",
    ps.s_sssyzt_cmc AS "手术完成状态",
    info.reject_reason AS "手术取消原因",
    CAST('' AS VARCHAR) AS "术中保温",
    CAST('' AS VARCHAR) AS "术前抗菌药物使用时间",
    CAST('' AS VARCHAR) AS "术中抗菌药物追加时间",
    CAST('' AS VARCHAR) AS "术前抗菌药物医嘱名称",
    CAST('' AS VARCHAR) AS "术中抗菌药物医嘱名称"
FROM (
    SELECT
        a.id AS apply_id,
        max(ar.id) AS anar_id,
        coalesce(max(reg.sam_room_id), max(a.sam_room_id)) AS room_id,
        coalesce(max(reg.ipi_registration_id), max(a.ipi_registration_id)) AS ipi_registration_id,
        coalesce(max(reg.opc_registration_id), max(a.ipi_registration_id)) AS opc_registration_id,
        coalesce(max(reg.patient_name), max(a.patient_name)) AS patient_name,
        array_join(array_agg(o.operation_name ORDER BY o.operation_name), '；') AS oper_name,
        coalesce(max(reg.is_emergency), max(a.is_emergency)) AS is_emergency,
        coalesce(max(reg.is_daytime), max(a.is_daytime)) AS is_daytime,
        coalesce(max(reg.patient_source), max(a.patient_source)) AS patient_source,
        max(a.blood_loss) AS blood_loss,
        max(a.op_time) AS oper_time,
        max(a.oper_type) AS oper_type,
        max(a.is_reject) AS is_reject,
        max(a.reject_reason) AS reject_reason,
        max(a.s_sssyzt_dm) AS s_sssyzt_dm,
        max(substr(a.scheduled_date, 1, 10)) AS schedate,
        max(a.scheduled_date) AS scheduled_date,
        max(a.op_time) AS ap_op_time,
        coalesce(max(reg.s_xb_dm), max(a.s_xb_dm)) AS s_xb_dm,
        max(a.sam_room_id) AS req_room_id,
        coalesce(max(o.s_asamzfj_dm), max(aop.s_asamzfj_dm)) AS asadm,
        coalesce(max(o.s_ssjb_dm), max(aop.s_ssjb_dm)) AS s_ssjb_dm,
        coalesce(max(o.s_ssqk_dj_dm), max(aop.s_ssqk_dj_dm)) AS qkdj,
        coalesce(max(reg.bed_no), max(a.bed_no)) AS bed_no,
        coalesce(max(reg.birthday), max(a.birthday)) AS birthday,
        coalesce(max(reg.main_diag), max(a.main_diag)) AS main_diag,
        coalesce(max(o.operator_doctor_id), max(aop.operator_doctor_id)) AS ssdoc_id,
        coalesce(max(o.operator_assistant_1), max(aop.operator_assistant_1)) AS ssdoc1_id,
        coalesce(max(o.operator_assistant_2), max(aop.operator_assistant_2)) AS ssdoc2_id,
        coalesce(max(o.narcotic_doctor_id), max(aop.narcotic_doctor_id)) AS mzdoc_id,
        coalesce(max(o.narcotic_assistant_1), max(aop.narcotic_assistant_1)) AS mzzs1_id,
        coalesce(max(o.narcotic_assistant_2), max(aop.narcotic_assistant_2)) AS mzzs2_id,
        coalesce(max(o.circuit_nurse_01), max(aop.circuit_nurse_01)) AS xhdoc1_id,
        coalesce(max(o.circuit_nurse_02), max(aop.circuit_nurse_02)) AS xhdoc2_id,
        coalesce(max(o.scrub_nurse_01), max(aop.scrub_nurse_01)) AS xsdoc1_id,
        coalesce(max(o.scrub_nurse_02), max(aop.scrub_nurse_02)) AS xsdoc2_id,
        coalesce(max(reg.patient_dept_id), max(a.patient_dept_id)) AS dept_id,
        max(ar.in_oproom_date) AS in_oproom_date,
        max(ar.out_oproom_date) AS out_oproom_date,
        max(ar.oper_beging_date) AS oper_beging_date,
        max(ar.oper_end_date) AS oper_end_date,
        max(ar.ana_beging_date) AS ana_beging_date,
        max(ar.ana_end_date) AS ana_end_date,
        max(ar.rec_in_date) AS rec_in_date,
        max(ar.rec_out_date) AS rec_out_date
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg
        ON reg.id = a.id AND reg.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ig
        ON ig.id = reg.ipi_registration_id AND ig.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.opc_registration og
        ON og.id = reg.opc_registration_id AND og.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op o
        ON reg.id = o.sam_reg_id AND o.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply_op aop
        ON a.id = aop.sam_apply_id AND aop.isdeleted = '0'
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
-- 以下两张表不在手麻库时请替换 catalog（示例用占位，需与平台一致）
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pro_send_order pso_jie
    ON pso_jie.apply_id = info.apply_id AND pso_jie.direction = '0'
LEFT JOIN  hid0101_orcl_operaanesthisa_cdxtboot.SYS_USER cbu_jie
    ON cast(cbu_jie.id AS VARCHAR) = cast(pso_jie.carer_id AS VARCHAR)
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pro_send_order pso_song
    ON pso_song.apply_id = info.apply_id AND pso_song.direction = '1'
LEFT JOIN  hid0101_orcl_operaanesthisa_cdxtboot.SYS_USER cbu_song
    ON cast(cbu_song.id AS VARCHAR) = cast(pso_song.carer_id AS VARCHAR)
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_sssyzt ps
    ON ps.s_sssyzt_dm = info.s_sssyzt_dm AND ps.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_room rm
    ON rm.id = info.room_id AND rm.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_room reqrm
    ON reqrm.id = info.req_room_id AND reqrm.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ssem
    ON ssem.id = info.ssdoc_id AND ssem.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ssem1
    ON ssem1.id = info.ssdoc1_id AND ssem1.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ssem2
    ON ssem2.id = info.ssdoc2_id AND ssem2.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department docdept
    ON docdept.id = ssem.department_id AND docdept.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee mzem
    ON mzem.id = info.mzdoc_id AND mzem.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee mzem1
    ON mzem1.id = info.mzzs1_id AND mzem1.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee mzem2
    ON mzem2.id = info.mzzs2_id AND mzem2.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee xhdoc1
    ON xhdoc1.id = info.xhdoc1_id AND xhdoc1.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee xhdoc2
    ON xhdoc2.id = info.xhdoc2_id AND xhdoc2.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee xsdoc1
    ON xsdoc1.id = info.xsdoc1_id AND xsdoc1.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee xsdoc2
    ON xsdoc2.id = info.xsdoc2_id AND xsdoc2.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.gb_t_2261_1_2003 xb
    ON xb.s_xb_dm = info.s_xb_dm AND xb.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
    ON ar.id = info.anar_id AND ar.isdeleted = '0'
LEFT JOIN (
    SELECT
        r.sam_apply_id,
        array_join(array_agg(n.node_value ORDER BY n.id), ';') AS mzfs_cmc
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec r
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec_nv n
        ON n.sam_emr_rec_id = r.id AND n.isdeleted = '0'
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply a
        ON a.id = r.sam_apply_id AND a.isdeleted = '0'
    WHERE r.isdeleted = '0'
      AND a.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND a.scheduled_date <= (SELECT dt_end FROM p_sched)
      AND a.oper_type = 'ROOM_OPER'
      AND n.node_name = 'S_MZFS_DM'
    GROUP BY r.sam_apply_id
) mzfs
    ON mzfs.sam_apply_id = info.apply_id
LEFT JOIN (
    SELECT
        ev.sam_apply_id AS apid,
        max(ev.tw_place) AS tw_place
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply ap
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ev
        ON ev.sam_apply_id = ap.id AND ev.isdeleted = '0'
    WHERE ap.isdeleted = '0'
      AND ap.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND ap.scheduled_date <= (SELECT dt_end FROM p_sched)
      AND ev.s_mzsj_dm = '10_5'
    GROUP BY ev.sam_apply_id
) hzqx
    ON hzqx.apid = info.apply_id
LEFT JOIN (
    SELECT
        ev.sam_apply_id AS apid,
        sum(
            CASE
                WHEN lower(pj.s_jldw_cmc) IN ('u', '治疗量') THEN try_cast(ev.single_dose AS DOUBLE) * 200
                ELSE try_cast(ev.single_dose AS DOUBLE)
            END
        ) AS clsingledose
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply ap
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ev
        ON ev.sam_apply_id = ap.id AND ev.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_jldw pj
        ON pj.s_jldw_dm = ev.single_dose_unit AND pj.isdeleted = '0'
    WHERE ap.isdeleted = '0'
      AND ap.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND ap.scheduled_date <= (SELECT dt_end FROM p_sched)
      AND ev.s_mzsj_dm = '40_2'
    GROUP BY ev.sam_apply_id
) xueinfo
    ON xueinfo.apid = info.apply_id
ORDER BY info.scheduled_date DESC;
