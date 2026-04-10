SELECT
DECODE(ad.status, 
        '1', '疑似',
        '2', '已否认',
        '3', '已审核',
        '4', '已上报',
        '5', '已确认',
        '未知状态' 
) 状态 , 
info.patient_Name 患者姓名 , 
xb.s_xb_cmc 性别 , 
f_j_getage(info.scheduled_date, info.birthday) 年龄 , 
ar.height "患者身高(cm)", 
ar.weight "患者体重(kg)" , 
info.birthday 患者出生日期 , 
nvl(ieg.ipi_registration_no,opc.opc_registration_no) 登记号 , 
ieg.ipno 病案号 , 
(case when info.is_emergency='1' then '急诊' else '择期' end ) 手术类型 , 
dpt.department_chinese_name  科室 , 
info.bed_no 床号 , 
rm.oper_room 手术间 , 
info.scheduled_date 手术安排日期 , 
ssem.employee_name 主刀医师 , 
mzem.employee_name 麻醉医师 , 
mzem1.employee_name 麻醉助手I , 
mzem2.employee_name 麻醉助手II , 
mzem3.employee_name 麻醉助手III , 
info.main_diag 患者诊断 , 
info.operName 手术名称 , 
info.in_oproom_date 入室时间 , 
info.ana_beging_date 麻醉开始时间 , 
info.ana_end_date 麻醉结束时间 , 
info.oper_beging_date 手术开始时间 , 
info.oper_end_date 手术结束时间 , 
info.out_oproom_date 出室时间 , 
info.asadm ASA分级 , 
DECODE(ad.patient_type, 
        '1', '常规手术',
        '2', '常规手术(临时安排)',
        '3', '限期手术',
        '4', '急症手术',
        '5', '严重复合创伤',
        '/' 
)  病人分类 , 
'' 麻醉医师分类 , 
'' 时间分段 , 
DECODE(ad.anar_phase, 
        '2', '麻醉前',
        '8', '麻醉诱导前期',
        '3', '麻醉诱导',
        '4', '术中',
        '5', '拔管',
         '6', '苏醒期',
         '7', '术后回病房',
        '/' 
) 麻醉时间分段 , 
adv.event_name 不良事件名称 , 
adf.factor_name 不良事件因素 , 
adr.reason_name 不良事件原因 , 
ad.happen_date 发生时间 , 
adem.employee_name 填表人 , 
ad.fill_man_id 填表人ID , 
ad.submit_date 提交时间 , 
ad.review_time 审核时间 , 
adrvem.employee_name 审核人 , 
yzy.s_smzd_cmc 所属亚专业 , 
'' 否定不良事件说明 , 
ad.mark 简述不良事件发生经过 , 
'' 系统识别依据 , 
DECODE(ad.is_key_point, 
        '1', '是',
        '2', '否',
        '/' 
) 是否重点关注 , 


DECODE(valuejson(ad.adverse_details, '"by_fault"'),   '1', '由失误造成、')  || 
DECODE(valuejson(ad.adverse_details, '"by_technology"'),   '1', '由技术造成、')  || 
DECODE(valuejson(ad.adverse_details, '"by_opt"'),   '1', '由外科手术造成、')   不良事件发生原因 , 

DECODE(valuejson(ad.adverse_details, '"wrong"'),   '1', '判断错误、')  || 
DECODE(valuejson(ad.adverse_details, '"inexperienced"'),   '1', '经验不足、')  || 
DECODE(valuejson(ad.adverse_details, '"less_environment"'),   '1', '环境不够熟悉、')  || 
valuejson(ad.adverse_details, '"lk_orther_text"')   "计划错误(知识不足) ", 

DECODE(valuejson(ad.adverse_details, '"befor_opt_assess"'),   '1', '术前评估不当、')  || 
DECODE(valuejson(ad.adverse_details, '"befor_opt_ready"'),   '1', '术前准备不当、')  || 
DECODE(valuejson(ad.adverse_details, '"Equ_check_error"'),   '1', '设备检查失误、')  || 
valuejson(ad.adverse_details, '"lu_ort_text"') "计划错误(规则不熟悉)", 

