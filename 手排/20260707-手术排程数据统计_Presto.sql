-- 手术排程数据统计（全字段 · Excel/LOG 35 列对齐）
-- 血缘：手排/20260707-手术排程数据统计.LOG|csv → 手排/手术申请主题-Plan_OPSSchedule.sql
-- 对比：手排/原始排程结果_20190801-20260430_Presto.sql（仅 20 列，缺备血/诊断/状态/病区/体位等）
-- 粒度：每条手术申请（OPMSApply）一行，与 LOG/原始排程 SQL 一致
-- 时间窗：2019-08-01 ~ 2026-04-30（与原始排程 SQL 一致；按需改 p_range）
-- 输出列序与 Excel 中文表头一致，便于对账导出

WITH p_range AS (
    SELECT
        '2026-05-01' AS dt_start,
        '2026-06-31' AS dt_end
),

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

-- 同一 OPMSApply 多 order 时取一条关联（优先 ApplyID=opms_rowid），保持一行一申请
apply_one AS (
    SELECT opms_rowid, ApplyID
    FROM (
        SELECT
            apply.opms_rowid,
            apply.ApplyID,
            row_number() OVER (
                PARTITION BY apply.opms_rowid
                ORDER BY
                    CASE WHEN apply.ApplyID = apply.opms_rowid THEN 0 ELSE 1 END,
                    apply.ApplyID
            ) AS rn
        FROM hid0101_cache_his_dhcapp_userssgl.OPMSApplyOrder apply
    ) t
    WHERE rn = 1
),

