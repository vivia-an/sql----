-- =============================================================================
-- 文件：01_手术信息查询报表_Presto.sql
-- 源：手麻原始sql/需求1-手术信息查询报表(1).sql（Oracle）
-- 蓝本：手麻/手麻报表明细_Oracle转Presto.sql + 手麻/择期入手术间至出PACU_默认版_Presto.sql
-- 口径：所有 择期手术（is_emergency != '1') + 入手术间(ar.in_oproom_date) 与 出PACU(ar.rec_out_date) 均有值
--       时间窗按 sam_apply.scheduled_date 滚动 最近 3 年（2023-05-14 ~ 2026-05-14）
--       同目录 02_生命体征 / 03_用药 的 cohort 与本篇 info 子查询 WHERE 已对齐（含业务三件套）
-- 业务过滤：health_service_org_id='HXSSMZK'；sam_room_id NOT IN ('73')；
--           oper_type='ROOM_OPER' OR (oper_type IN ('NJ_OPER','QZJ_OPER') AND patient_source='03')
-- 引擎：Presto（中文字段名用双引号；varchar 日期用 substr/字符串比较或 try(date_parse(...))）
-- 库：hid0101_orcl_operaanesthisa_emrhis（手术麻醉），hid0101_orcl_operaanesthisa_cdxtboot（派单接送人员）
-- 逻辑删除：所有表 isdeleted='0'
-- 字段血缘标注：见每个 SELECT 列后的 -- 注释 与 文末映射表
-- 占位列：原 SQL 即留空（'急诊手术分级/首台/末台/周末/到达手术室时间（接）/建立人工气道/拆除人工气道/
--         变更手术间/小恢复室事件时间/入小恢复室时间/抗菌药物 4 列' 等），保持 '' 占位
-- =============================================================================

