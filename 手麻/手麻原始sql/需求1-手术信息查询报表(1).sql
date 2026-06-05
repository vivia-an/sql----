SELECT
    ieg.ipno 病案号,
    nvl(ieg.ipi_registration_no,opc.opc_registration_no) 登记号,
    info.patient_Name 姓名,
    xb.s_xb_cmc 性别,
    info.birthday 出生日期,
    ar.height 身高,
    ar.weight 体重,
    (case when info.is_emergency='1' then '急诊' else '择期' end ) 手术类别,
     (case when info.is_daytime='1' then '是' else '否' end ) 是否日间手术,   
    mzfs.mzfsCmc 麻醉方式,
    info.asadm ASA分级,
    '' 急诊手术分级,
    (rank() over(partition by info.room_id,info.scheduled_date order by info.in_oproom_date, info.oper_beging_date)) 台次,
   '' 首台,
   '' 末台,
   '' 周末,
   dpt.department_chinese_name 患者所在科室,
   docdept.department_chinese_name 手术医生科室,
   info.schedate 手术安排日期,
   rm.oper_room 手术间,
   rm.building||rm.floor 手术间位置,
   info.main_diag 术前诊断,
   info.operName 手术名称,
   hzqx.tw_place 术后运转地点,
   info.qkdj 切口等级,
   mzem.employee_name  麻醉医生,
   mzem.id 麻醉医生工号,
   mzem1.employee_name 麻醉助手1,
   mzem1.id 麻醉助手1工号,
  mzem2.employee_name 麻醉助手2,
  mzem2.employee_name 麻醉助手2工号,
  
  xhdoc1.employee_name 巡回护士1,
  xhdoc1.id 巡回护士1工号,
  
  xhdoc2.employee_name 巡回护士2,
  xhdoc2.id 巡回护士2工号,
  
  xsdoc1.employee_name 洗手护士1,
  xsdoc1.id 洗手护士1工号,
  
  xsdoc2.employee_name 洗手护士2,
  xsdoc2.id 洗手护士2工号,
  
  ssem.employee_name  手术医生,
  ssem.id  手术医生工号,
  
  ssem1.employee_name 手术助手1,
  ssem1.id 手术助手1工号,
  
  ssem2.employee_name 手术助手2,
  ssem2.id 手术助手2工号,
  
  docdept.department_chinese_name 医生科室,
  ROUND((nvl(info.oper_end_date, sysdate) - info.oper_beging_date) * 24, 2) 手术时长,
  cbu_jie.realname "接单人（接）",
  pso_jie.send_order_time "派单时间（接）",
  pso_jie.ORDER_RECEIVING_TIME "接单时间（接）",
  pso_jie.START_PLACE_ARRIVE_TIME "到达出发地时间（接）",
  pso_jie.SEND_ORDER_ARRIVE_TIME "接到患者时间（接）",
  '' "到达手术室时间（接）",
  pso_jie.BURGLARY_TIME "到达手术间时间（接）",
  pso_jie.SEND_ORDER_FINISH_TIME "完成订单时间（接）",
    info.oper_beging_date 手术开始,
    info.oper_end_date 手术结束,
    info.ana_beging_date 麻醉开始,
    info.ana_end_date 麻醉结束,
    info.in_oproom_date 进手术间,
    info.out_oproom_date 出手术间,
    '' 建立人工气道,
    '' 拆除人工气道,
    info.oper_time 手术预计时长,
    info.blood_loss 预估出血量,
    xueinfo.clsingledose 实际出血量,
    info.rec_in_date 到达PACU时间,
    info.rec_out_date 出PACU时间,
    cbu_song.realname "接单人（送）",
    pso_song.SEND_ORDER_TIME "派单时间（送）",
    pso_song.ORDER_RECEIVING_TIME  "接单时间（送）",
    pso_song.START_PLACE_ARRIVE_TIME  "到达出发地时间（送）",
    pso_song.SEND_ORDER_ARRIVE_TIME "接到患者时间（送）",
    pso_song.BURGLARY_TIME "到达目的地时间（送）",
    pso_song.SEND_ORDER_FINISH_TIME "完成订单时间（送）",
    '' "小恢复室事件时间",
    '' "入小恢复室时间",
    reqrm.oper_room 预计手术间,
    '' 变更手术间,
    
    case when info.s_sssyzt_dm ='30' and info.in_oproom_date is null then '排程未做'
                when info.s_sssyzt_dm='90' and info.oper_beging_date is not null and info.oper_end_date is not null then '已完成手术'
                when info.ana_beging_date is null and info.oper_beging_date is null then '麻醉前取消'
                when info.ana_beging_date is not null and info.oper_beging_date is null then '手术开始前取消' else '' end 手术完成状态,
    case when info.s_sssyzt_dm='90' and info.oper_beging_date is not null and info.oper_end_date is not null then ''  else info.reject_reason end 手术取消原因,
    case when szbw.event_text is not null then '是' else '否' end 术中保温,
    '' 术前抗菌药物使用时间,
    '' 术中抗菌药物追加时间,
    '' 术前抗菌药物医嘱名称,
    '' 术中抗菌药物医嘱名称
    
