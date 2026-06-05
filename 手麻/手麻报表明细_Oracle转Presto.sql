-- Oracle 手麻明细 SQL → Presto 适配版（与提供的 Oracle 清单对齐）
-- 血缘：SAM_APPLY / SAM_REG / SAM_REG_OP / SAM_APPLY_OP / SAM_ANAR / HRM_EMPLOYEE / HRA00_DEPARTMENT / SAM_ROOM
--       SAM_EMR_REC+SAM_EMR_REC_NV(麻醉方式) / SAM_ANAR_ENENT(术后运转、出血量、术中保温) / PUB_JLDW / GB_T_2261_1_2003
--       IPI_REGISTRATION / OPC_REGISTRATION
--       PRO_SEND_ORDER + SYS_USER（非手麻库，catalog 见下）
-- 说明：子查询中 Oracle 为 max(blood_loss) AS oper_time，本版按源 SQL 亦映射「手术预计时长」至该别名；若需业务含义上的「预计时长」可改为 max(a.op_time)
-- 派运/用户库：hid0101_orcl_operaanesthisa_cdxtboot.SYS_USER（与 Oracle 侧 cdxtboot.sys_user 对应，可按环境改为 cdxt_boot）
-- 输出列名：下划线汉语拼音，见文尾「列名 拼音—中文 映射表」