WITH p_sched AS (
    -- 最近 3 年；按 手术日期(scheduled_date) 落窗（字符串 yyyy-MM-dd HH:mm:ss 形式可直接字符串比较）
    SELECT
        '2023-05-14 00:00:00' AS dt_start,
        '2026-05-14 23:59:59' AS dt_end,
        '2023-05-14'           AS d_start,
        '2026-05-14'           AS d_end
),
rop_agg AS (
    -- sam_reg_op：按 sam_reg_id 聚合手术名称
    SELECT
        sam_reg_id,
        array_join(array_agg(operation_name ORDER BY operation_name), '；') AS operation_name_agg
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_reg_op
    WHERE isdeleted = '0'
    GROUP BY sam_reg_id
),
aop_agg AS (
    -- sam_apply_op：按 sam_apply_id 聚合手术名称（作为 reg 缺失时的兜底）
    SELECT
        sam_apply_id,
        array_join(array_agg(operation_name ORDER BY operation_name), '；') AS operation_name_agg
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply_op
    WHERE isdeleted = '0'
    GROUP BY sam_apply_id
)
SELECT
    ieg.ipno                                            AS "病案号",                       -- ipi_registration.ipno
    coalesce(ieg.ipi_registration_no, opc.opc_registration_no) AS "登记号",                -- ipi.ipi_registration_no | opc.opc_registration_no
    info.patient_name                                   AS "姓名",                         -- coalesce(reg.patient_name, sam_apply.patient_name)
    xb.s_xb_cmc                                         AS "性别",                         -- gb_t_2261_1_2003.s_xb_cmc
    info.birthday                                       AS "出生日期",                     -- coalesce(reg.birthday, sam_apply.birthday)
    ar.height                                           AS "身高",                         -- sam_anar.height
    ar.weight                                           AS "体重",                         -- sam_anar.weight
    (CASE WHEN info.is_emergency = '1' THEN '急诊' ELSE '择期' END) AS "手术类别",         -- 派生于 is_emergency
    (CASE WHEN info.is_daytime  = '1' THEN '是'   ELSE '否'   END) AS "是否日间手术",       -- 派生于 is_daytime
    mzfs.mzfs_cmc                                       AS "麻醉方式",                     -- sam_emr_rec_nv.node_value(node_name='S_MZFS_DM')
    info.asadm                                          AS "ASA分级",                      -- coalesce(sam_reg_op.s_asamzfj_dm, sam_apply_op.s_asamzfj_dm) ※ 输出代码值，原 SQL 同
    CAST('' AS varchar)                                 AS "急诊手术分级",                 -- 原 SQL 占位
    rank() OVER (
        PARTITION BY info.room_id, info.scheduled_date
        ORDER BY info.in_oproom_date, info.oper_beging_date
    )                                                   AS "台次",                         -- 派生：同手术间同日按入室/开始时间排名
    CAST('' AS varchar)                                 AS "首台",                         -- 原 SQL 占位
    CAST('' AS varchar)                                 AS "末台",                         -- 原 SQL 占位
    CAST('' AS varchar)                                 AS "周末",                         -- 原 SQL 占位
    dpt.department_chinese_name                         AS "患者所在科室",                 -- hra00_department(by dept_id) 患者所在科室
    docdept.department_chinese_name                     AS "手术医生科室",                 -- hra00_department(by ssem.department_id)
    info.schedate                                       AS "手术安排日期",                 -- substr(sam_apply.scheduled_date,1,10)
    rm.oper_room                                        AS "手术间",                       -- sam_room.oper_room
    concat(coalesce(rm.building,''), coalesce(rm.floor,'')) AS "手术间位置",               -- sam_room.building || floor
    info.main_diag                                      AS "术前诊断",                     -- coalesce(reg.main_diag, sam_apply.main_diag)
    info.oper_name                                      AS "手术名称",                     -- coalesce(sam_reg_op agg, sam_apply_op agg)
    hzqx.tw_place                                       AS "术后运转地点",                 -- sam_anar_enent.tw_place where s_mzsj_dm='10_5'
    info.qkdj                                           AS "切口等级",                     -- coalesce(sam_reg_op.s_ssqk_dj_dm, sam_apply_op.s_ssqk_dj_dm) ※ 代码值
    mzem.employee_name                                  AS "麻醉医生",                     -- hrm_employee.employee_name(by mzdoc_id)
    mzem.id                                             AS "麻醉医生工号",                 -- hrm_employee.id
    mzem1.employee_name                                 AS "麻醉助手1",
    mzem1.id                                            AS "麻醉助手1工号",
    mzem2.employee_name                                 AS "麻醉助手2",
    mzem2.id                                            AS "麻醉助手2工号",                -- 注：原 Oracle SQL 此处误写为 mzem2.employee_name，已按业务含义改为 id
    xhdoc1.employee_name                                AS "巡回护士1",
    xhdoc1.id                                           AS "巡回护士1工号",
    xhdoc2.employee_name                                AS "巡回护士2",
    xhdoc2.id                                           AS "巡回护士2工号",
    xsdoc1.employee_name                                AS "洗手护士1",
    xsdoc1.id                                           AS "洗手护士1工号",
    xsdoc2.employee_name                                AS "洗手护士2",
    xsdoc2.id                                           AS "洗手护士2工号",
    ssem.employee_name                                  AS "手术医生",
    ssem.id                                             AS "手术医生工号",
    ssem1.employee_name                                 AS "手术助手1",
    ssem1.id                                            AS "手术助手1工号",
    ssem2.employee_name                                 AS "手术助手2",
    ssem2.id                                            AS "手术助手2工号",
    docdept.department_chinese_name                     AS "医生科室",
    -- 手术时长（小时，保留 2 位）：oper_end_date - oper_beging_date 转秒后除 3600；end 为空时退回 current_timestamp
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
                ) AS double
            ) / 3600.0,
            2
        )
    END                                                 AS "手术时长",                     -- 派生：sam_anar.oper_beging_date / oper_end_date
    cbu_jie.realname                                    AS "接单人（接）",                 -- cdxtboot.sys_user.realname
    pso_jie.send_order_time                             AS "派单时间（接）",               -- pro_send_order.send_order_time
    pso_jie.order_receiving_time                        AS "接单时间（接）",               -- pro_send_order.order_receiving_time
    pso_jie.start_place_arrive_time                     AS "到达出发地时间（接）",         -- pro_send_order.start_place_arrive_time
    pso_jie.send_order_arrive_time                      AS "接到患者时间（接）",           -- pro_send_order.send_order_arrive_time
    CAST('' AS varchar)                                 AS "到达手术室时间（接）",         -- 原 SQL 占位
    pso_jie.burglary_time                               AS "到达手术间时间（接）",         -- pro_send_order.burglary_time
    pso_jie.send_order_finish_time                      AS "完成订单时间（接）",           -- pro_send_order.send_order_finish_time
    info.oper_beging_date                               AS "手术开始",                     -- sam_anar.oper_beging_date
    info.oper_end_date                                  AS "手术结束",                     -- sam_anar.oper_end_date
    info.ana_beging_date                                AS "麻醉开始",                     -- sam_anar.ana_beging_date
    info.ana_end_date                                   AS "麻醉结束",                     -- sam_anar.ana_end_date
    info.in_oproom_date                                 AS "进手术间",                     -- sam_anar.in_oproom_date
    info.out_oproom_date                                AS "出手术间",                     -- sam_anar.out_oproom_date
    CAST('' AS varchar)                                 AS "建立人工气道",                 -- 原 SQL 占位
    CAST('' AS varchar)                                 AS "拆除人工气道",                 -- 原 SQL 占位
    info.oper_time                                      AS "手术预计时长",                 -- 与原 SQL 一致：max(a.blood_loss) AS oper_time（原表别名错位，按源 SQL 保持）
    info.blood_loss                                     AS "预估出血量",                   -- sam_apply.blood_loss
    xueinfo.clsingledose                                AS "实际出血量",                   -- sum(sam_anar_enent.single_dose) where s_mzsj_dm='40_2'（u/治疗量×200）
    info.rec_in_date                                    AS "到达PACU时间",                 -- sam_anar.rec_in_date
    info.rec_out_date                                   AS "出PACU时间",                   -- sam_anar.rec_out_date
    cbu_song.realname                                   AS "接单人（送）",
    pso_song.send_order_time                            AS "派单时间（送）",
    pso_song.order_receiving_time                       AS "接单时间（送）",
    pso_song.start_place_arrive_time                    AS "到达出发地时间（送）",
    pso_song.send_order_arrive_time                     AS "接到患者时间（送）",
    pso_song.burglary_time                              AS "到达目的地时间（送）",
    pso_song.send_order_finish_time                     AS "完成订单时间（送）",
    CAST('' AS varchar)                                 AS "小恢复室事件时间",             -- 原 SQL 占位
    CAST('' AS varchar)                                 AS "入小恢复室时间",               -- 原 SQL 占位
    reqrm.oper_room                                     AS "预计手术间",                   -- sam_room(by sam_apply.sam_room_id).oper_room
    CAST('' AS varchar)                                 AS "变更手术间",                   -- 原 SQL 占位
    (CASE
        WHEN info.s_sssyzt_dm = '30' AND info.in_oproom_date IS NULL THEN '排程未做'
        WHEN info.s_sssyzt_dm = '90' AND info.oper_beging_date IS NOT NULL AND info.oper_end_date IS NOT NULL THEN '已完成手术'
        WHEN info.ana_beging_date IS NULL AND info.oper_beging_date IS NULL THEN '麻醉前取消'
        WHEN info.ana_beging_date IS NOT NULL AND info.oper_beging_date IS NULL THEN '手术开始前取消'
        ELSE ''
    END)                                                AS "手术完成状态",                 -- 派生
    (CASE
        WHEN info.s_sssyzt_dm = '90' AND info.oper_beging_date IS NOT NULL AND info.oper_end_date IS NOT NULL THEN ''
        ELSE info.reject_reason
    END)                                                AS "手术取消原因",                 -- sam_apply.reject_reason
    (CASE WHEN szbw.event_text IS NOT NULL THEN '是' ELSE '否' END) AS "术中保温",         -- sam_anar_enent.event_text where s_mzsj_dm in('10_29','10_30') or ('10_41' + 含'保温毯加温')
    CAST('' AS varchar)                                 AS "术前抗菌药物使用时间",         -- 原 SQL 占位
    CAST('' AS varchar)                                 AS "术中抗菌药物追加时间",         -- 原 SQL 占位
    CAST('' AS varchar)                                 AS "术前抗菌药物医嘱名称",         -- 原 SQL 占位
    CAST('' AS varchar)                                 AS "术中抗菌药物医嘱名称"          -- 原 SQL 占位