base AS (
    SELECT
        a.OPMS_RowId,
        a.OPNo,
        cast(room.opms_rowid AS varchar)              AS room_id,
        room.RoomCode                                 AS room_code,
        room.RoomName                                 AS room_desc,
        a.TC,
        coalesce(
            nullif(trim(bodyblood_dict.SubDicName), ''),
            nullif(trim(cast(a.BodyBlood AS varchar)), ''),
            nullif(trim(cast(a.BloodPrepare AS varchar)), ''),
            nullif(trim(cast(a.OpBloodNote AS varchar)), ''),
            '不详'
        )                                             AS blood_info,
        substr(cast(a.opdate AS varchar), 1, 10)      AS op_date,
        a.regno,
        coalesce(
            nullif(trim(loc_ct.ctloc_desc), ''),
            nullif(trim(ward_ct.ctloc_desc), '')
        )                                             AS loc_desc,
        a.bedno,
        a.patname,
        a.Sex,
        a.Age,
        a.OpDiagnose,
        ona.operation_name,
        CASE
            WHEN nullif(trim(opbody.SubDicName), '') IS NOT NULL
             AND nullif(trim(cast(a.OpBloodNote AS varchar)), '') IS NOT NULL
             AND nullif(trim(cast(a.Quarantine AS varchar)), '') IS NOT NULL
                THEN concat(
                    nullif(trim(opbody.SubDicName), ''),
                    ',',
                    nullif(trim(cast(a.OpBloodNote AS varchar)), ''),
                    ',',
                    nullif(trim(cast(a.Quarantine AS varchar)), '')
                )
            WHEN nullif(trim(opbody.SubDicName), '') IS NOT NULL
             AND nullif(trim(cast(a.OpBloodNote AS varchar)), '') IS NOT NULL
                THEN concat(
                    nullif(trim(opbody.SubDicName), ''),
                    ',',
                    nullif(trim(cast(a.OpBloodNote AS varchar)), '')
                )
            WHEN nullif(trim(opbody.SubDicName), '') IS NOT NULL
             AND nullif(trim(cast(a.Quarantine AS varchar)), '') IS NOT NULL
                THEN concat(
                    nullif(trim(opbody.SubDicName), ''),
                    ',',
                    nullif(trim(cast(a.Quarantine AS varchar)), '')
                )
            WHEN nullif(trim(cast(a.OpBloodNote AS varchar)), '') IS NOT NULL
             AND nullif(trim(cast(a.Quarantine AS varchar)), '') IS NOT NULL
                THEN concat(
                    nullif(trim(cast(a.OpBloodNote AS varchar)), ''),
                    ',',
                    nullif(trim(cast(a.Quarantine AS varchar)), '')
                )
            ELSE coalesce(
                nullif(trim(opbody.SubDicName), ''),
                nullif(trim(cast(a.OpBloodNote AS varchar)), ''),
                nullif(trim(cast(a.Quarantine AS varchar)), '')
            )
        END                                             AS op_tsxq,
        coalesce(
            nullif(trim(opdoc.CTPCP_Desc), ''),
            nullif(trim(opdoc_direct.CTPCP_Desc), '')
        )                                             AS doc_desc,
        assistantfirst.CTPCP_Desc                     AS ass1,
        assistantsecond.CTPCP_Desc                    AS ass2,
        assistantthird.CTPCP_Desc                     AS ass3,
        hocusmet.SubDicName                           AS hocus_methos,
        coalesce(
            nullif(trim(s.HandNurse1), ''),
            nullif(trim(s.HandNurse2), ''),
            nullif(trim(s.HandNurse3), '')
        )                                             AS hand_nurse,
        coalesce(
            nullif(trim(s.ItinerantNurse1), ''),
            nullif(trim(s.ItinerantNurse2), ''),
            nullif(trim(s.ItinerantNurse3), '')
        )                                             AS itinerant_nurse,
        CASE a.prostatus
            WHEN 'H' THEN '已排程'
            WHEN 'J' THEN '已排程'
            WHEN 'K' THEN '已排程'
            WHEN 'I' THEN '已排程'
            WHEN 'L' THEN '已排程'
            ELSE cast(a.prostatus AS varchar)
        END                                           AS op_status,
        StopReason.SubDicName                         AS undo_reason,
        a.TC                                          AS tc_raw,
        room.RoomCode                                 AS room_code_raw,
        ward_ct.ctloc_code                            AS ward_code,
        concat(
            '(',
            coalesce(cast(ward_ct.ctloc_code AS varchar), ''),
            ')',
            coalesce(ward_ct.ctloc_desc, '')
        )                                             AS adm_dpt,
        opstype.SubDicName                            AS op_type,
        s.HocusDoc                                    AS hocus_doc,
        s.HocusDocAss                                 AS hocus_doc_ass,
        s.HocusDocAssOther                            AS ass_other,
        cast(pmi.PAPMI_MobPhone AS varchar)           AS phone,
        CASE
            WHEN try_cast(substr(coalesce(confirmsche.optime, ''), 1, 2) AS integer) >= 12 THEN '下午'
            WHEN coalesce(trim(confirmsche.optime), '') <> '' THEN '上午'
            ELSE NULL
        END                                           AS atf_flag,
        CASE
            WHEN adm.PAADM_DischgDate IS NOT NULL
             AND trim(cast(adm.PAADM_DischgDate AS varchar)) NOT IN ('', '1899-12-30', '0000-00-00')
            THEN '出院'
            WHEN adm.paadm_rowid IS NOT NULL THEN '在院'
            ELSE NULL
        END                                           AS pat_status,
        opposition.SubDicName                         AS op_position
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    LEFT JOIN apply_one apply
        ON a.OPMS_RowId = apply.opms_rowid
    LEFT JOIN op_name_agg ona
        ON ona.ApplyID = apply.ApplyID
    LEFT JOIN (
        SELECT paadm_rowid, PAADM_ADMNo, PAADM_DischgDate
        FROM hid0101_cache_his_dhcapp_sqluser.PA_Adm
    ) adm
        ON a.Paadm = adm.paadm_rowid
    LEFT JOIN (
        SELECT PAPMI_No, PAPMI_MobPhone
        FROM hid0101_cache_his_dhcapp_sqluser.PA_PatMas
    ) pmi
        ON a.RegNo = pmi.PAPMI_No
    LEFT JOIN (
        SELECT OPMS_RowId, DocID
        FROM hid0101_cache_his_dhcapp_userssgl.OPMSDoctorManage
    ) doc
        ON doc.OPMS_RowId = a.OpDoc
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv opdoc
        ON opdoc.ctpcp_rowid = doc.DocID
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv opdoc_direct
        ON opdoc_direct.ctpcp_rowid = a.OpDoc
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv assistantfirst
        ON assistantfirst.ctpcp_rowid = a.Ass1
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv assistantsecond
        ON assistantsecond.ctpcp_rowid = a.Ass2
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_CareProv assistantthird
        ON assistantthird.ctpcp_rowid = a.Ass3
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage hocusmet
        ON a.HocusMethos = hocusmet.opms_rowid
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opstype
        ON a.OpType = opstype.opms_rowid
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage bodyblood_dict
        ON bodyblood_dict.OPMS_RowId = a.BodyBlood
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage StopReason
        ON StopReason.OPMS_RowId = a.StopReason
    LEFT JOIN (
        SELECT
            OPMS_RowId,
            array_join(array_distinct(array_agg(SubDicName)), ',') AS SubDicName
        FROM hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage
        GROUP BY OPMS_RowId
    ) opbody
        ON opbody.OPMS_RowId = a.OpBody
    LEFT JOIN (
        SELECT
            OPMS_RowId,
            array_join(array_distinct(array_agg(SubDicName)), ',') AS SubDicName
        FROM hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage
        GROUP BY OPMS_RowId
    ) opposition
        ON opposition.OPMS_RowId = a.OpPosition
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSSchedule s
        ON cast(s.oproomid AS varchar) = cast(coalesce(a.oproomid, a.OpRoomID) AS varchar)
       AND substr(cast(s.useingdate AS varchar), 1, 10) = substr(cast(a.opdate AS varchar), 1, 10)
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSRoomManage room
        ON a.OpRoomID = room.opms_rowid
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_Loc loc_ct
        ON cast(loc_ct.ctloc_rowid AS varchar) = cast(a.CTLocID AS varchar)
    LEFT JOIN hid0101_cache_his_dhcapp_sqluser.CT_Loc ward_ct
        ON cast(ward_ct.ctloc_rowid AS varchar) = cast(a.wordid AS varchar)
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
      AND a.prostatus IN ('H', 'J', 'K', 'I', 'L')
)

