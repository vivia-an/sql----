-- 原始排程结果明细（HIS 手术管理 · 手术排程结果）
-- 血缘：手排/手术申请主题.sql → OPMSApply + OPMSSchedule + OPMSRoomManage + PA_Adm + OPMSApplyOrder
-- 时间窗：2019-08-01 ~ 2026-04-30（原需求写 2026.4.31，4 月无 31 日，故取 < 2026-05-01）
-- 粒度：每个手术间、每个排程日、每条手术申请（OPMSApply）一行
-- 说明：洗手/巡回/麻醉医护来自 OPMSSchedule，按「手术间+排程日」关联，与手术申请主题 SQL 一致

WITH p_range AS (
    SELECT
        '2019-08-01' AS dt_start,
        '2026-05-01' AS dt_end
),

-- 同一申请单下手术名称聚合
op_name_agg AS (
    SELECT
        apply.ApplyID,
        array_join(array_distinct(array_agg(arc.ARCIM_Desc)), '；') AS operation_name
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApplyOrder apply
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSOrderManage manage
        ON manage.opms_rowid = apply.OrderMId
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.ARC_ItmMast arc
        ON manage.ARCIemID = arc.arcim_rowid
    GROUP BY apply.ApplyID
),

base AS (
    SELECT
        a.OPMS_RowId,
        a.OPNo,
        a.opdate,
        a.TC,
        a.patname,
        a.Age,
        a.paadm,
        adm.PAADM_ADMNo AS visit_no,
        applydpt.ctloc_desc AS apply_dept_name,
        room.RoomName AS ops_room_name,
        room.RoomCode AS ops_room_code,
        opdoc.CTPCP_Desc AS operate_doct_name,
        assistantfirst.CTPCP_Desc AS assistant_first,
        assistantsecond.CTPCP_Desc AS assistant_second,
        assistantthird.CTPCP_Desc AS assistant_third,
        hocusmet.SubDicName AS narcosis_mode_name,
        s.HocusDoc AS narcosis_doct_name,
        s.HocusDocAss AS narcosis_assistant,
        s.HocusDocAssOther AS other_assistant,
        s.HandNurse1 AS scrub_nurse_1,
        s.HandNurse2 AS scrub_nurse_2,
        s.HandNurse3 AS scrub_nurse_3,
        s.ItinerantNurse1 AS circuit_nurse_1,
        s.ItinerantNurse2 AS circuit_nurse_2,
        s.ItinerantNurse3 AS circuit_nurse_3,
        ona.operation_name,
        confirmsche.opdate AS confirm_schedule_date,
        confirmsche.optime AS confirm_schedule_time
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSApplyOrder apply
        ON a.OPMS_RowId = apply.opms_rowid
    LEFT JOIN op_name_agg ona
        ON ona.ApplyID = apply.ApplyID
    LEFT JOIN (
        SELECT paadm_rowid, PAADM_ADMNo
        FROM hid0101_cache_his_dhcapp_sqluser.PA_Adm
    ) adm
        ON a.Paadm = adm.paadm_rowid
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_Loc applydpt
        ON applydpt.ctloc_rowid = a.ApplyDptID
    LEFT JOIN (
        SELECT OPMS_RowId, DocID
        FROM hid0101_cache_his_dhcapp_userssgl.OPMSDoctorManage
    ) doc
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
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSSchedule s
        ON cast(s.oproomid AS varchar) = cast(coalesce(a.oproomid, a.OpRoomID) AS varchar)
       AND substr(cast(s.useingdate AS varchar), 1, 10) = substr(cast(a.opdate AS varchar), 1, 10)
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSRoomManage room
        ON a.OpRoomID = room.opms_rowid
    LEFT JOIN (
        SELECT OPNO, opdate, optime
        FROM hid0101_cache_his_dhcapp_userssgl.OPClosedloopstate
        WHERE OPStatus = 'H'
    ) confirmsche
        ON confirmsche.OPNO = a.OPNo
    WHERE coalesce(a.isdeleted, '0') = '0'
      AND a.patname NOT LIKE '%测试%'
      AND substr(cast(a.opdate AS varchar), 1, 10) >= (SELECT dt_start FROM p_range)
      AND substr(cast(a.opdate AS varchar), 1, 10) <  (SELECT dt_end   FROM p_range)
      -- 与手术申请主题一致：已排程/确认类状态；若需全量原始排程可注释本行
      AND a.prostatus IN ('H', 'J', 'K', 'I', 'L')
)

SELECT
    cast(substr(cast(b.opdate AS varchar), 1, 10) AS varchar) AS "排程日期",
    b.ops_room_name                                          AS "手术间",
    b.TC                                                     AS "台次",
    row_number() OVER (
        PARTITION BY substr(cast(b.opdate AS varchar), 1, 10), b.ops_room_name
        ORDER BY
            try_cast(b.TC AS integer),
            b.OPNo,
            b.OPMS_RowId
    )                                                        AS "序号",
    coalesce(
        nullif(trim(b.confirm_schedule_time), ''),
        substr(cast(b.opdate AS varchar), 1, 10)
    )                                                        AS "时间",
    b.visit_no                                               AS "住院号",
    b.apply_dept_name                                        AS "申请科室",
    b.patname                                                AS "姓名",
    cast(b.Age AS varchar)                                   AS "年龄",
    b.operate_doct_name                                      AS "主刀医生",
    b.narcosis_doct_name                                     AS "麻醉医生",
    b.narcosis_mode_name                                     AS "麻醉方式",
    b.operation_name                                         AS "手术名称",
    b.assistant_first                                        AS "一助",
    b.assistant_second                                       AS "二助",
    b.assistant_third                                        AS "三助",
    b.other_assistant                                        AS "其他助手",
    coalesce(
        nullif(trim(b.scrub_nurse_1), ''),
        nullif(trim(b.scrub_nurse_2), ''),
        nullif(trim(b.scrub_nurse_3), '')
    )                                                        AS "洗手护士",
    coalesce(
        nullif(trim(b.circuit_nurse_1), ''),
        nullif(trim(b.circuit_nurse_2), ''),
        nullif(trim(b.circuit_nurse_3), '')
    )                                                        AS "巡回护士",
    b.narcosis_assistant                                     AS "麻醉助手",
    b.OPNo                                                   AS "手术单号",
    b.ops_room_code                                          AS "手术间代码"
FROM base b
ORDER BY
    "排程日期",
    "手术间",
    "序号";

-- 字段血缘摘要：
-- 手术间/台次/姓名/年龄/申请科室/一助二助三助/主刀/麻醉方式  ← OPMSApply + CT_Loc/CT_CareProv/OPMSDoctorManage
-- 洗手/巡回/麻醉医生/麻醉助手/其他助手                      ← OPMSSchedule（按手术间+排程日关联）
-- 手术名称                                                  ← OPMSApplyOrder → OPMSOrderManage → ARC_ItmMast
-- 住院号                                                    ← PA_Adm.PAADM_ADMNo
-- 时间                                                      ← OPClosedloopstate(OPStatus='H') 优先，否则排程日期
--
-- 异常血缘：
-- 1) OPMSSchedule 仅按「手术间+日期」关联，医护为当日手术间排班，不一定逐台手术一一对应
-- 2) 洗手/巡回护士若需分别展示 1/2/3，可改 SELECT 为三列 HandNurse1~3 / ItinerantNurse1~3
-- 3) 若环境无 OPMS cache 表，可改用 datacenter_db.Plan_OPSSchedule（见同目录备选 SQL）