WITH p_sched AS (
    SELECT
        '2024-12-01 00:00:00' AS dt_start,
        '2024-12-31 23:59:59' AS dt_end
)
SELECT
    ieg.ipno AS bing_an_hao,
    coalesce(ieg.ipi_registration_no, opc.opc_registration_no) AS deng_ji_hao,
    info.patient_name AS xing_ming,
    xb.s_xb_cmc AS xing_bie,
    info.birthday AS chu_sheng_ri_qi,
    ar.height AS shen_gao,
    ar.weight AS ti_zhong,
    (CASE WHEN info.is_emergency = '1' THEN '急诊' ELSE '择期' END) AS shou_shu_lei_bie,
    (CASE WHEN info.is_daytime = '1' THEN '是' ELSE '否' END) AS shi_fou_ri_jian_shou_shu,
    mzfs.mzfs_cmc AS ma_zui_fang_shi,
    info.asadm AS asa_fen_ji,
    cast('' AS varchar) AS ji_zhen_shou_shu_fen_ji,
    rank() OVER (
        PARTITION BY info.room_id, info.scheduled_date
        ORDER BY info.in_oproom_date, info.oper_beging_date
    ) AS tai_ci,
    cast('' AS varchar) AS shou_tai,
    cast('' AS varchar) AS mo_tai,
    cast('' AS varchar) AS zhou_mo,
    dpt.department_chinese_name AS huan_zhe_suo_zai_ke_shi,
    docdept.department_chinese_name AS shou_shu_yi_sheng_ke_shi,
    info.schedate AS shou_shu_an_pai_ri_qi,
    rm.oper_room AS shou_shu_jian,
    concat(rm.building, rm.floor) AS shou_shu_jian_wei_zhi,
    info.main_diag AS shu_qian_zhen_duan,
    info.oper_name AS shou_shu_ming_cheng,
    hzqx.tw_place AS shu_hou_yun_zhuan_di_dian,
    info.qkdj AS qie_kou_deng_ji,
    mzem.employee_name AS ma_zui_yi_sheng,
    mzem.id AS ma_zui_yi_sheng_gong_hao,
    mzem1.employee_name AS ma_zui_zhu_shou_1,
    mzem1.id AS ma_zui_zhu_shou_1_gong_hao,
    mzem2.employee_name AS ma_zui_zhu_shou_2,
    mzem2.id AS ma_zui_zhu_shou_2_gong_hao,
    xhdoc1.employee_name AS xun_hui_hu_shi_1,
    xhdoc1.id AS xun_hui_hu_shi_1_gong_hao,
    xhdoc2.employee_name AS xun_hui_hu_shi_2,
    xhdoc2.id AS xun_hui_hu_shi_2_gong_hao,
    xsdoc1.employee_name AS xi_shou_hu_shi_1,
    xsdoc1.id AS xi_shou_hu_shi_1_gong_hao,
    xsdoc2.employee_name AS xi_shou_hu_shi_2,
    xsdoc2.id AS xi_shou_hu_shi_2_gong_hao,
    ssem.employee_name AS shou_shu_yi_sheng,
    ssem.id AS shou_shu_yi_sheng_gong_hao,
    ssem1.employee_name AS shou_shu_zhu_shou_1,
    ssem1.id AS shou_shu_zhu_shou_1_gong_hao,
    ssem2.employee_name AS shou_shu_zhu_shou_2,
    ssem2.id AS shou_shu_zhu_shou_2_gong_hao,
    docdept.department_chinese_name AS yi_sheng_ke_shi,
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
    END AS shou_shu_shi_chang,
    cbu_jie.realname AS jie_dan_ren_jie,
    pso_jie.send_order_time AS pai_dan_shi_jian_jie,
    pso_jie.order_receiving_time AS jie_dan_shi_jian_jie,
    pso_jie.start_place_arrive_time AS dao_da_chu_fa_di_shi_jian_jie,
    pso_jie.send_order_arrive_time AS jie_dao_huan_zhe_shi_jian_jie,
    cast('' AS varchar) AS dao_da_shou_shu_shi_shi_jian_jie,
    pso_jie.burglary_time AS dao_da_shou_shu_jian_shi_jian_jie,
    pso_jie.send_order_finish_time AS wan_cheng_ding_dan_shi_jian_jie,
    info.oper_beging_date AS shou_shu_kai_shi,
    info.oper_end_date AS shou_shu_jie_shu,
    info.ana_beging_date AS ma_zui_kai_shi,
    info.ana_end_date AS ma_zui_jie_shu,
    info.in_oproom_date AS jin_shou_shu_jian,
    info.out_oproom_date AS chu_shou_shu_jian,
    cast('' AS varchar) AS jian_li_ren_gong_qi_dao,
    cast('' AS varchar) AS chai_chu_ren_gong_qi_dao,
    info.oper_time AS shou_shu_yu_ji_shi_chang,
    info.blood_loss AS yu_gu_chu_xue_liang,
    xueinfo.clsingledose AS shi_ji_chu_xue_liang,
    info.rec_in_date AS dao_da_pacu_shi_jian,
    info.rec_out_date AS chu_pacu_shi_jian,
    cbu_song.realname AS jie_dan_ren_song,
    pso_song.send_order_time AS pai_dan_shi_jian_song,
    pso_song.order_receiving_time AS jie_dan_shi_jian_song,
    pso_song.start_place_arrive_time AS dao_da_chu_fa_di_shi_jian_song,
    pso_song.send_order_arrive_time AS jie_dao_huan_zhe_shi_jian_song,
    pso_song.burglary_time AS dao_da_mu_di_di_shi_jian_song,
    pso_song.send_order_finish_time AS wan_cheng_ding_dan_shi_jian_song,
    cast('' AS varchar) AS xiao_hui_fu_shi_shi_jian_shi_jian,
    cast('' AS varchar) AS ru_xiao_hui_fu_shi_shi_jian,
    reqrm.oper_room AS yu_ji_shou_shu_jian,
    cast('' AS varchar) AS bian_geng_shou_shu_jian,
    (CASE
        WHEN info.s_sssyzt_dm = '30' AND info.in_oproom_date IS NULL THEN '排程未做'
        WHEN info.s_sssyzt_dm = '90' AND info.oper_beging_date IS NOT NULL AND info.oper_end_date IS NOT NULL THEN '已完成手术'
        WHEN info.ana_beging_date IS NULL AND info.oper_beging_date IS NULL THEN '麻醉前取消'
        WHEN info.ana_beging_date IS NOT NULL AND info.oper_beging_date IS NULL THEN '手术开始前取消'
        ELSE ''
    END) AS shou_shu_wan_cheng_zhuang_tai,
    (CASE
        WHEN info.s_sssyzt_dm = '90' AND info.oper_beging_date IS NOT NULL AND info.oper_end_date IS NOT NULL THEN ''
        ELSE info.reject_reason
    END) AS shou_shu_qu_xiao_yuan_yin,
    (CASE WHEN szbw.event_text IS NOT NULL THEN '是' ELSE '否' END) AS shu_zhong_bao_wen,
    cast('' AS varchar) AS shu_qian_kang_jun_yao_wu_shi_yong_shi_jian,
    cast('' AS varchar) AS shu_zhong_kang_jun_yao_wu_zhui_jia_shi_jian,
    cast('' AS varchar) AS shu_qian_kang_jun_yao_wu_yi_zhu_ming_cheng,
    cast('' AS varchar) AS shu_zhong_kang_jun_yao_wu_yi_zhu_ming_cheng