FROM (
    SELECT
        a.id                                                                                 AS apply_id,
        max(ar.id)                                                                           AS anar_id,
        coalesce(max(reg.sam_room_id),       max(a.sam_room_id))                              AS room_id,
        coalesce(max(reg.ipi_registration_id), max(a.ipi_registration_id))                    AS ipi_registration_id,
        coalesce(max(reg.opc_registration_id), max(a.opc_registration_id))                    AS opc_registration_id,
        coalesce(max(reg.patient_name),      max(a.patient_name))                             AS patient_name,
        coalesce(max(rop.operation_name_agg), max(aop.operation_name_agg))                    AS oper_name,
        coalesce(max(reg.is_emergency),      max(a.is_emergency))                             AS is_emergency,
        coalesce(max(reg.is_daytime),        max(a.is_daytime))                               AS is_daytime,
        coalesce(max(reg.patient_source),    max(a.patient_source))                           AS patient_source,
        max(a.blood_loss)                                                                     AS blood_loss,
        max(a.blood_loss)                                                                     AS oper_time,           -- 与原 SQL 一致（源 SQL 中 oper_time 别名挂在 blood_loss 上）
        max(a.oper_type)                                                                      AS oper_type,
        max(a.is_reject)                                                                      AS is_reject,
        max(a.reject_reason)                                                                  AS reject_reason,
        max(a.s_sssyzt_dm)                                                                    AS s_sssyzt_dm,
        max(substr(a.scheduled_date, 1, 10))                                                  AS schedate,
        max(a.scheduled_date)                                                                 AS scheduled_date,
        max(a.op_time)                                                                        AS ap_op_time,
        coalesce(max(reg.s_xb_dm),           max(a.s_xb_dm))                                  AS s_xb_dm,
        max(a.sam_room_id)                                                                    AS req_room_id,
        coalesce(max(rop_o.s_asamzfj_dm),    max(aop_o.s_asamzfj_dm))                         AS asadm,                -- ASA 代码（与原 SQL 一致）
        coalesce(max(rop_o.s_ssjb_dm),       max(aop_o.s_ssjb_dm))                            AS s_ssjb_dm,
        coalesce(max(rop_o.s_ssqk_dj_dm),    max(aop_o.s_ssqk_dj_dm))                         AS qkdj,                 -- 切口等级 代码
        coalesce(max(reg.bed_no),            max(a.bed_no))                                   AS bed_no,
        coalesce(max(reg.birthday),          max(a.birthday))                                 AS birthday,
        coalesce(max(reg.main_diag),         max(a.main_diag))                                AS main_diag,
        coalesce(max(rop_o.operator_doctor_id),  max(aop_o.operator_doctor_id))               AS ssdoc_id,
        coalesce(max(rop_o.operator_assistant_1),max(aop_o.operator_assistant_1))             AS ssdoc1_id,
        coalesce(max(rop_o.operator_assistant_2),max(aop_o.operator_assistant_2))             AS ssdoc2_id,
        coalesce(max(rop_o.narcotic_doctor_id),  max(aop_o.narcotic_doctor_id))               AS mzdoc_id,
        coalesce(max(rop_o.narcotic_assistant_1),max(aop_o.narcotic_assistant_1))             AS mzzs1_id,
        coalesce(max(rop_o.narcotic_assistant_2),max(aop_o.narcotic_assistant_2))             AS mzzs2_id,
        coalesce(max(rop_o.circuit_nurse_01),    max(aop_o.circuit_nurse_01))                 AS xhdoc1_id,
        coalesce(max(rop_o.circuit_nurse_02),    max(aop_o.circuit_nurse_02))                 AS xhdoc2_id,
        coalesce(max(rop_o.scrub_nurse_01),      max(aop_o.scrub_nurse_01))                   AS xsdoc1_id,
        coalesce(max(rop_o.scrub_nurse_02),      max(aop_o.scrub_nurse_02))                   AS xsdoc2_id,
        coalesce(max(reg.patient_dept_id),       max(a.patient_dept_id))                      AS dept_id,
        max(ar.in_oproom_date)                                                                AS in_oproom_date,
        max(ar.out_oproom_date)                                                               AS out_oproom_date,
        max(ar.oper_beging_date)                                                              AS oper_beging_date,
        max(ar.oper_end_date)                                                                 AS oper_end_date,
        max(ar.ana_beging_date)                                                               AS ana_beging_date,
        max(ar.ana_end_date)                                                                  AS ana_end_date,
        max(ar.rec_in_date)                                                                   AS rec_in_date,
        max(ar.rec_out_date)                                                                  AS rec_out_date
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
        ON a.id = ar.sam_apply_id AND ar.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg
        ON reg.id = a.id AND reg.isdeleted = '0'
    LEFT JOIN rop_agg rop
        ON rop.sam_reg_id = reg.id
    LEFT JOIN aop_agg aop
        ON aop.sam_apply_id = a.id
    -- 取医护/ASA/切口等级/手术级别 等字段需要原始 sam_reg_op / sam_apply_op（不能用聚合 CTE，因为字段太多）
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op rop_o
        ON rop_o.sam_reg_id = reg.id AND rop_o.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply_op aop_o
        ON aop_o.sam_apply_id = a.id AND aop_o.isdeleted = '0'
    WHERE a.isdeleted = '0'
      -- ① 业务三件套（与源 SQL 完全一致）
      AND a.health_service_org_id = 'HXSSMZK'
      AND a.sam_room_id NOT IN ('73')
      AND (
            a.oper_type = 'ROOM_OPER'
         OR (a.oper_type IN ('NJ_OPER','QZJ_OPER') AND a.patient_source = '03')
      )
      -- ② 时间窗（按 手术日期 = sam_apply.scheduled_date）
      AND a.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND a.scheduled_date <= (SELECT dt_end   FROM p_sched)
      -- ③ 择期（与「手术类别='择期'」一致）
      AND coalesce(reg.is_emergency, a.is_emergency) IS DISTINCT FROM '1'
      -- ④ 入手术间 与 出 PACU 均有值（前 10 位为 yyyy-mm-dd 形式）
      AND nullif(trim(ar.in_oproom_date), '') IS NOT NULL
      AND nullif(trim(ar.rec_out_date),  '') IS NOT NULL
      AND length(trim(ar.in_oproom_date)) >= 10
      AND length(trim(ar.rec_out_date))  >= 10
    GROUP BY a.id
) info
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ieg
    ON ieg.id = info.ipi_registration_id AND ieg.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.opc_registration opc
    ON opc.id = info.opc_registration_id AND opc.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department dpt
    ON dpt.id = info.dept_id AND dpt.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pro_send_order pso_jie
    ON pso_jie.apply_id = info.apply_id
   AND pso_jie.direction = '0'
   AND pso_jie.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_cdxtboot.sys_user cbu_jie
    ON cast(cbu_jie.id AS varchar) = cast(pso_jie.carer_id AS varchar)
   AND cbu_jie.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pro_send_order pso_song
    ON pso_song.apply_id = info.apply_id
   AND pso_song.direction = '1'
   AND pso_song.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_cdxtboot.sys_user cbu_song
    ON cast(cbu_song.id AS varchar) = cast(pso_song.carer_id AS varchar)
   AND cbu_song.isdeleted = '0'
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
-- 麻醉方式（sam_emr_rec + sam_emr_rec_nv 节点 S_MZFS_DM）
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
      AND a.scheduled_date <= (SELECT dt_end   FROM p_sched)
      AND a.oper_type = 'ROOM_OPER'
      AND n.node_name = 'S_MZFS_DM'
    GROUP BY r.sam_apply_id
) mzfs
    ON mzfs.sam_apply_id = info.apply_id