SELECT
    cast(b.OPMS_RowId AS varchar)                      AS "手术申请单ID",
    b.room_id                                            AS "手术间内部ID",
    b.room_code                                          AS "手术间代码",
    b.room_desc                                          AS "手术间名称",
    cast(b.TC AS varchar)                                AS "台次",
    b.blood_info                                         AS "备血情况",
    b.op_date                                            AS "排程日期",
    cast(b.regno AS varchar)                             AS "登记号",
    b.loc_desc                                           AS "当前所在科室",
    CASE
        WHEN coalesce(trim(cast(b.bedno AS varchar)), '') = '' THEN NULL
        WHEN strpos(cast(b.bedno AS varchar), '床') > 0 THEN cast(b.bedno AS varchar)
        ELSE concat(cast(b.bedno AS varchar), '床')
    END                                                  AS "床号",
    b.patname                                            AS "患者姓名",
    cast(b.Sex AS varchar)                               AS "性别",
    CASE
        WHEN strpos(cast(b.Age AS varchar), '岁') > 0 THEN cast(b.Age AS varchar)
        ELSE concat(cast(b.Age AS varchar), '岁')
    END                                                  AS "年龄",
    cast(b.OpDiagnose AS varchar)                        AS "术前诊断",
    b.operation_name                                     AS "手术名称",
    b.op_tsxq                                            AS "手术部位/特殊要求",
    b.doc_desc                                           AS "主刀医生",
    b.ass1                                               AS "第一助手",
    b.ass2                                               AS "第二助手",
    b.ass3                                               AS "第三助手",
    b.hocus_methos                                       AS "麻醉方式",
    b.hand_nurse                                         AS "洗手护士",
    b.itinerant_nurse                                    AS "巡回护士",
    b.op_status                                          AS "排程状态",
    b.undo_reason                                        AS "取消/停止原因",
    CASE
        WHEN strpos(coalesce(trim(cast(b.tc_raw AS varchar)), ''), '-') > 0
            THEN trim(cast(b.tc_raw AS varchar))
        ELSE concat(
            coalesce(
                nullif(regexp_replace(element_at(split(b.room_code_raw, '-'), -1), '^0+', ''), ''),
                cast(b.ward_code AS varchar)
            ),
            '-',
            coalesce(nullif(trim(cast(b.tc_raw AS varchar)), ''), '1')
        )
    END                                                  AS "排程显示序号",
    b.adm_dpt                                            AS "护理单元/病区",
    b.op_type                                            AS "手术类型",
    b.hocus_doc                                          AS "麻醉医生",
    b.hocus_doc_ass                                      AS "麻醉助手",
    b.ass_other                                          AS "其他助手",
    b.phone                                              AS "联系电话",
    b.atf_flag                                           AS "时段标识",
    b.pat_status                                         AS "病人状态",
    b.op_position                                        AS "手术体位"
