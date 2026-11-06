-- 各类手术信息明细（Presto）
-- 血缘：手排/手术申请主题-Plan_OPSSchedule.sql
--       OPMSApply + OPMSDictionaryManage(OpType) + OPMSRoomManage
--       + OPMSSchedule + OPClosedloopstate + CT_Loc/CT_CareProv/PA_Adm
--       + 手麻 sam_apply/sam_anar（实际开台结束，对不上就空）
-- 字典原名已在手排口径里出现：
--   心脏介入、外周介入、超声介入、病房日间、中心日间
-- 心导管室=心脏介入，介入手术室=外周介入，日间=病房日间+中心日间
-- 内镜中心、眼科门诊、膀胱镜、乳腺门诊、呼吸内镜：字典原名仓库没有
--   只在手术类型/手术间/楼栋/执行科室/申请科室名称包含时归类
-- 时间窗默认近 7 天，改 p_range 即可
-- 护士来自 OPMSSchedule，按手术间+排程日，不是每台手术各一套

WITH p_range AS (
    SELECT
        date_format(date_add('day', -7, current_date), '%Y-%m-%d') AS dt_start,
        date_format(date_add('day', 1, current_date), '%Y-%m-%d') AS dt_end
),

op_name_agg AS (
    SELECT
        apply.opms_rowid,
        array_join(array_distinct(array_agg(arc.ARCIM_Desc)), '；') AS operation_name
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApplyOrder apply
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSOrderManage manage
        ON manage.opms_rowid = apply.OrderMId
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.ARC_ItmMast arc
        ON manage.ARCIemID = arc.arcim_rowid
    GROUP BY apply.opms_rowid
),

sched AS (
    SELECT
        cast(s.oproomid AS varchar) AS room_id,
        substr(cast(s.useingdate AS varchar), 1, 10) AS use_dt,
        max(s.HocusDoc) AS hocus_doc,
        max(s.HocusDocAss) AS hocus_doc_ass,
        max(s.HocusDocAssOther) AS hocus_doc_ass_other,
        max(s.HandNurse1) AS hand_nurse_1,
        max(s.HandNurse2) AS hand_nurse_2,
        max(s.HandNurse3) AS hand_nurse_3,
        max(s.ItinerantNurse1) AS circuit_nurse_1,
        max(s.ItinerantNurse2) AS circuit_nurse_2,
        max(s.ItinerantNurse3) AS circuit_nurse_3
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSSchedule s
    GROUP BY
        cast(s.oproomid AS varchar),
        substr(cast(s.useingdate AS varchar), 1, 10)
),

loop_time AS (
    SELECT
        c.OPNO,
        max(CASE WHEN c.OPStatus = 'OPS' THEN substr(cast(c.opdate AS varchar), 1, 10) END) AS begin_date,
        max(CASE WHEN c.OPStatus = 'OPS' THEN cast(c.optime AS varchar) END) AS begin_time,
        max(CASE WHEN c.OPStatus = 'OPE' THEN substr(cast(c.opdate AS varchar), 1, 10) END) AS end_date,
        max(CASE WHEN c.OPStatus = 'OPE' THEN cast(c.optime AS varchar) END) AS end_time
    FROM hid0101_cache_his_dhcapp_userssgl.OPClosedloopstate c
    WHERE c.OPStatus IN ('OPS', 'OPE')
    GROUP BY c.OPNO
),

sam_time AS (
    SELECT
        sa.opa_no,
        max(ar.oper_beging_date) AS oper_begin,
        max(ar.oper_end_date) AS oper_end,
        max(ar.ana_beging_date) AS ana_begin,
        max(ar.ana_end_date) AS ana_end
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply sa
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
        ON ar.sam_apply_id = sa.id
       AND ar.isdeleted = '0'
    WHERE sa.isdeleted = '0'
    GROUP BY sa.opa_no
),