from (select a.id apply_id,
           max(ar.id) anar_id,
           nvl(max(reg.sam_room_id) , max(a.sam_room_id)) roomId,
           nvl(max(reg.ipi_registration_id),max(a.ipi_registration_id)) ipi_registration_id,
           nvl(max(reg.opc_registration_id),max(a.opc_registration_id)) opc_registration_id,
           nvl(max(reg.patient_name),max(a.patient_name)) patient_Name,
           listagg(o.operation_name, '；') within group(order by o.operation_name) operName,
           nvl(max(reg.is_emergency),max(a.is_emergency)) is_emergency,
           nvl(max(reg.is_daytime),max(a.is_daytime)) is_daytime,
           nvl(max(reg.patient_source),max(a.patient_source)) patient_source,
           max(a.blood_loss) blood_loss,
           max(a.blood_loss) oper_time,
           max(a.oper_type) oper_type,
           max(a.is_reject) is_reject , 
           max(a.reject_reason) reject_reason,
           max(a.s_sssyzt_dm) s_sssyzt_dm,
           max(to_char(a.scheduled_date, 'yyyy-mm-dd')) schedate,
           max(a.scheduled_date) scheduled_date,
           max(a.op_time) ap_op_time,
           nvl(max(reg.s_xb_dm) , max(a.s_xb_dm)) s_xb_dm,
           max(a.sam_room_id) req_room_id,
           nvl(max(reg.sam_room_id) , max(a.sam_room_id)) room_id,
           nvl(max(o.s_asamzfj_dm) , max(aop.s_asamzfj_dm)) asadm,
           nvl(max(o.s_ssjb_dm) , max(aop.s_ssjb_dm)) s_ssjb_dm,
           
           nvl(max(o.s_ssqk_dj_dm) , max(aop.s_ssqk_dj_dm)) qkdj,
           
           nvl(max(reg.bed_no) , max(a.bed_no)) bed_no,
           nvl(max(reg.birthday) , max(a.birthday)) birthday,
           nvl(max(reg.main_diag) , max(a.main_diag)) main_diag,
           nvl(max(o.operator_doctor_id),max(aop.operator_doctor_id))  ssdoc_id,
           
           nvl(max(o.operator_assistant_1),max(aop.operator_assistant_1))  ssdoc1_id,
           nvl(max(o.operator_assistant_2),max(aop.operator_assistant_2))  ssdoc2_id,
           
           
           nvl(max(o.narcotic_doctor_id),max(aop.narcotic_doctor_id)) mzdoc_id,
           
           nvl(max(o.narcotic_assistant_1),max(aop.narcotic_assistant_1)) mzzs1_id,
           nvl(max(o.narcotic_assistant_2),max(aop.narcotic_assistant_2)) mzzs2_id,
           
           nvl(max(o.CIRCUIT_NURSE_01),max(aop.CIRCUIT_NURSE_01)) xhdoc1_id,
           nvl(max(o.CIRCUIT_NURSE_02),max(aop.CIRCUIT_NURSE_02)) xhdoc2_id,
           
           nvl(max(o.SCRUB_NURSE_01),max(aop.SCRUB_NURSE_01)) xsdoc1_id,
           nvl(max(o.SCRUB_NURSE_02),max(aop.SCRUB_NURSE_02)) xsdoc2_id,
           
           
           
           nvl(max(reg.patient_dept_id),max(a.patient_dept_id)) dept_id,
           max(ar.in_oproom_date) in_oproom_date,
           max(ar.out_oproom_date) out_oproom_date,
           max(ar.oper_beging_date) oper_beging_date,
           max(ar.oper_end_date) oper_end_date,
           max(ar.ana_beging_date) ana_beging_date,
           max(ar.ana_end_date) ana_end_date,
           max(ar.rec_in_date) rec_in_date,
           max(ar.rec_out_date) rec_out_date 
      from sam_apply a
      left join sam_reg reg 
        on reg.id =  a.id 
    left join ipi_registration ig
    on ig.id = reg.ipi_registration_id
    left join opc_registration og
    on og.id = reg.opc_registration_id
    left join sam_reg_op o
    on reg.id = o.sam_reg_id
    left join sam_apply_op aop 
    on a.id = aop.sam_apply_id 
    left join sam_anar ar
    on a.id = ar.sam_apply_id
        
        -- start 请在此处编写SQL条件 --
        where a.scheduled_date between TO_DATE( '2024-12-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '2024-12-30 00:00:00', 'yyyy-mm-dd hh24:mi:ss' )
        and a.health_service_org_id='HXSSMZK' 
        and a.sam_room_id not in ('73') and (a.oper_type = 'ROOM_OPER' OR  (a.oper_type in( 'NJ_OPER','QZJ_OPER') AND a.patient_source='03')) 
        -- end--
       
     group by a.id  
     ) info
  left join ipi_registration ieg on ieg.id = info.ipi_registration_id
  left join opc_registration opc on opc.id = info.opc_registration_id
  left join hra00_department dpt on dpt.id = info.dept_Id
  
  left join pro_send_order pso_jie on pso_jie.apply_id = info.apply_id and pso_jie.direction = 0
  -- 本部线上环境是 cdxt_boot
  left join cdxtboot.sys_user cbu_jie on cbu_jie.id = pso_jie.carer_id
  left join pro_send_order pso_song on pso_song.apply_id = info.apply_id and pso_song.direction = 1
  -- 本部线上环境是 cdxt_boot
  left join cdxtboot.sys_user cbu_song on cbu_song.id = pso_song.carer_id
 
  left join pub_sssyzt ps on ps.s_sssyzt_dm = info.s_sssyzt_dm
  left join sam_room rm  on rm.id = info.room_id 
  left join sam_room reqrm on reqrm.id = info.req_room_id
  left join hrm_employee ssem on ssem.id = info.ssdoc_id
  
  left join hrm_employee ssem1 on ssem1.id = info.ssdoc1_id
  left join hrm_employee ssem2 on ssem2.id = info.ssdoc2_id
  
  left join hra00_department docdept on docdept.id = ssem.department_id 
  
  left join hrm_employee mzem on mzem.id = info.mzdoc_id
  left join hrm_employee mzem1 on mzem1.id = info.mzzs1_id
  left join hrm_employee mzem2 on mzem2.id = info.mzzs2_id
  
  
  left join hrm_employee xhdoc1 on xhdoc1.id = info.xhdoc1_id
  left join hrm_employee xhdoc2 on xhdoc2.id = info.xhdoc2_id
  
  
  left join hrm_employee xsdoc1 on xsdoc1.id = info.xsdoc1_id
  left join hrm_employee xsdoc2 on xsdoc2.id = info.xsdoc2_id
  
  left join GB_T_2261_1_2003 xb on xb.s_xb_dm = info.s_xb_dm
  left join sam_anar ar on ar.id=info.anar_id
  left join (select r.sam_apply_id,
                    listagg(n.node_value, ';') within group(order by n.id) mzfsCmc
           from sam_emr_rec r
           left join sam_emr_rec_nv n
             on n.sam_emr_rec_id = r.id
             left join sam_apply a on a.id = r.sam_apply_id
          where a.scheduled_date between TO_DATE( '2024-12-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '2024-12-30 00:00:00', 'yyyy-mm-dd hh24:mi:ss' )
             and a.oper_type = 'ROOM_OPER'
            and n.node_name = 'S_MZFS_DM'
          group by r.sam_apply_id) mzfs on mzfs.sam_apply_id = info.apply_id
          
    left join (select ev.sam_apply_id apid, max(ev.tw_place) tw_place 
               from sam_apply ap
               left join sam_anar_enent ev
                 on ev.sam_apply_id = ap.id
              where ap.scheduled_date between
                    TO_DATE( '2024-12-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '2024-12-30 00:00:00', 'yyyy-mm-dd hh24:mi:ss' )
                and ev.s_mzsj_dm = '10_5'
              group by ev.sam_apply_id) hzqx 
       on hzqx.apid = info.apply_id
       
     left join (select ev.sam_apply_id apid,
                    sum(case
                          when pj.s_jldw_cmc in ('u', 'U', '治疗量') then  ev.single_dose * 200
                          else
                           ev.single_dose
                        end) clsingledose
               from sam_apply ap
               left join sam_anar_enent ev
                 on ev.sam_apply_id = ap.id
               left join pub_jldw pj
                 on pj.s_jldw_dm = ev.single_dose_unit
              where ap.scheduled_date between
                    TO_DATE( '2024-12-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '2024-12-30 00:00:00', 'yyyy-mm-dd hh24:mi:ss' )
                and ev.s_mzsj_dm = '40_2' 
              group by ev.sam_apply_id) xueinfo      
    on xueinfo.apid = info.apply_id
    
    left join (select en.sam_apply_id,
                           max(en.event_text) event_text
                    from sam_apply ap
                    left join sam_anar_enent en  on en.sam_apply_id = ap.id
                    where  ap.scheduled_date between
                    TO_DATE( '2024-12-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '2024-12-30 00:00:00', 'yyyy-mm-dd hh24:mi:ss' )
                       and (en.s_mzsj_dm in('10_29','10_30')  or (en.S_MZSJ_DM='10_41' and (instr(en.EVENT_TEXT,'保温毯加温')>0)) )
                    group by en.sam_apply_id) szbw on szbw.sam_apply_id = info.apply_id
                    
                    
order by info.scheduled_date desc;                                                                                                                                                                         