FROM base b
ORDER BY
    b.op_date,
    b.room_desc,
    try_cast(b.TC AS integer),
    b.OPMS_RowId;

-- =============================================================================
-- 字段血缘（LOG 英文字段 → 本 SQL 中文列）
-- =============================================================================
-- ApplyID      → OPMSApply.OPMS_RowId（LOG 列名 ApplyID，导出按申请主表主键）
-- RoomId       → OPMSRoomManage.opms_rowid
-- RoomCode/Desc→ OPMSRoomManage.RoomCode/RoomName
-- TC           → OPMSApply.TC
-- Blood        → BodyBlood字典 + BodyBlood/BloodPrepare/OpBloodNote
-- OpDate       → OPMSApply.opdate
-- RegNo        → OPMSApply.regno（登记号，非住院号）
-- LocDesc      → CTLocID→CT_Loc 优先；否则 wordid→CT_Loc（病区）
-- BedNo        → OPMSApply.bedno
-- PatName/Sex/Age → OPMSApply
-- Diagnose     → OPMSApply.OpDiagnose
-- OpName       → OPMSApplyOrder(apply.opms_rowid=OPMS_RowId).ApplyID → OPMSOrderManage → ARC_ItmMast（与原始排程一致）
-- OpTSXQ       → OpBody字典 + OpBloodNote + Quarantine
-- DocDesc      → OpDoc→OPMSDoctorManage→CT_CareProv；兜底 OpDoc 直连 CT_CareProv（与原始排程/手术申请主题一致，无 cast）
-- Ass1~3       → Ass1/2/3→CT_CareProv.CTPCP_Desc
-- HocusMethos  → OPMSDictionaryManage（麻醉方式）
-- HandNurse/ItinerantNurse → OPMSSchedule（按手术间+排程日）
-- OpStatus     → OPMSApply.prostatus 映射
-- UnDoReason   → StopReason 字典
-- SSLocNo      → 近似：TC 含 '-' 时取 TC，否则 术间号-台次（见异常血缘）
-- AdmDpt       → wordid→CT_Loc 拼 (代码)名称（非 pac_ward；cache 无 AdmDpt 直出列）
-- OPType       → OpType 字典
-- HocusDoc/Ass/AssOther → OPMSSchedule
-- phone        → PA_PatMas.PAPMI_MobPhone
-- atfFlag      → OPClosedloopstate 确认时间推导上午/下午
-- PatStatus    → PA_Adm.PAADM_DischgDate 推导出院/在院
-- OpPosition   → OpPosition 字典
--
-- 异常血缘：
-- 1) OPMSSchedule 按「手术间+日期」关联，洗手/巡回/麻醉为当日术间排班，非逐台一一对应
-- 2) 排程显示序号（SSLocNo）导出程序规则未在 HIS 表中找到直出字段，本 SQL 为近似推导
-- 3) 时段标识（atfFlag）LOG 大量为空，仅在有确认排程时间时可推导
-- 4) 联系电话偶发填人名，源表 PAPMI_MobPhone 需数据质量校验
-- 5) 护理单元 wordid 在医嘱等主题中指向 CT_Loc 病区，非 pac_ward（已修正）
-- 6) cache 表无 LocDesc/DocDesc/AdmDpt 直出列，LOG 列名仅为导出别名