base AS (
    SELECT
        substr(cast(a.opdate AS varchar), 1, 10) AS schedule_date,
        a.OPNo AS op_no,
        a.OPMS_RowId AS apply_id,
        a.TC AS seq_no,
        a.patname AS pers_name,
        cast(a.Age AS varchar) AS age,
        adm.PAADM_ADMNo AS visit_no,
        applydpt.ctloc_desc AS apply_dept_name,
        execdpt.ctloc_desc AS exec_dept_name,
        trim(cast(opstype.SubDicName AS varchar)) AS ops_type_name,
        room.RoomName AS room_name,
        room.RoomCode AS room_code,
        building.SubDicName AS room_building,
        opdoc.CTPCP_Desc AS surgeon_name,
        assistantfirst.CTPCP_Desc AS assistant_1,
        assistantsecond.CTPCP_Desc AS assistant_2,
        assistantthird.CTPCP_Desc AS assistant_3,
        sched.hocus_doc_ass_other AS assistant_other,
        hocusmet.SubDicName AS narcosis_mode_name,
        sched.hocus_doc AS narcosis_doctor,
        sched.hocus_doc_ass AS narcosis_assistant,
        sched.hand_nurse_1,
        sched.hand_nurse_2,
        sched.hand_nurse_3,
        sched.circuit_nurse_1,
        sched.circuit_nurse_2,
        sched.circuit_nurse_3,
        ona.operation_name,
        loop_time.begin_date,
        loop_time.begin_time,
        loop_time.end_date,
        loop_time.end_time,
        sam_time.oper_begin,
        sam_time.oper_end,
        sam_time.ana_begin,
        sam_time.ana_end
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    LEFT JOIN op_name_agg ona
        ON ona.opms_rowid = a.OPMS_RowId
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.PA_Adm adm
        ON a.Paadm = adm.paadm_rowid
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_Loc applydpt
        ON applydpt.ctloc_rowid = a.ApplyDptID
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_Loc execdpt
        ON execdpt.ctloc_rowid = a.CTLocID
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDoctorManage doc
        ON doc.OPMS_RowId = a.OpDoc
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv opdoc
        ON opdoc.ctpcp_rowid = doc.DocID
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv assistantfirst
        ON assistantfirst.ctpcp_rowid = a.Ass1
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv assistantsecond
        ON assistantsecond.ctpcp_rowid = a.Ass2
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv assistantthird
        ON assistantthird.ctpcp_rowid = a.Ass3
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage hocusmet
        ON a.HocusMethos = hocusmet.opms_rowid
       AND coalesce(cast(hocusmet.isdeleted AS varchar), '0') = '0'
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opstype
        ON cast(a.OpType AS varchar) = cast(opstype.opms_rowid AS varchar)
       AND coalesce(cast(opstype.isdeleted AS varchar), '0') = '0'
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSRoomManage room
        ON a.OpRoomID = room.opms_rowid
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage building
        ON room.RoomBuilding = building.OPMS_RowId
       AND coalesce(cast(building.isdeleted AS varchar), '0') = '0'
    LEFT JOIN sched
        ON sched.room_id = cast(coalesce(a.oproomid, a.OpRoomID) AS varchar)
       AND sched.use_dt = substr(cast(a.opdate AS varchar), 1, 10)
    LEFT JOIN loop_time
        ON loop_time.OPNO = a.OPNo
    LEFT JOIN sam_time
        ON sam_time.opa_no = a.OPNo
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND a.patname NOT LIKE '%测试%'
      AND substr(cast(a.opdate AS varchar), 1, 10) >= (SELECT dt_start FROM p_range)
      AND substr(cast(a.opdate AS varchar), 1, 10) <  (SELECT dt_end FROM p_range)
      AND upper(trim(cast(a.prostatus AS varchar))) IN ('E', 'H', 'J', 'SZ', 'K', 'I', 'L')
),

typed AS (
    SELECT
        b.*,
        concat(
            coalesce(b.ops_type_name, ''), '|',
            coalesce(b.room_name, ''), '|',
            coalesce(b.room_building, ''), '|',
            coalesce(b.exec_dept_name, ''), '|',
            coalesce(b.apply_dept_name, '')
        ) AS loc_text
    FROM base b
)