FROM (
    SELECT
        a.id AS apply_id,
        max(ar.id) AS anar_id,
        coalesce(max(reg.sam_room_id), max(a.sam_room_id)) AS room_id,
        coalesce(max(reg.ipi_registration_id), max(a.ipi_registration_id)) AS ipi_registration_id,
        coalesce(max(reg.opc_registration_id), max(a.opc_registration_id)) AS opc_registration_id,
        coalesce(max(reg.patient_name), max(a.patient_name)) AS patient_name,
        array_join(array_agg(o.operation_name ORDER BY o.operation_name), '；') AS oper_name,
        coalesce(max(reg.is_emergency), max(a.is_emergency)) AS is_emergency,
        coalesce(max(reg.is_daytime), max(a.is_daytime)) AS is_daytime,
        coalesce(max(reg.patient_source), max(a.patient_source)) AS patient_source,
        max(a.blood_loss) AS blood_loss,
        max(a.blood_loss) AS oper_time,
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
      AND a.health_service_org_id = 'HXSSMZK'
      AND a.sam_room_id NOT IN ('73')
      AND (
          a.oper_type = 'ROOM_OPER'
          OR (a.oper_type IN ('NJ_OPER', 'QZJ_OPER') AND a.patient_source = '03')
      )
    GROUP BY a.id
) info
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ieg
    ON ieg.id = info.ipi_registration_id AND ieg.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.opc_registration opc
    ON opc.id = info.opc_registration_id AND opc.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department dpt
    ON dpt.id = info.dept_id AND dpt.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pro_send_order pso_jie
    ON pso_jie.apply_id = info.apply_id AND pso_jie.direction = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_cdxtboot.SYS_USER cbu_jie
    ON cast(cbu_jie.id AS varchar) = cast(pso_jie.carer_id AS varchar)
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pro_send_order pso_song
    ON pso_song.apply_id = info.apply_id AND pso_song.direction = '1'
LEFT JOIN hid0101_orcl_operaanesthisa_cdxtboot.SYS_USER cbu_song
    ON cast(cbu_song.id AS varchar) = cast(pso_song.carer_id AS varchar)
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
                WHEN lower(trim(pj.s_jldw_cmc)) IN ('u', '治疗量') THEN try_cast(ev.single_dose AS double) * 200
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
      AND ap.scheduled_date <= (SELECT dt_end FROM p_sched)
      AND ev.s_mzsj_dm = '40_2'
    GROUP BY ev.sam_apply_id
) xueinfo
    ON xueinfo.apid = info.apply_id
LEFT JOIN (
    SELECT
        en.sam_apply_id,
        max(en.event_text) AS event_text
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply ap
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent en
        ON en.sam_apply_id = ap.id AND en.isdeleted = '0'
    WHERE ap.isdeleted = '0'
      AND ap.scheduled_date >= (SELECT dt_start FROM p_sched)
      AND ap.scheduled_date <= (SELECT dt_end FROM p_sched)
      AND (
          en.s_mzsj_dm IN ('10_29', '10_30')
          OR (en.s_mzsj_dm = '10_41' AND strpos(coalesce(en.event_text, ''), '保温毯加温') > 0)
      )
    GROUP BY en.sam_apply_id
) szbw
    ON szbw.sam_apply_id = info.apply_id
ORDER BY info.scheduled_date DESC;