DECODE(valuejson(ad.adverse_details, '"pre_job_train"'),   '1', '岗前培训疏忽、')  || 
DECODE(valuejson(ad.adverse_details, '"dis_and_neg"'),   '1', '外因分心疏忽、')  || 
DECODE(valuejson(ad.adverse_details, '"fail_to_ob"'),   '1', '疏于观察、')  || 
DECODE(valuejson(ad.adverse_details, '"merr_err"'),   '1', '记忆错误、')  || 
valuejson(ad.adverse_details, '"lt_ort_text"')  "实施错误-监护(技术不熟悉)", 

DECODE(valuejson(ad.adverse_details, '"elk_err"'),   '1', '判断错误、')  || 
DECODE(valuejson(ad.adverse_details, '"elk_exper"'),   '1', '经验不足、')  || 
DECODE(valuejson(ad.adverse_details, '"elk_en"'),   '1', '环境不够熟悉、')  ||  
valuejson(ad.adverse_details, '"elk_ort_text"')  "实施错误-问题处理(知识不足) ", 

DECODE(valuejson(ad.adverse_details, '"not_foll_ins"'),   '1', '未按指南操作、')  || 
DECODE(valuejson(ad.adverse_details, '"not_foll_pre"'),   '1', '未按方案操作、')  || 
valuejson(ad.adverse_details, '"lp_ort_text"') "实施错误-问题处理(规划不熟悉) ", 

----
DECODE(valuejson(ad.adverse_details, '"czyl"'),   '1', '操作压力、')  || 
DECODE(valuejson(ad.adverse_details, '"jlwt"'),   '1', '交流问题、')  || 
DECODE(valuejson(ad.adverse_details, '"qstd"'),   '1', '缺少团队工作、')  || 
DECODE(valuejson(ad.adverse_details, '"bdzdls"'),   '1', '不当的指导老师、')   "潜在的/起作用的因素:文化 ", 

DECODE(valuejson(ad.adverse_details, '"qsmzzs"'),   '1', '缺少麻醉助手、')  || 
DECODE(valuejson(ad.adverse_details, '"zsbl"'),   '1', '助手不力、')  || 
DECODE(valuejson(ad.adverse_details, '"bsgzry"'),   '1', '新/不熟的工作人员、')   "潜在的/起作用的因素:工作人员 ", 

DECODE(valuejson(ad.adverse_details, '"bsxwz"'),   '1', '不熟悉位置、') ||
DECODE(valuejson(ad.adverse_details, '"bsxfx"'),   '1', '不习惯方向、') || 
DECODE(valuejson(ad.adverse_details, '"bsxbr"'),   '1', '不熟悉病人、') || 
DECODE(valuejson(ad.adverse_details, '"bsxjh"'),   '1', '不熟悉监护、') || 
DECODE(valuejson(ad.adverse_details, '"bsxsb"'),   '1', '不熟悉设备、')  "潜在的/起作用的因素:工作环境 ", 

DECODE(valuejson(ad.adverse_details, '"pl"'),   '1', '疲劳、') || 
DECODE(valuejson(ad.adverse_details, '"jz"'),   '1', '紧张、') || 
DECODE(valuejson(ad.adverse_details, '"sb"'),   '1', '生病、') || 
DECODE(valuejson(ad.adverse_details, '"cx"'),   '1', '粗心、')  "潜在的/起作用的因素:个人 ", 

DECODE(valuejson(ad.adverse_details, '"you"'),   '1', '有-未执行、')  ||
DECODE(valuejson(ad.adverse_details, '"bsy"'),   '1', '不适用、')   ||
DECODE(valuejson(ad.adverse_details, '"meiyou"'),   '1', '没有-应当建立、')  "潜在的/起作用的因素:政策/方案" , 
----   DECODE(valuejson(ad.adverse_details, '"aaaaa"'),   '1', 'bbbbb、')  || 


DECODE(valuejson(ad.adverse_details, '"experience"'),   '1', '前面经验/高度警惕、')  || 
DECODE(valuejson(ad.adverse_details, '"good_assistant"'),   '1', '训练有素的助手、')  || 
DECODE(valuejson(ad.adverse_details, '"near_teacher"'),   '1', '临近的指导老师、')  || 
valuejson(ad.adverse_details, '"one_ort_text"')  "改善结果的因素:第一行", 

DECODE(valuejson(ad.adverse_details, '"good_plan"'),   '1', '良好的计划/方案、')  || 
DECODE(valuejson(ad.adverse_details, '"cooperate"'),   '1', '请教与合作、')  || 
DECODE(valuejson(ad.adverse_details, '"chech_agin"'),   '1', '设备再检查、')  || 
valuejson(ad.adverse_details, '"second_ort_text"')   "改善结果的因素:第二行" , 