SELECT
    t.schedule_date AS "排程日期",
    CASE
        WHEN t.loc_text LIKE '%呼吸内镜%' THEN '呼吸内镜中心手术/治疗'
        WHEN t.loc_text LIKE '%膀胱镜%' THEN '膀胱镜室手术/治疗'
        WHEN t.loc_text LIKE '%内镜%' THEN '内镜中心手术/治疗'
        WHEN t.loc_text LIKE '%眼科%' THEN '眼科门诊手术'
        WHEN t.loc_text LIKE '%乳腺%' THEN '乳腺门诊手术'
        WHEN t.ops_type_name = '超声介入' OR t.loc_text LIKE '%超声介入%' THEN '超声介入手术'
        WHEN t.ops_type_name = '心脏介入' OR t.loc_text LIKE '%心导管%' THEN '心导管室手术'
        WHEN t.ops_type_name = '外周介入' OR t.loc_text LIKE '%介入手术室%' THEN '介入手术室手术'
        WHEN t.ops_type_name IN ('病房日间', '中心日间') THEN '日间手术'
        ELSE '未归类'
    END AS "手术类别",
    CASE
        WHEN t.ops_type_name IN ('心脏介入', '外周介入', '超声介入', '病房日间', '中心日间') THEN '手术类型原名'
        ELSE '名称包含'
    END AS "归类依据",
    t.ops_type_name AS "手术类型",
    t.room_name AS "手术间",
    t.room_code AS "手术间代码",
    t.room_building AS "楼栋",
    t.exec_dept_name AS "执行科室",
    t.seq_no AS "台次",
    t.visit_no AS "就诊号",
    t.pers_name AS "患者",
    t.age AS "年龄",
    t.apply_dept_name AS "申请科室",
    t.operation_name AS "手术名称",
    t.surgeon_name AS "手术医生",
    t.assistant_1 AS "一助",
    t.assistant_2 AS "二助",
    t.assistant_3 AS "三助",
    t.assistant_other AS "其他助手",
    coalesce(
        nullif(trim(t.hand_nurse_1), ''),
        nullif(trim(t.hand_nurse_2), ''),
        nullif(trim(t.hand_nurse_3), '')
    ) AS "洗手护士",
    coalesce(
        nullif(trim(t.circuit_nurse_1), ''),
        nullif(trim(t.circuit_nurse_2), ''),
        nullif(trim(t.circuit_nurse_3), '')
    ) AS "巡回护士",
    t.narcosis_doctor AS "麻醉医生",
    t.narcosis_assistant AS "麻醉助手",
    t.narcosis_mode_name AS "麻醉方式",
    coalesce(
        nullif(trim(concat(coalesce(t.begin_date, ''), ' ', coalesce(t.begin_time, ''))), ''),
        t.oper_begin
    ) AS "手术开始",
    coalesce(
        nullif(trim(concat(coalesce(t.end_date, ''), ' ', coalesce(t.end_time, ''))), ''),
        t.oper_end
    ) AS "手术结束",
    t.ana_begin AS "麻醉开始",
    t.ana_end AS "麻醉结束",
    t.op_no AS "手术单号"
FROM typed t
WHERE
    t.ops_type_name IN ('心脏介入', '外周介入', '超声介入', '病房日间', '中心日间')
    OR t.loc_text LIKE '%心导管%'
    OR t.loc_text LIKE '%介入手术室%'
    OR t.loc_text LIKE '%超声介入%'
    OR t.loc_text LIKE '%呼吸内镜%'
    OR t.loc_text LIKE '%膀胱镜%'
    OR t.loc_text LIKE '%内镜%'
    OR t.loc_text LIKE '%眼科%'
    OR t.loc_text LIKE '%乳腺%'
ORDER BY
    "排程日期",
    "手术类别",
    "手术间",
    "台次";