-- 术后运转地点
LEFT JOIN (
    SELECT
        ev.sam_apply_id AS apid,
        max(ev.tw_place) AS tw_place
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply ap
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ev
        ON ev.sam_apply_id = ap.id AND ev.isdeleted = '0'
    WHERE ap.isdeleted = '0'
      AND ap.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND ap.scheduled_date <= (SELECT dt_end   FROM p_sched)
      AND ev.s_mzsj_dm = '10_5'
    GROUP BY ev.sam_apply_id
) hzqx
    ON hzqx.apid = info.apply_id
-- 实际出血量（u/治疗量 × 200）
LEFT JOIN (
    SELECT
        ev.sam_apply_id AS apid,
        sum(
            CASE
                WHEN lower(trim(pj.s_jldw_cmc)) IN ('u','治疗量')
                THEN try_cast(ev.single_dose AS double) * 200
                ELSE try_cast(ev.single_dose AS double)
            END
        ) AS clsingledose
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply ap
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ev
        ON ev.sam_apply_id = ap.id AND ev.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_jldw pj
        ON pj.s_jldw_dm = ev.single_dose_unit AND pj.isdeleted = '0'
    WHERE ap.isdeleted = '0'
      AND ap.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND ap.scheduled_date <= (SELECT dt_end   FROM p_sched)
      AND ev.s_mzsj_dm = '40_2'
    GROUP BY ev.sam_apply_id
) xueinfo
    ON xueinfo.apid = info.apply_id