-- =============================================================================
-- 列名 拼音（下划线）与中文含义 映射表（与上方 SELECT 输出列一一对应）
-- =============================================================================
-- | pinyin_jian_ti（输出列名）     | 中文含义 |
-- |------------------------------|----------|
-- | bing_an_hao                  | 病案号 |
-- | deng_ji_hao                  | 登记号 |
-- | xing_ming                    | 姓名 |
-- | xing_bie                     | 性别 |
-- | chu_sheng_ri_qi              | 出生日期 |
-- | shen_gao                     | 身高 |
-- | ti_zhong                     | 体重 |
-- | shou_shu_lei_bie             | 手术类别 |
-- | shi_fou_ri_jian_shou_shu     | 是否日间手术 |
-- | ma_zui_fang_shi              | 麻醉方式 |
-- | asa_fen_ji                   | ASA分级 |
-- | ji_zhen_shou_shu_fen_ji      | 急诊手术分级 |
-- | tai_ci                       | 台次 |
-- | shou_tai                     | 首台 |
-- | mo_tai                       | 末台 |
-- | zhou_mo                      | 周末 |
-- | huan_zhe_suo_zai_ke_shi      | 患者所在科室 |
-- | shou_shu_yi_sheng_ke_shi     | 手术医生科室 |
-- | shou_shu_an_pai_ri_qi        | 手术安排日期 |
-- | shou_shu_jian                | 手术间 |
-- | shou_shu_jian_wei_zhi        | 手术间位置 |
-- | shu_qian_zhen_duan           | 术前诊断 |
-- | shou_shu_ming_cheng          | 手术名称 |
-- | shu_hou_yun_zhuan_di_dian    | 术后运转地点 |
-- | qie_kou_deng_ji              | 切口等级 |
-- | ma_zui_yi_sheng              | 麻醉医生 |
-- | ma_zui_yi_sheng_gong_hao     | 麻醉医生工号 |
-- | ma_zui_zhu_shou_1            | 麻醉助手1 |
-- | ma_zui_zhu_shou_1_gong_hao   | 麻醉助手1工号 |
-- | ma_zui_zhu_shou_2            | 麻醉助手2 |
-- | ma_zui_zhu_shou_2_gong_hao   | 麻醉助手2工号 |
-- | xun_hui_hu_shi_1             | 巡回护士1 |
-- | xun_hui_hu_shi_1_gong_hao    | 巡回护士1工号 |
-- | xun_hui_hu_shi_2             | 巡回护士2 |
-- | xun_hui_hu_shi_2_gong_hao    | 巡回护士2工号 |
-- | xi_shou_hu_shi_1             | 洗手护士1 |
-- | xi_shou_hu_shi_1_gong_hao    | 洗手护士1工号 |
-- | xi_shou_hu_shi_2             | 洗手护士2 |
-- | xi_shou_hu_shi_2_gong_hao    | 洗手护士2工号 |
-- | shou_shu_yi_sheng            | 手术医生（主刀） |
-- | shou_shu_yi_sheng_gong_hao   | 手术医生工号 |
-- | shou_shu_zhu_shou_1          | 手术助手1 |
-- | shou_shu_zhu_shou_1_gong_hao | 手术助手1工号 |
-- | shou_shu_zhu_shou_2          | 手术助手2 |
-- | shou_shu_zhu_shou_2_gong_hao | 手术助手2工号 |
-- | yi_sheng_ke_shi              | 医生科室 |
-- | shou_shu_shi_chang           | 手术时长 |
-- | jie_dan_ren_jie              | 接单人（接） |
-- | pai_dan_shi_jian_jie         | 派单时间（接） |
-- | jie_dan_shi_jian_jie         | 接单时间（接） |
-- | dao_da_chu_fa_di_shi_jian_jie| 到达出发地时间（接） |
-- | jie_dao_huan_zhe_shi_jian_jie| 接到患者时间（接） |
-- | dao_da_shou_shu_shi_shi_jian_jie | 到达手术室时间（接） |
-- | dao_da_shou_shu_jian_shi_jian_jie | 到达手术间时间（接） |
-- | wan_cheng_ding_dan_shi_jian_jie | 完成订单时间（接） |
-- | shou_shu_kai_shi             | 手术开始 |
-- | shou_shu_jie_shu              | 手术结束 |
-- | ma_zui_kai_shi               | 麻醉开始 |
-- | ma_zui_jie_shu                | 麻醉结束 |
-- | jin_shou_shu_jian             | 进手术间 |
-- | chu_shou_shu_jian             | 出手术间 |
-- | jian_li_ren_gong_qi_dao       | 建立人工气道 |
-- | chai_chu_ren_gong_qi_dao      | 拆除人工气道 |
-- | shou_shu_yu_ji_shi_chang      | 手术预计时长 |
-- | yu_gu_chu_xue_liang          | 预估出血量 |
-- | shi_ji_chu_xue_liang         | 实际出血量 |
-- | dao_da_pacu_shi_jian         | 到达PACU时间 |
-- | chu_pacu_shi_jian            | 出PACU时间 |
-- | jie_dan_ren_song             | 接单人（送） |
-- | pai_dan_shi_jian_song        | 派单时间（送） |
-- | jie_dan_shi_jian_song        | 接单时间（送） |
-- | dao_da_chu_fa_di_shi_jian_song | 到达出发地时间（送） |
-- | jie_dao_huan_zhe_shi_jian_song | 接到患者时间（送） |
-- | dao_da_mu_di_di_shi_jian_song | 到达目的地时间（送） |
-- | wan_cheng_ding_dan_shi_jian_song | 完成订单时间（送） |
-- | xiao_hui_fu_shi_shi_jian_shi_jian | 小恢复室事件时间 |
-- | ru_xiao_hui_fu_shi_shi_jian  | 入小恢复室时间 |
-- | yu_ji_shou_shu_jian          | 预计手术间 |
-- | bian_geng_shou_shu_jian      | 变更手术间 |
-- | shou_shu_wan_cheng_zhuang_tai| 手术完成状态 |
-- | shou_shu_qu_xiao_yuan_yin    | 手术取消原因 |
-- | shu_zhong_bao_wen            | 术中保温 |
-- | shu_qian_kang_jun_yao_wu_shi_yong_shi_jian | 术前抗菌药物使用时间 |
-- | shu_zhong_kang_jun_yao_wu_zhui_jia_shi_jian | 术中抗菌药物追加时间 |
-- | shu_qian_kang_jun_yao_wu_yi_zhu_ming_cheng | 术前抗菌药物医嘱名称 |
-- | shu_zhong_kang_jun_yao_wu_yi_zhu_ming_cheng | 术中抗菌药物医嘱名称 |
-- =============================================================================
