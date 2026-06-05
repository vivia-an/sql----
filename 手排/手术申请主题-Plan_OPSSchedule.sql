select
distinct
  cast(a.Age as varchar) as age,
  cast(applydpt.ctloc_code as varchar) as applydeptcode,
  cast(applydpt.ctloc_desc as varchar) as applydeptdesc,
  cast(ss_user.ssusr_name as varchar) as applyperson,
  cast(ss_user.ssusr_initials as varchar) as applypersoncode,
  cast(b.ARCIM_Desc as varchar) as arcim_desc,
  cast(b.arcim_rowid as varchar) as arcim_rowid,
  cast(assistantfirst.CTPCP_Code as varchar) as assistantfirstcode,
  cast(assistantfirst.CTPCP_Desc as varchar) as assistantfirstname,
  cast(assistantsecond.CTPCP_Code as varchar) as assistantsecondcode,
  cast(assistantsecond.CTPCP_Desc as varchar) as assistantsecondname,
  cast(assistantthird.CTPCP_Code as varchar) as assistantthirdcode,
  cast(assistantthird.CTPCP_Desc as varchar) as assistantthirdname,
  cast(a.bedno as varchar) as bedno,
  cast(a.BloodABO as varchar) as bloodabo,
  cast(a.BloodHBS as varchar) as bloodhbs,
  cast(a.BloodHCV as varchar) as bloodhcv,
  cast(a.BloodHIV as varchar) as bloodhiv,
  cast(a.BloodPrepare as varchar) as bloodprepare,
  cast(a.BloodRH as varchar) as bloodrh,
  cast(a.BloodSYP as varchar) as bloodsyp,
  cast(a.BodyBlood as varchar) as bodyblood,
  cast(a.BodyCircule as varchar) as bodycircule,
  a.opdate as bookingopdate,
  Confirmdoccode.OPUser as confirmdoccode,
  confirmschedate.opdate as confirmschedate,
  confirmschedate.optime as confirmschetime,
  cast(ctloc.ctloc_code as varchar) as ctloccode,
  cast(ctloc.ctloc_desc as varchar) as ctlocdesc,
  current_timestamp as datacreatedttm,
  cast('4' as varchar) as datasourceflag,
  cast(
    'hid0101_cache_his_dhcapp_userssgl.opmsapply' as varchar
  ) as dstable,
  cast('opms_rowid' as varchar) as dstablekey,
  cast(a.rowkey as varchar) as dstablevalue,
  cast(null as varchar) as extdate1,
  cast(null as varchar) as extdate2,
  cast(null as varchar) as extnum1,
  cast(null as varchar) as extnum2,
  cast(a.rjroomid as varchar) as extstr1,
  cast(a.OPNo as varchar) as extstr2,
  cast(a.paadm as varchar) as extstr3,
  cast(null as varchar) as extstr4,
  cast(null as varchar) as extstr5,
  cast(null as varchar) as extstr6,
  cast(s.HandNurse1 as varchar) as handnurse1,
  cast(s.HandNurse2 as varchar) as handnurse2,
  cast(s.HandNurse3 as varchar) as handnurse3,
  cast(s.HocusDoc as varchar) as hocusdoc,
  cast(s.HocusDocAss as varchar) as hocusdocass,
  cast(s.HocusDocAssOther as varchar) as hocusdocassother,
  cast(hocusmet.SubDicName as varchar) as hocusmethos,
  cast(b.IncisionType as varchar) as incisiontype,
  a.isdeleted as isdeleted,
  cast(a.IsHocus as varchar) as ishocus,
  cast(s.ItinerantNurse1 as varchar) as itinerantnurse1,
  cast(s.ItinerantNurse2 as varchar) as itinerantnurse2,
  cast(s.ItinerantNurse3 as varchar) as itinerantnurse3,
  current_timestamp as lastupdatedttm,
  cast('HID0101' as varchar) as medorgcode,
  cast('四川大学华西医院' as varchar) as medorgname,
  opbegindate.opdate as opbegindate,
  opbegindate.optime as opbegintime,
  openddate.opdate as openddate,
  openddate.optime as opendtime,
  cast(a.OpBloodNote as varchar) as opbloodnote,
  cast(opbody.SubDicName as varchar) as opbody,
  cast(a.OpDiagnose as varchar) as opdiagnose,
  cast(opdoc.CTPCP_Code as varchar) as opdoccode,
  cast(opdoc.CTPCP_Desc as varchar) as opdocname,
  cast(a.OPDuration as varchar) as opduration,
  cast(a.OPMS_RowId as varchar) as opms_rowid,
  a.OPNo as opno,
  cast(OpPosition.SubDicName as varchar) as opposition,
  cast(a.OPRepeat as varchar) as oprepeat,
  cast(coalesce(mdm.visit_id, '-1') as varchar) as ops_apply_visitid,
  cast(b.opslevel as varchar) as opslevel,
  cast(room.RoomName as varchar) as opsroom,
  cast(room.RoomCode as varchar) as opsroomcode,
  cast(opstype.SubDicName as varchar) as opstype,
  cast(a.patname as varchar) as patname,
  cast(pmi.PAPMI_RowId as varchar) as persid,
  cast(a.regno as varchar) as persno,
  cast(a.prostatus as varchar) as prostatus,
  cast(b.QKNUM as varchar) as qknum,
  cast(a.Quarantine as varchar) as quarantine,
  cast(dic.SubDicName as varchar) as roombuilding,
  cast(roomfloor.SubDicName as varchar) as roomfloor,
  cast(concat('1_5_2_opmsapply_', a.rowkey) as varchar) as rowkey,
  cast(a.Sex as varchar) as sex,
  cast(StopReason.SubDicName as varchar) as stopreason,
  cast(a.TC as varchar) as tc,
  cast(a.paadm as varchar) as visitid,
  cast(adm.PAADM_ADMNo as varchar) as visitno,
  cast(ward.WARD_Code as varchar) as wardcode,
  cast(ward.WARD_Desc as varchar) as wardname,
  coalesce(opbegindate.opdate,substring(sam_anar.oper_beging_date,1,10)) as opbegindate,
  coalesce(opbegindate.optime,substring(sam_anar.oper_beging_date,12)) as opbegintime,
  coalesce(openddate.opdate,substring(sam_anar.oper_end_date,1,10)) as openddate,
  coalesce(openddate.optime, substring(sam_anar.oper_end_date,12)) as opendtime