DECODE(valuejson(ad.adverse_details, '"early_detection"'),   '1', '监护仪或报警早发现、')  || 
valuejson(ad.adverse_details, '"third_ort_text"')  "改善结果的因素:第三行" , 

DECODE(valuejson(ad.adverse_details, '"good_pre"'),   '1', '现有的自由条件下能够预防、')  || 
DECODE(valuejson(ad.adverse_details, '"equipment_pre"'),   '1', '有充分理由认为额外设备能够预防、')  || 
DECODE(valuejson(ad.adverse_details, '"resouse_pre"'),   '1', '现有的资源条件下可能预防、')  || 
DECODE(valuejson(ad.adverse_details, '"person_pre"'),   '1', '有充分理由认为增加资源可能预防、')  || 
DECODE(valuejson(ad.adverse_details, '"no_pre"'),   '1', '任何改变都不能明显预防、')   预防措施 , 

DECODE(valuejson(ad.adverse_details, '"no_pro"'),   '1', '无影响、')  || 
DECODE(valuejson(ad.adverse_details, '"equ_temp_pro"'),   '1', '病人不能注意到的暂时影响、')  || 
DECODE(valuejson(ad.adverse_details, '"res_temp_pro"'),   '1', '能完全恢复的暂时影响、')  || 
DECODE(valuejson(ad.adverse_details, '"slight_ever"'),   '1', '可能是不致残的永久性损害、')  || 
DECODE(valuejson(ad.adverse_details, '"serious_ever"'),   '1', '可能是致残的永久性损害、')  || 
DECODE(valuejson(ad.adverse_details, '"dead"'),   '1', '死亡、')   后果 , 
'' 随访时间 , 
'' 记录时间 , 
'' 随访人 , 
valuejsonsz(ad.adverse_details, '"follow_visit"') 随访说明 , 
valuejsonsz(ad.adverse_details, '"review_note"') 审核说明

from (select a.id apply_id,
           max(ar.id) anar_id,
           nvl(max(reg.sam_room_id) , max(a.sam_room_id)) roomId,
           nvl(max(reg.ipi_registration_id),max(a.ipi_registration_id)) ipi_registration_id,
           nvl(max(reg.opc_registration_id),max(a.ipi_registration_id)) opc_registration_id,
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
           nvl(max(o.narcotic_assistant_3),max(aop.narcotic_assistant_3)) mzzs3_id,
           
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
        where a.scheduled_date between TO_DATE( '2023-12-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '2026-12-30 00:00:00', 'yyyy-mm-dd hh24:mi:ss' )
        -- end--
       
     group by a.id  
     ) info
  left join ipi_registration ieg on ieg.id = info.ipi_registration_id
  left join opc_registration opc on opc.id = info.opc_registration_id
  left join hra00_department dpt on dpt.id = info.dept_Id
  
  left join pub_sssyzt ps on ps.s_sssyzt_dm = info.s_sssyzt_dm
  left join sam_room rm  on rm.id = info.room_id 
  
  left join hrm_employee ssem on ssem.id = info.ssdoc_id
  
  left join hrm_employee mzem on mzem.id = info.mzdoc_id
  left join hrm_employee mzem1 on mzem1.id = info.mzzs1_id
  left join hrm_employee mzem2 on mzem2.id = info.mzzs2_id
  left join hrm_employee mzem3 on mzem3.id = info.mzzs3_id
  
  left join GB_T_2261_1_2003 xb on xb.s_xb_dm = info.s_xb_dm
  left join sam_anar ar on ar.id=info.anar_id
  
  left join sam_adverse_event ad on ad.apply_id = info.apply_id
  
  left join sam_adverse adv on adv.id = ad.event_id 
  
  left join sam_adverse_factor adf on adf.id = ad.factor_id 
  
  left join sam_adverse_reason adr on adr.id = ad.reason_id 
  
  left join hrm_employee adem on adem.id = ad.fill_man_id 
  
  left join hrm_employee adrvem on adrvem.id = ad.reviewer_id
  
  left join pub_smzd yzy on yzy.s_smzd_dm = ad.profession_id

where ad.id is not null 
 
order by info.scheduled_date desc;                                                                                                                                                                         
