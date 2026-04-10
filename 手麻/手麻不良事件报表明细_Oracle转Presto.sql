-- Oracle 手麻不良事件明细 SQL → Presto 适配版（对齐 需求2-不良事件管理(1).sql）
-- 血缘：info 子查询 → sam_adverse_event.adverse_details(JSON) + sam_adverse / factor / reason
--       hrm_employee / hra00_department / sam_room / gb_t_2261_1_2003 / pub_smzd / pub_sssyzt（JOIN 与需求一致，SELECT 未引用 ps）
-- Oracle valuejson(col, '"key"') → try(json_extract_scalar(col, '$.key'))；valuejsonsz 同路径取标量文本（若存嵌套 JSON 需再解析）
-- f_j_getage：varchar 年份差近似；日期区间见 p_sched
-- 可按需追加：a.health_service_org_id、oper_type、is_reject、s_sssyzt_dm 等

WITH p_sched AS (
    SELECT
        '2023-12-01 00:00:00' AS dt_start,
        '2026-12-30 00:00:00' AS dt_end
)
SELECT
    CASE ad.status
        WHEN '1' THEN '疑似'
        WHEN '2' THEN '已否认'
        WHEN '3' THEN '已审核'
        WHEN '4' THEN '已上报'
        WHEN '5' THEN '已确认'
        ELSE '未知状态'
    END AS "状态",
    info.patient_name AS "患者姓名",
    xb.s_xb_cmc AS "性别",
    CASE
        WHEN info.birthday IS NOT NULL
            AND info.scheduled_date IS NOT NULL
            AND length(trim(info.birthday)) >= 4
            AND length(trim(info.scheduled_date)) >= 4
        THEN cast(
            cast(substr(trim(info.scheduled_date), 1, 4) AS INTEGER)
            - cast(substr(trim(info.birthday), 1, 4) AS INTEGER) AS VARCHAR
        )
        ELSE ''
    END AS "年龄",
    ar.height AS "患者身高(cm)",
    ar.weight AS "患者体重(kg)",
    info.birthday AS "患者出生日期",
    coalesce(ieg.ipi_registration_no, opc.opc_registration_no) AS "登记号",
    ieg.ipno AS "病案号",
    (CASE WHEN info.is_emergency = '1' THEN '急诊' ELSE '择期' END) AS "手术类型",
    dpt.department_chinese_name AS "科室",
    info.bed_no AS "床号",
    rm.oper_room AS "手术间",
    info.scheduled_date AS "手术安排日期",
    ssem.employee_name AS "主刀医师",
    mzem.employee_name AS "麻醉医师",
    mzem1.employee_name AS "麻醉助手I",
    mzem2.employee_name AS "麻醉助手II",
    mzem3.employee_name AS "麻醉助手III",
    info.main_diag AS "患者诊断",
    info.oper_name AS "手术名称",
    info.in_oproom_date AS "入室时间",
    info.ana_beging_date AS "麻醉开始时间",
    info.ana_end_date AS "麻醉结束时间",
    info.oper_beging_date AS "手术开始时间",
    info.oper_end_date AS "手术结束时间",
    info.out_oproom_date AS "出室时间",
    info.asadm AS "ASA分级",
    CASE ad.patient_type
        WHEN '1' THEN '常规手术'
        WHEN '2' THEN '常规手术(临时安排)'
        WHEN '3' THEN '限期手术'
        WHEN '4' THEN '急症手术'
        WHEN '5' THEN '严重复合创伤'
        ELSE '/'
    END AS "病人分类",
    CAST('' AS VARCHAR) AS "麻醉医师分类",
    CAST('' AS VARCHAR) AS "时间分段",
    CASE ad.anar_phase
        WHEN '2' THEN '麻醉前'
        WHEN '8' THEN '麻醉诱导前期'
        WHEN '3' THEN '麻醉诱导'
        WHEN '4' THEN '术中'
        WHEN '5' THEN '拔管'
        WHEN '6' THEN '苏醒期'
        WHEN '7' THEN '术后回病房'
        ELSE '/'
    END AS "麻醉时间分段",
    adv.event_name AS "不良事件名称",
    adf.factor_name AS "不良事件因素",
    adr.reason_name AS "不良事件原因",
    ad.happen_date AS "发生时间",
    adem.employee_name AS "填表人",
    ad.fill_man_id AS "填表人ID",
    ad.submit_date AS "提交时间",
    ad.review_time AS "审核时间",
    adrvem.employee_name AS "审核人",
    yzy.s_smzd_cmc AS "所属亚专业",
    CAST('' AS VARCHAR) AS "否定不良事件说明",
    ad.mark AS "简述不良事件发生经过",
    CAST('' AS VARCHAR) AS "系统识别依据",
    CASE ad.is_key_point
        WHEN '1' THEN '是'
        WHEN '2' THEN '否'
        ELSE '/'
    END AS "是否重点关注",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.by_fault')) = '1' THEN '由失误造成、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.by_technology')) = '1' THEN '由技术造成、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.by_opt')) = '1' THEN '由外科手术造成、' ELSE '' END
    ) AS "不良事件发生原因",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.wrong')) = '1' THEN '判断错误、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.inexperienced')) = '1' THEN '经验不足、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.less_environment')) = '1' THEN '环境不够熟悉、' ELSE '' END,
        coalesce(try(json_extract_scalar(ad.adverse_details, '$.lk_orther_text')), '')
    ) AS "计划错误(知识不足) ",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.befor_opt_assess')) = '1' THEN '术前评估不当、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.befor_opt_ready')) = '1' THEN '术前准备不当、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.Equ_check_error')) = '1' THEN '设备检查失误、' ELSE '' END,
        coalesce(try(json_extract_scalar(ad.adverse_details, '$.lu_ort_text')), '')
    ) AS "计划错误(规则不熟悉)",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.pre_job_train')) = '1' THEN '岗前培训疏忽、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.dis_and_neg')) = '1' THEN '外因分心疏忽、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.fail_to_ob')) = '1' THEN '疏于观察、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.merr_err')) = '1' THEN '记忆错误、' ELSE '' END,
        coalesce(try(json_extract_scalar(ad.adverse_details, '$.lt_ort_text')), '')
    ) AS "实施错误-监护(技术不熟悉)",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.elk_err')) = '1' THEN '判断错误、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.elk_exper')) = '1' THEN '经验不足、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.elk_en')) = '1' THEN '环境不够熟悉、' ELSE '' END,
        coalesce(try(json_extract_scalar(ad.adverse_details, '$.elk_ort_text')), '')
    ) AS "实施错误-问题处理(知识不足) ",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.not_foll_ins')) = '1' THEN '未按指南操作、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.not_foll_pre')) = '1' THEN '未按方案操作、' ELSE '' END,
        coalesce(try(json_extract_scalar(ad.adverse_details, '$.lp_ort_text')), '')
    ) AS "实施错误-问题处理(规划不熟悉) ",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.czyl')) = '1' THEN '操作压力、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.jlwt')) = '1' THEN '交流问题、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.qstd')) = '1' THEN '缺少团队工作、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.bdzdls')) = '1' THEN '不当的指导老师、' ELSE '' END
    ) AS "潜在的/起作用的因素:文化 ",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.qsmzzs')) = '1' THEN '缺少麻醉助手、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.zsbl')) = '1' THEN '助手不力、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.bsgzry')) = '1' THEN '新/不熟的工作人员、' ELSE '' END
    ) AS "潜在的/起作用的因素:工作人员 ",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.bsxwz')) = '1' THEN '不熟悉位置、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.bsxfx')) = '1' THEN '不习惯方向、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.bsxbr')) = '1' THEN '不熟悉病人、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.bsxjh')) = '1' THEN '不熟悉监护、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.bsxsb')) = '1' THEN '不熟悉设备、' ELSE '' END
    ) AS "潜在的/起作用的因素:工作环境 ",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.pl')) = '1' THEN '疲劳、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.jz')) = '1' THEN '紧张、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.sb')) = '1' THEN '生病、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.cx')) = '1' THEN '粗心、' ELSE '' END
    ) AS "潜在的/起作用的因素:个人 ",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.you')) = '1' THEN '有-未执行、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.bsy')) = '1' THEN '不适用、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.meiyou')) = '1' THEN '没有-应当建立、' ELSE '' END
    ) AS "潜在的/起作用的因素:政策/方案",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.experience')) = '1' THEN '前面经验/高度警惕、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.good_assistant')) = '1' THEN '训练有素的助手、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.near_teacher')) = '1' THEN '临近的指导老师、' ELSE '' END,
        coalesce(try(json_extract_scalar(ad.adverse_details, '$.one_ort_text')), '')
    ) AS "改善结果的因素:第一行",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.good_plan')) = '1' THEN '良好的计划/方案、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.cooperate')) = '1' THEN '请教与合作、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.chech_agin')) = '1' THEN '设备再检查、' ELSE '' END,
        coalesce(try(json_extract_scalar(ad.adverse_details, '$.second_ort_text')), '')
    ) AS "改善结果的因素:第二行",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.early_detection')) = '1' THEN '监护仪或报警早发现、' ELSE '' END,
        coalesce(try(json_extract_scalar(ad.adverse_details, '$.third_ort_text')), '')
    ) AS "改善结果的因素:第三行",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.good_pre')) = '1' THEN '现有的自由条件下能够预防、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.equipment_pre')) = '1' THEN '有充分理由认为额外设备能够预防、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.resouse_pre')) = '1' THEN '现有的资源条件下可能预防、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.person_pre')) = '1' THEN '有充分理由认为增加资源可能预防、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.no_pre')) = '1' THEN '任何改变都不能明显预防、' ELSE '' END
    ) AS "预防措施",
    concat(
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.no_pro')) = '1' THEN '无影响、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.equ_temp_pro')) = '1' THEN '病人不能注意到的暂时影响、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.res_temp_pro')) = '1' THEN '能完全恢复的暂时影响、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.slight_ever')) = '1' THEN '可能是不致残的永久性损害、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.serious_ever')) = '1' THEN '可能是致残的永久性损害、' ELSE '' END,
        CASE WHEN try(json_extract_scalar(ad.adverse_details, '$.dead')) = '1' THEN '死亡、' ELSE '' END
    ) AS "后果",
    CAST('' AS VARCHAR) AS "随访时间",
    CAST('' AS VARCHAR) AS "记录时间",
    CAST('' AS VARCHAR) AS "随访人",
    coalesce(try(json_extract_scalar(ad.adverse_details, '$.follow_visit')), '') AS "随访说明",
    coalesce(try(json_extract_scalar(ad.adverse_details, '$.review_note')), '') AS "审核说明"
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
        coalesce(max(o.narcotic_assistant_3), max(aop.narcotic_assistant_3)) AS mzzs3_id,
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
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_sssyzt ps
    ON ps.s_sssyzt_dm = info.s_sssyzt_dm AND ps.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_room rm
    ON rm.id = info.room_id AND rm.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ssem
    ON ssem.id = info.ssdoc_id AND ssem.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee mzem
    ON mzem.id = info.mzdoc_id AND mzem.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee mzem1
    ON mzem1.id = info.mzzs1_id AND mzem1.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee mzem2
    ON mzem2.id = info.mzzs2_id AND mzem2.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee mzem3
    ON mzem3.id = info.mzzs3_id AND mzem3.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.gb_t_2261_1_2003 xb
    ON xb.s_xb_dm = info.s_xb_dm AND xb.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
    ON ar.id = info.anar_id AND ar.isdeleted = '0'
INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_adverse_event ad
    ON ad.apply_id = info.apply_id AND ad.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_adverse adv
    ON adv.id = ad.event_id AND adv.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_adverse_factor adf
    ON adf.id = ad.factor_id AND adf.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_adverse_reason adr
    ON adr.id = ad.reason_id AND adr.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee adem
    ON adem.id = ad.fill_man_id AND adem.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee adrvem
    ON adrvem.id = ad.reviewer_id AND adrvem.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_smzd yzy
    ON yzy.s_smzd_dm = ad.profession_id AND yzy.isdeleted = '0'
ORDER BY info.scheduled_date DESC;