from
hid0101_cache_his_dhcapp_userssgl.OPMSApplyOrder apply
left join hid0101_cache_his_dhcapp_userssgl.OPMSApply as a on a.OPMS_RowId = apply.opms_rowid
left join (
select
paadm_rowid,
 PAADM_ADMNo
    from
      hid0101_cache_his_dhcapp_sqluser.PA_Adm
  ) as adm on a.Paadm = adm.paadm_rowid
  left join (
    select
      PAPMI_No,
      PAPMI_RowId
    from
      hid0101_cache_his_dhcapp_sqluser.PA_PatMas
  ) as pmi on a.RegNo = pmi.PAPMI_No
  left join (
    select
      OPMS_RowId,
      DocID
    from
      hid0101_cache_his_dhcapp_userssgl.OPMSDoctorManage
  ) as doc on doc.OPMS_RowId = a.OpDoc
  left join (
    select
      ApplyID,
      array_join(array_distinct(array_agg(arc.arcim_rowid)), ',') as arcim_rowid,
      array_join(array_distinct(array_agg(arc.ARCIM_Desc)), ',') as arcim_desc,
      array_join(
        array_distinct(array_agg(opslevel.SubDicName)),
        ','
      ) as opslevel,
      array_join(array_distinct(array_agg(manage.QKNUM)), ',') as QKNUM,
      array_join(
        array_distinct(array_agg(IncisionType.SubDicName)),
        ','
      ) as IncisionType
    from
      hid0101_cache_his_dhcapp_userssgl.OPMSApplyOrder apply
      left join hid0101_cache_his_dhcapp_userssgl.OPMSOrderManage manage on manage.opms_rowid = apply.OrderMId
      left join hid0101_cache_his_dhcapp_sqluser.ARC_ItmMast arc on manage.ARCIemID = arc.arcim_rowid
      left join hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opslevel on opslevel.opms_rowid = manage.OPLevel
      left join hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage IncisionType on IncisionType.opms_rowid = manage.IncisionType
    group by
      ApplyID
  ) as b on b.ApplyID = apply.ApplyID
  left join hid0101_cache_his_dhcapp_userssgl.OPMSSchedule as s on s.oproomid = a.oproomid
  and s.useingdate = a.opdate
  left join (
    select
      ward_rowid,
      WARD_Code,
      WARD_Desc
    from
      hid0101_cache_his_dhcapp_sqluser.pac_ward
  ) as ward on ward_rowid = a.wordid
  left join hid0101_cache_his_dhcapp_sqluser.CT_Loc as ctloc on ctloc.ctloc_rowid = a.CTLocID
  left join hid0101_cache_his_dhcapp_sqluser.CT_Loc as applydpt on applydpt.ctloc_rowid = a.ApplyDptID
  left join hid0101_cache_his_dhcapp_sqluser.ss_user as ss_user on ss_user.ssusr_rowid = a.ApplyPerson
  left join hid0101_cache_his_dhcapp_sqluser.CT_CareProv as opdoc on opdoc.ctpcp_rowid = doc.DocID
  left join hid0101_cache_his_dhcapp_sqluser.CT_CareProv as assistantfirst on assistantfirst.ctpcp_rowid = a.Ass1
  left join hid0101_cache_his_dhcapp_sqluser.CT_CareProv as assistantsecond on assistantsecond.ctpcp_rowid = a.Ass2
  left join hid0101_cache_his_dhcapp_sqluser.CT_CareProv as assistantthird on assistantthird.ctpcp_rowid = a.Ass3
  left join hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage as hocusmet on a.HocusMethos = hocusmet.opms_rowid
  left join hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage as opstype on a.OpType = opstype.opms_rowid
  left join hid0101_cache_his_dhcapp_userssgl.OPMSRoomManage as room on a.OpRoomID = room.opms_rowid
  left join hid0101_cache_his_dhcapp_userssgl.OPMSRoomManage as room01 on a.OpRoomID = room01.opms_rowid
  left join hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage as dic on room01.RoomBuilding = dic.OPMS_RowId
  left join hid0101_cache_his_dhcapp_userssgl.OPMSRoomManage as room02 on a.OpRoomID = room02.opms_rowid
  left join hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage as roomfloor on room02.Roomfloor = roomfloor.OPMS_RowId
  left join (
    select
      OPNO,
      OPStatus,
      opdate,
      optime
    from
      hid0101_cache_his_dhcapp_userssgl.OPClosedloopstate
  ) as confirmschedate on confirmschedate.OPNO = a.OPNo
  and confirmschedate.OPStatus = 'H'
  left join (
    select
      OPNO,
      OPStatus,
      OPUser
    from
      hid0101_cache_his_dhcapp_userssgl.OPClosedloopstate
  ) as Confirmdoccode on Confirmdoccode.OPNO = a.OPNo
  and Confirmdoccode.OPStatus = 'C'
  left join (
    select
      OPNO,
      OPStatus,
      opdate,
      optime
    from
      hid0101_cache_his_dhcapp_userssgl.OPClosedloopstate
  ) as opbegindate on opbegindate.OPNO = a.OPNo
  and opbegindate.OPStatus = 'OPS'
 
  left join (
    select
      OPNO,
      OPStatus,
      opdate,
      optime
    from
      hid0101_cache_his_dhcapp_userssgl.OPClosedloopstate
  ) as openddate on openddate.OPNO = a.OPNo
  and openddate.OPStatus = 'OPE'
  
  
  left join (
    select
      OPMS_RowId,
      array_join(array_distinct(array_agg(SubDicName)), ',') as SubDicName
    from
      hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage
    group by
      OPMS_RowId
  ) as opbody on opbody.OPMS_RowId = a.OpBody
  left join (
    select
      OPMS_RowId,
      array_join(array_distinct(array_agg(SubDicName)), ',') as SubDicName
    from
      hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage
    group by
      OPMS_RowId
  ) as opposition on opposition.OPMS_RowId = a.OpPosition
  left join hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage as StopReason on StopReason.OPMS_RowId = a.StopReason
  left join (
    select
      visit_no,
      system_source,
      visit_id
    from
      ddm.mdm_patientvisitkey
    where
      system_source = '2'
  ) as mdm on a.paadm = mdm.visit_no
  and system_source = '2'
 left join  hid0101_orcl_operaanesthisa_emrhis.sam_apply sam_apply on sam_apply.opa_no = a.OPNo
 left join hid0101_orcl_operaanesthisa_emrhis.sam_anar sam_anar on sam_anar.sam_apply_id = sam_apply.id
 
 
where
  patName not like '%测试%'
  and prostatus in ('H', 'J', 'K', 'I', 'L')