-- 术中保温事件
LEFT JOIN (
    SELECT
        en.sam_apply_id,
        max(en.event_text) AS event_text
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply ap
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent en
        ON en.sam_apply_id = ap.id AND en.isdeleted = '0'
    WHERE ap.isdeleted = '0'
      AND ap.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND ap.scheduled_date <= (SELECT dt_end   FROM p_sched)
      AND (
            en.s_mzsj_dm IN ('10_29','10_30')
         OR (en.s_mzsj_dm = '10_41' AND strpos(coalesce(en.event_text,''), '保温毯加温') > 0)
      )
    GROUP BY en.sam_apply_id
) szbw
    ON szbw.sam_apply_id = info.apply_id
ORDER BY info.scheduled_date DESC;

-- =============================================================================
-- 备注：
-- 1) ASA分级 / 切口等级 输出为「代码」(与源 Oracle SQL 一致；如需中文名称可分别 left join
--    hid0101_orcl_operaanesthisa_emrhis.pub_asamzfj 取 s_asamzfj_cmc；
--    hid0101_orcl_operaanesthisa_emrhis.pub_ssqk_dj 取 s_ssqk_dj_cmc）
-- 2) 「手术预计时长」字段在源 Oracle SQL 中为 max(a.blood_loss) AS oper_time，本版保留同步语义；
--    如需取业务预计时长，请改为 max(a.op_time) AS oper_time
-- 3) 「麻醉助手2工号」源 Oracle SQL 误写为 mzem2.employee_name，本版按业务含义改为 mzem2.id
-- 4) cdxtboot 库（派单接送人员）按本部线上环境改为 hid0101_orcl_operaanesthisa_cdxtboot
-- 5) 所有日期字段在大数据平台均为 varchar，原样输出；如需做计算，请用 try(date_parse(...,'%Y-%m-%d %H:%i:%s'))
-- 6) 「入手术间到出PACU」口径：sam_anar.in_oproom_date 与 sam_anar.rec_out_date 同时非空且前 10 位
--    为合法日期；如需进一步保证出PACU时间晚于入手术间时间，可加：
--      AND date_parse(substr(rec_out_date,1,19),'%Y-%m-%d %H:%i:%s')
--          > date_parse(substr(in_oproom_date,1,19),'%Y-%m-%d %H:%i:%s')
-- =============================================================================
