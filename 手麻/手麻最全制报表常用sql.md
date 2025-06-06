#### sql查询

##### 字段块

```sql
SELECT 
a.id 手术唯一编码,
ipi.id PATIENT_ID,--患者ID:HIS系统中的患者ID，患者流水号
nvl(reg.opa_no,a.opa_no) 手术申请号,
to_char(a.scheduled_date,'yyyy-mm-dd') 日期,
to_char(ar.in_oproom_date,'yyyy-mm-dd') 日期,
de.department_chinese_name 患者科室,
a.scheduled_date 外科期望时间,--排程时间
nvl(reg.patient_name,a.patient_name) 患者姓名,
xb.s_xb_cmc 性别,
f_j_getage(a.scheduled_date,nvl(reg.birthday,a.birthday)) 年龄,
ar.height 身高,
ar.weight 体重,
trunc(case when ar.weight is not null and ar.height is not null and ar.height !=0 then ar.weight/((ar.height/100)*(ar.height/100)) else null end),2) BMI,
rm.oper_room 手术间,
nvl(reg.birthday,a.birthday) 出生日期,
--de.department_abbreviation 审核部门,
jsks.department_chinese_name 接收科室,
req.department_chinese_name 申请科室,
nvl(reg.bed_no,a.bed_no) 床号,
decode(nvl(reg.patient_source,a.patient_source),'03','住院','02','急诊','01','门诊') 患者来源,
nvl(a.op_time,row_number() over(partition by rm.id,to_char(a.scheduled_date,'yyyy-mm-dd') order by ar.in_oproom_date,a.scheduled_date)) 台次,
row_number() over(partition by rm.id,to_char(nvl(ar.in_oproom_date,a.scheduled_date),'yyyy-mm-dd') order by nvl(ar.in_oproom_date,a.scheduled_date)) tc,--台次2
nvl(rop.operation_Name,aop.operation_Name) 手术名称,
nvl(rop.OPERATION_CODE,aop.OPERATION_CODE) 手术操作代码,
pasa.s_asamzfj_cmc ASA分级,
ssjb.s_ssjb_cmc 手术级别,
coalesce(pub1.s_sscz_rtbw_cmc,rop.incision_site,aop.incision_site) 手术部位,
ipi.ipi_registration_no 住院号,
nvl(ipi.INHOSPITAL_TIMES,ipi.THIS_YEAR_TIMES) 住院次数,--总的|本年度住院次数
opc.OPC_REGISTRATION_NO 门诊号,--门诊急诊号
nvl(ipi.ipi_registration_no,opc.opc_registration_no) 登记号,
nvl(ipi.IDENTITY_NO,opc.IDENTITY_NO) 证件号码,--不一定是身份证
ipi.s_cyqk_dm 离院方式代码,
ps.s_sssyzt_cmc 手术状态,
ipi.registration_date 入院日期,--入院日期（挂号时间）
nvl(ipi.leave_dept_date,ipi.DISCHARGE_DATE) 出院时间,--可能是his传的，所以可能没有
ipi.FIRST_INSECTION_DATE 入院时间,--可能是his传的，所以可能没有
a.reject_reason 拒绝理由,
nvl(mzfs.mzfsCmc,mzfs2.s_mzfs_cmc) 麻醉方式,
(case when nvl(reg.is_emergency,a.is_emergency) = '1' then '急诊'
      when nvl(reg.is_emergency,a.is_emergency) = '2' then '择期'
      when nvl(reg.is_daytime,a.is_daytime) = '1' then '日间'
      else null end) 手术类型,
(case when nvl(reg.is_daytime,a.is_daytime) = '1' then '是' when nvl(reg.is_daytime,a.is_daytime) ='2' then '否' else null end) 是否日间,--好像null或者'0'也是否
(case when nvl(reg.is_emergency,a.is_emergency) = '2' then '是' else '否' end) 是否择期,
(case when nvl(reg.is_emergency,a.is_emergency) = '2' then '择期' when nvl(reg.is_emergency,a.is_emergency) = '1' then '急诊' else '其他' end) 手术类型,
gms.gms 过敏史,
'ABO血型:'||ab.s_aboxx_cmc||'Rh血型:'||rh.s_rhxx_cmc 血型,
valuejson(ztb.remark, '"ztb_type"') 镇痛泵类型,
valuejson(ztb.remark, '"ztb_method"') 镇痛方法,
ev.ztpf 镇痛配方,
ao.oppos_name 体位,
ztbsj.ztb_name 镇痛泵名称,
mz.employee_name 麻醉医生,
zd.employee_name 主刀医生,
xh1.employee_name 巡回1,
xh2.employee_name 巡回2,
xs1.employee_name 洗手1,
xs2.employee_name 洗手2,
xh1.employee_name||decode(xh1.employee_name,null,xh2.employee_name,decode(xh2.employee_name,null,null,'/'||xh2.employee_name)) 巡回,
xs1.employee_name||decode(xs1.employee_name,null,xs2.employee_name,decode(xs2.employee_name,null,null,'/'||xs2.employee_name)) 洗手,
zdzs1.employee_name 主刀助手1,
zdzs2.employee_name 主刀助手2,
zdzs3.employee_name 主刀助手3,
zdzs4.employee_name 主刀助手4,
hrm.employee_name 主管医师,
zdls.employee_name 指导医师,
substr(decode(mzzs1.employee_name,null,null,mzzs1.employee_name||'/')||
       decode(mzzs2.employee_name,null,null,mzzs2.employee_name||'/')||
       decode(mzzs3.employee_name,null,null,mzzs3.employee_name||'/'),1,
length(decode(mzzs1.employee_name,null,null,mzzs1.employee_name||'/')||
       decode(mzzs2.employee_name,null,null,mzzs2.employee_name||'/')||
       decode(mzzs3.employee_name,null,null,mzzs3.employee_name||'/'))-1) 麻醉助手,
mzzs1.employee_name 麻醉助手1,
mzzs2.employee_name 麻醉助手2,
mzzs3.employee_name 麻醉助手3,
mzhs1.employee_name 麻醉护士1,
mzhs2.employee_name 麻醉护士2,
gzysem.employee_name 灌注,
trunc((ar.oper_end_date-ar.oper_beging_date)*24,2)||'小时' 手术时长,
ar.oper_beging_date 手术开始,
ar.oper_end_date 手术结束,
a.req_dat 手术申请时间,
trunc((ar.ana_end_date-ar.ana_beging_date)*24,2)||'小时' 麻醉时长,
ar.ana_end_date 麻醉结束,
ar.ana_beging_date 麻醉开始,
ar.in_oproom_date 入室时间,
ar.out_oproom_date 出室时间,
ar.rec_in_date 入PACU时间,
ar.rec_out_date 出PACU时间,
trunc((ar.out_oproom_date-ar.in_oproom_date)*24,2)||'小时' 入室时长,
(case when ar.IS_BEARFOOD='1' then ar.finally_eat_time else null end) 禁饮禁食时间,--多少小时前
--药品剂量(注：这里计算公式，浓度好像有问题)
to_char(e.single_dose * 
(case when instr(j.s_jldw_cmc, '/h') > 0 then (case when e.duration is null then 1 else round((e.end_date - e.ordered_date) * 24, 2) end)
     when instr(j.s_jldw_cmc, '/min') > 0 then (case when e.duration is null then 1 else round((e.end_date - e.ordered_date) * 24 * 60, 1) end)
else 1 end) * 
(case when instr(j.s_jldw_cmc, '/kg') > 0 then ar.weight else 1 end) * 
(case when e.density is not null then (to_number(e.density) * 10) else 1 end) * 
n.udu_du_scale,'fm9999999999999990.00')||ja.s_jldw_cmc 使用剂量,
nvl(en.specification,drm.specification) 规格,
pyj.s_yytj_cmc 用法,
--处方剂量(规格)-使用剂量=丢弃剂量
to_char((ceil((e.single_dose * 
(case when instr(j.s_jldw_cmc, '/h') > 0 then (case when e.duration is null then 1 else round((e.end_date - e.ordered_date) * 24, 2) end)
when instr(j.s_jldw_cmc, '/min') > 0 then (case when e.duration is null then 1 else round((e.end_date - e.ordered_date) * 24 * 60, 1) end)
else 1 end) * 
(case when instr(j.s_jldw_cmc, '/kg') > 0 then ar.weight else 1 end) * 
(case when e.density is not null then (to_number(e.density) * 10) else 1 end) * 
n.udu_du_scale)/drm.single_dose_specification) * drm.single_dose_specification- e.single_dose * 
(case when instr(j.s_jldw_cmc, '/h') > 0 then (case when e.duration is null then 1 else round((e.end_date - e.ordered_date) * 24, 2) end)
     when instr(j.s_jldw_cmc, '/min') > 0 then (case when e.duration is null then 1 else round((e.end_date - e.ordered_date) * 24 * 60, 1) end)
else 1 end) * 
(case when instr(j.s_jldw_cmc, '/kg') > 0 then ar.weight else 1 end) * 
(case when e.density is not null then (to_number(e.density) * 10) else 1 end) * 
n.udu_du_scale),'fm9999999999999990.00')||ja.s_jldw_cmc 丢弃剂量,
to_char(ceil(sum(t.single_dose * 
    (case when instr(j.s_jldw_cmc, '/h') > 0 then (case when t.duration is null then 1 else round((t.end_date -t.ordered_date) * 24, 2) end)
          when instr(j.s_jldw_cmc, '/min') > 0 then (case when t.duration is null then 1 else round((t.end_date - t.ordered_date) * 24 * 60, 1) end)
     else 1 end) * 
    (case when instr(j.s_jldw_cmc, '/kg') > 0 then a.weight else 1 end) * 
    (case when t.density is not null then (to_number(t.density) * 10) else 1 end) * 
    n.udu_du_scale)/max(drm.single_dose_specification))  * max(drm.single_dose_specification),'fm9999999999999990.00')||ja.s_jldw_cmc 处方剂量,
--(case when instr(j.s_jldw_cmc,'/')>0 then substr(j.s_jldw_cmc,0,instr(j.s_jldw_cmc,'/')-1) else j.s_jldw_cmc end)
nvl(reg.main_diag,a.main_diag) 术中诊断,--一般报表要的诊断都用用它
--ar.OPPRE_DIAG 术前诊断,
--coalesce(ar.OPPRE_DIAG,reg.main_diag,a.main_diag) 术前诊断,
--ar.OPEND_DIAG 术后诊断,
--coalesce(ar.OPEND_DIAG,reg.main_diag,a.main_diag) 术后诊断,
yy.event_text 药品名称,
yy.batch_no 药品批号,
yy.POISONOUS_NO 处方号,
qk.s_ssqk_dj_cmc 切口等级,
qk.s_bz 手术切口清洁度,
yhdj.s_bz 切口愈合备注,
yhdj.s_ssqk_yhdj_cmc 切口愈合等级,
jm.mc 静脉,
dm.mc 动脉,
ar.weight 体重,
ald.zf Aldrete总分,
nvl(ipi.IDENTITY_NO,opc.IDENTITY_NO) 证件号码,
rm.BUILDING||'-'||rm.FLOOR 手术间位置,--建筑物—楼层
csqx.tw_place 术后运转地点,
pbys.employee_name 排班医生,
aop.operation_Name 拟行手术,
rop.operation_Name 实施手术,
cgsj 插管时间,--首次
hz.hz 喉罩类型,
sjzz.cjq 神经刺激器,
sjzz.csyd 超声引导,--以下几个地方有 in ('sam_sjzz','sam_zgnmz','sam_yccz')
sjzz.zzfs 阻滞方式,
(case when mzxg.mzxg='1' then '优' when mzxg.mzxg='2' then '良' when mzxg.mzxg='3' then '中' when mzxg.mzxg='4' then '差' else null end) 麻醉满意度,--麻醉质量评估的麻醉效果
(case when icu.icu is not null then '是' else '否' end) 是否转入ICU,--苏醒室&手术室ICU
nvl(rop.OPERATION_CODE,aop.OPERATION_CODE) 手术编码,--ICD-9
chuxueinfo.singledose 出血量,
sx.singledose 输血量,
sx.hs 自体血,
sx.yx 异血,
ps.s_sssyzt_cmc 手术状态,
a.oper_time 手术预计时长,
a.blood_loss 预估出血量,
trunc((ar.out_oproom_date-ar.in_oproom_date)*24,0) 时长(h),
trunc((ar.out_oproom_date-ar.in_oproom_date)*1440,0) 时长(min),
trunc((ar.out_oproom_date-ar.in_oproom_date)*86400,0) 时长(s),
zrw.zrw 植入物,
decode(nvl(reg.is_again_plan,a.is_again_plan),'1','是','否') 是否非计划手术,
sam_anar_enent.other_attr 输血类型,--自体/异血
bq.BQMC 入院病区名称,
yz.yz 术前麻醉医嘱,
trunc(months_between(ar.out_oproom_date,ipi.birthday)/12) NLS,--年龄(岁)
mod(trunc(months_between(ar.out_oproom_date,ipi.birthday)),12) NLY,--年龄(月)
(case when (ar.out_oproom_date - trunc(ar.out_oproom_date,'mm')) > (ipi.birthday - trunc(ipi.birthday))
             then trunc((ar.out_oproom_date - trunc(ar.out_oproom_date,'mm')) - (ipi.birthday - trunc(ipi.birthday)))
             when (ar.out_oproom_date - trunc(ar.out_oproom_date,'mm')) < (ipi.birthday - trunc(ipi.birthday))
             then trunc((ipi.birthday - trunc(ipi.birthday)) - (ar.out_oproom_date - trunc(ar.out_oproom_date,'mm')))
             else 0 end) NLT,--年龄(天)
(case when (ar.out_oproom_date - trunc(ar.out_oproom_date)) > (ipi.birthday - trunc(ipi.birthday))
             then trunc(((ar.out_oproom_date - trunc(ar.out_oproom_date)) - (ipi.birthday - trunc(ipi.birthday))) * 24)
             when (ar.out_oproom_date - trunc(ar.out_oproom_date)) < (ipi.birthday - trunc(ipi.birthday))
             then trunc(((ipi.birthday - trunc(ipi.birthday)) - (ar.out_oproom_date - trunc(ar.out_oproom_date))) * 24)
             else 0 end) NLXS,--年龄(小时)
ar.oppre_sc 术前特殊情况,
a.or_require 注意事项,
```

##### 连表块

###### 最基础块

```sql
from sam_apply a 
left join sam_reg reg on reg.id = a.id
left join sam_anar ar on ar.sam_apply_id = a.id
left join ipi_registration ipi on ipi.id = nvl(reg.ipi_registration_id,a.ipi_registration_id)--住院号
where a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss')
and a.s_sssyzt_dm ='90'--手术完成
and (a.is_reject is null or a.is_reject = '2')--未取消手术
--患者姓名
${if(len(hzxm) > 0,"and nvl(reg.patient_name,a.patient_name) = '" + hzxm + "'","")}
--住院号
${if(len(zyh) > 0, "and ipi.ipi_registration_no = '" + zyh + "'","")}
ORDER BY 
```

###### 基础块

```sql
from (SELECT a.* FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a
left join sam_reg reg on reg.id = a.id
left join sam_anar ar on ar.sam_apply_id = a.id
from sam_apply a 
left join sam_reg reg on reg.id = a.id
left join sam_anar ar on ar.sam_apply_id = a.id
left join ipi_registration ipi on ipi.id = nvl(reg.ipi_registration_id,a.ipi_registration_id)--住院号
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on a.id = ar.sam_apply_id
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on r.sam_apply_id = ar.sam_apply_id--文书
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.id = en.sam_anar_id--事件
inner join (SELECT a.* FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = r.sam_apply_id
left join sam_apply a on a.id = .sam_apply_id
left join (select sj.sam_apply_id,
                  listagg(sj.event_text,'+') within group(order by sj.ordered_date) sj
           from sam_anar_enent sj
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = sj.sam_apply_id
           inner join (SELECT ar.sam_apply_id FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.sam_apply_id = sj.sam_apply_id
           where sj.s_mzsj_dm = ''
           and sj.s_mzsjlb_dm = '10'
           and sj.event_text like '%事件名%'
           group by sj.sam_apply_id) sj on sj.sam_apply_id=a.id--事件块
left join sam_room rm on rm.id = nvl(reg.sam_room_id,a.sam_room_id)--手术间
left join hra00_department de on de.id = nvl(reg.patient_dept_id,a.patient_dept_id)--患者科室
left join hra00_department ssks on ssks.id = zd.department_id--手术科室
left join hra00_department jsks on jsks.id = nvl(reg.RECEIVE_DEPT_ID,a.RECEIVE_DEPT_ID)--患者接收科室
left join hra00_department req on req.id = nvl(reg.req_dept_id,a.req_dept_id)--手术申请科室
left join hra00_department gzry on gzry.id = mz.department_id--工作人员科室(如:麻醉医生)
left join ipi_registration ipi on ipi.id = nvl(reg.ipi_registration_id,a.ipi_registration_id)--住院号
left join opc_registration opc on opc.id = nvl(reg.opc_registration_id,a.opc_registration_id)--门诊号
left join GB_T_2261_1_2003 xb on xb.s_xb_dm = nvl(reg.s_xb_dm,a.s_xb_dm)--性别
left join pub_sssyzt ps on ps.s_sssyzt_dm = a.s_sssyzt_dm--手术状态
left join hra00_health_service_org org on org.id = nvl(reg.health_service_org_id,a.health_service_org_id)--机构
left join (SELECT ald.sam_anar_id,ald.zf FROM (SELECT ald.sam_anar_id,ald.zf,(ROW_NUMBER() OVER(PARTITION BY ald.sam_anar_id  ORDER BY ald.input_date desc)) rn FROM sam_fss_ald ald)ald WHERE ald.rn=1)ald on ald.sam_anar_id=ar.id--Aldrete评分
left join (select sam_apply_id,max(narcotic_doctor_id)narcotic_doctor_id,max(operator_doctor_id) operator_doctor_id,
                  max(SCRUB_NURSE_01) SCRUB_NURSE_01,max(SCRUB_NURSE_02) SCRUB_NURSE_02,--洗手
                  max(circuit_nurse_01) circuit_nurse_01,max(circuit_nurse_02) circuit_nurse_02,--巡回
                  max(operator_assistant_1) operator_assistant_1,max(operator_assistant_2) operator_assistant_2,
                  max(operator_assistant_3) operator_assistant_3,max(operator_assistant_4) operator_assistant_4,
                  max(narcotic_nurse) narcotic_nurse,max(narcotic_nurse2) narcotic_nurse2,
                  max(narcotic_assistant_1) narcotic_assistant_1,max(narcotic_assistant_2) narcotic_assistant_2,
                  max(narcotic_assistant_3) narcotic_assistant_3,max(PERFUSION_DOCTOR_ID) PERFUSION_DOCTOR_ID,
                  listagg(operation_name, ';') within group(order by is_main_operation) operation_Name,
                  listagg(OPERATION_CODE, ';') within group(order by is_main_operation) OPERATION_CODE,
                  max(s_asamzfj_dm)s_asamzfj_dm,max(s_ssjb_dm) s_ssjb_dm,max(s_ssqk_dj_dm) s_ssqk_dj_dm,max(NARCOTIC_GUIDANCE_ID) NARCOTIC_GUIDANCE_ID,
                  max(s_ssqk_yhdj_dm)s_ssqk_yhdj_dm,max(incision_site) incision_site,
                  max(is_main_operation) is_main_operation
           from sam_apply_op group by sam_apply_id) aop on a.id = aop.sam_apply_id              
left join (select sam_reg_id,max(narcotic_doctor_id)narcotic_doctor_id,max(operator_doctor_id) operator_doctor_id,
                  max(SCRUB_NURSE_01) SCRUB_NURSE_01,max(SCRUB_NURSE_02) SCRUB_NURSE_02,--洗手
                  max(circuit_nurse_01) circuit_nurse_01,max(circuit_nurse_02) circuit_nurse_02,--巡回
                  max(operator_assistant_1) operator_assistant_1,max(operator_assistant_2) operator_assistant_2,
                  max(operator_assistant_3) operator_assistant_3,max(operator_assistant_4) operator_assistant_4,
                  max(narcotic_nurse) narcotic_nurse,max(narcotic_nurse2) narcotic_nurse2,
                  max(narcotic_assistant_1) narcotic_assistant_1,max(narcotic_assistant_2) narcotic_assistant_2,
                  max(narcotic_assistant_3) narcotic_assistant_3,max(PERFUSION_DOCTOR_ID) PERFUSION_DOCTOR_ID,
                  listagg(operation_name, ';') within group(order by is_main_operation) operation_Name,
                  listagg(OPERATION_CODE, ';') within group(order by is_main_operation) OPERATION_CODE,
                  max(s_asamzfj_dm)s_asamzfj_dm,max(s_ssjb_dm) s_ssjb_dm,max(s_ssqk_dj_dm) s_ssqk_dj_dm,max(NARCOTIC_GUIDANCE_ID) NARCOTIC_GUIDANCE_ID,
                  max(s_ssqk_yhdj_dm)s_ssqk_yhdj_dm,max(incision_site) incision_site,
                  max(is_main_operation) is_main_operation
           from sam_reg_op group by sam_reg_id) rop on reg.id = rop.sam_reg_id
left join hrm_employee mz on mz.id=nvl(rop.narcotic_doctor_id,aop.narcotic_doctor_id)--麻醉姓名
left join hrm_employee zd on zd.id=nvl(rop.operator_doctor_id,aop.operator_doctor_id)--主刀姓名
left join hrm_employee hrm on hrm.id = ipi.doctor_id--主管医师
left join hrm_employee zdls on zdls.id=nvl(rop.NARCOTIC_GUIDANCE_ID,aop.NARCOTIC_GUIDANCE_ID)--指导姓名
left join hrm_employee sqys on sqys.id=nvl(reg.req_doctor_id,a.req_doctor_id)--申请医生
left join hrm_employee xs1 on xs1.id=nvl(rop.SCRUB_NURSE_01,aop.SCRUB_NURSE_01)--洗手1姓名
left join hrm_employee xs2 on xs2.id=nvl(rop.SCRUB_NURSE_02,aop.SCRUB_NURSE_02)--洗手2姓名
left join hrm_employee xh1 on xh1.id=nvl(rop.circuit_nurse_01,aop.circuit_nurse_01)--巡回1姓名
left join hrm_employee xh2 on xh2.id=nvl(rop.circuit_nurse_02,aop.circuit_nurse_02)--巡回2姓名
left join hrm_employee zdzs1 on zdzs1.id=nvl(rop.operator_assistant_1,aop.operator_assistant_1)--主刀助手1姓名
left join hrm_employee zdzs2 on zdzs2.id=nvl(rop.operator_assistant_2,aop.operator_assistant_2)--主刀助手2姓名
left join hrm_employee zdzs3 on zdzs3.id=nvl(rop.operator_assistant_3,aop.operator_assistant_3)--主刀助手3姓名
left join hrm_employee zdzs4 on zdzs4.id=nvl(rop.operator_assistant_4,aop.operator_assistant_4)--主刀助手4姓名
left join hrm_employee mzzs1 on mzzs1.id=nvl(rop.narcotic_assistant_1,aop.narcotic_assistant_1)--麻醉助手1姓名
left join hrm_employee mzzs2 on mzzs2.id=nvl(rop.narcotic_assistant_2,aop.narcotic_assistant_2)--麻醉助手2姓名
left join hrm_employee mzzs3 on mzzs3.id=nvl(rop.narcotic_assistant_3,aop.narcotic_assistant_3)--麻醉助手3姓名
left join hrm_employee gzysem on gzysem.id = nvl(rop.PERFUSION_DOCTOR_ID,aop.PERFUSION_DOCTOR_ID)--灌注
left join hrm_employee mzhs1 on mzhs1.id=nvl(rop.narcotic_nurse,aop.narcotic_nurse)--麻醉护士1姓名
left join hrm_employee mzhs2 on mzhs2.id=nvl(rop.narcotic_nurse2,aop.narcotic_nurse2)--麻醉护士2姓名
left join hrm_employee pbys on pbys.id=a.req_doctor_id--排班医生姓名
left join pub_asamzfj pasa on nvl(rop.s_asamzfj_dm,aop.s_asamzfj_dm) = pasa.s_asamzfj_dm--asa分级
left join pub_ssjb ssjb on nvl(rop.s_ssjb_dm,aop.s_ssjb_dm) = ssjb.s_ssjb_dm--手术级别
left join pub_sscz_rtbw pub1 on pub1.S_SSCZ_RTBW_DM = nvl(rop.incision_site,aop.incision_site)--手术部位
left join pub_ssqk_dj qk on qk.s_ssqk_dj_dm = nvl(rop.s_ssqk_dj_dm,aop.s_ssqk_dj_dm)--切口
left join PUB_SSQK_YHDJ yhdj on yhdj.S_SSQK_YHDJ_DM = nvl(rop.s_ssqk_yhdj_dm,aop.s_ssqk_yhdj_dm)--切口愈合等级
left join (select r.sam_apply_id,
                  listagg((case when n.node_name = 'DM' then n.node_value else null end),'+') within group(order by n.id) mzfsDM,
                  listagg((case when n.node_name = 'S_MZFS_DM' then n.node_value else null end),'+') within group(order by n.id) mzfsCmc
           from sam_emr_rec r
           inner join sam_apply a on a.id = r.sam_apply_id and a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss')
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'sam_mzfs'
           and n.node_name in ('DM','S_MZFS_DM')
           group by r.sam_apply_id) mzfs on mzfs.sam_apply_id = a.id--麻醉方式
left join (select r.sam_apply_id,listagg(n.node_value,'+') within group(order by n.id) mzfsCmc
           from sam_emr_rec r
           inner join sam_apply a on a.id = r.sam_apply_id and a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss')
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'sam_mzfs'
           and n.node_name = 'S_MZFS_DM'
           group by r.sam_apply_id) mzfs on mzfs.sam_apply_id = a.id--麻醉方式  
left join pub_mzfs mzfs2 on mzfs2.s_mzfs_dm = a.s_mzfs_dm--申请时记录的麻醉方式
left join pub_aboxx ab on ab.s_aboxx_dm=ar.S_ABOXX_DM--ABO血型
left join pub_sssyzt ps on ps.s_sssyzt_dm = a.s_sssyzt_dm--手术状态
left join pub_rhxx rh on rh.s_rhxx_dm=ar.s_rhxx_dm--Rh血型
left join sam_room rm1 on rm1.id = ar.rec_bed_id and rm1.is_rec_bed in ('1','8')--恢复间
left join (select r.sam_apply_id,listagg((case when n.node_name is not null then n.node_value else null end),'+') within group(order by n.node_value) gms
       		from sam_emr_rec r
       		left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
       		where r.rss_emr_type_id = 'sam_mzfs'
       		and n.node_name in ('S_GM','GMS_NAME')
       		group by r.sam_apply_id) gms on gms.sam_apply_id = a.id--过敏史
left join (select nvl(max(de.department_chinese_name),max(en.tw_place)) tw_place,en.sam_apply_id 
          from sam_anar_enent en 
          left join hra00_department de on de.id = en.tw_place
          where en.event_text='出手术室'
          group by en.sam_apply_id)csqx on csqx.sam_apply_id = a.id--出室去向
left join (SELECT ym.sam_apply_id,
           max(case when ym.s_mzsj_dm='10_116' then ym.input_date else null end) 入预麻室时间,
           max(case when ym.s_mzsj_dm='10_117' then ym.input_date else null end) 出预麻室时间
           FROM sam_anar_enent ym
           WHERE ym.s_mzsjlb_dm = '10'
           group by ym.sam_apply_id)ym on ym.sam_apply_id=a.id--预麻室
left join (select en.sam_anar_id icu
                 from sam_anar_enent en
                 where en.tw_place like '%icuInPlan%'
                 --and en.is_rec_enent = '2'--手术室
                 --and en.is_rec_enent = '1'--苏醒室
                 group by en.sam_anar_id) icu on icu.icu = ar.id--是否转入ICU
left join (SELECT ol.APPLY_ID,
           max(case when ol.ANS_VALUE = '82ef1e1c7ba704250002' then '无' when ol.ANS_VALUE = '82ef1e1c7ba6e3ee0001' then '有' else null end) zrw 
           FROM ONS_AQHC_LOG ol
           where ol.issue_id = '82ef1e1c7ba6a7610000'
           group by ol.APPLY_ID) zrw on zrw.apply_id = a.id--三方核查举例：植入物有无
left join(select ao.sam_anar_id,listagg(ao.OPPOS_NAME,'+') within group(order by ao.EXEC_DATE) OPPOS_NAME from sam_anar_oppos ao group by ao.sam_anar_id)ao on ao.sam_anar_id = ar.id--体位
LEFT JOIN SAM_BQ_DEPT bq ON bq.BQDM =  nvl(reg.billing_hospital_area,a.billing_hospital_area)--病区名称
left join (select ev.sam_anar_id, 
                  listagg( ev.event_text,';') within group(order by ev.sam_anar_id) yz
           from sam_anar_enent ev 
           where ((ev.s_mzsjlb_dm='32' 
           and ev.is_py!='1' 
           and ev.is_hzzd!='1')
           or ev.s_mzsjlb_dm='31')
           group by ev.sam_anar_id ) yz on ar.id = yz.sam_anar_id--术前麻醉医嘱
left join pub_patient_type ty on ipi.patient_type_id = ty.id--保险类型名称
left join hra00_department ry on ipi.ipi_dept_id = ry.id--入院科室
left join hra00_department cy on ipi.dept_id = cy.id--出院科室
left join hrm_employee emp on ipi.doctor_id = emp.id--主治医生
```

###### 新护士工作站交接班名单（王牌，待验证）

```sql
from (SELECT ar.sam_apply_id,
                   worker.WORKER_NAME,
                   (case when worker.worker_type = '20' then '巡回'
                         when worker.worker_type = '30' then '洗手'
                         end) worker_type,
                   nvl(worker.START_WORK_TIME,ar.in_oproom_date) sbtime,
                   nvl(worker.END_WORK_TIME,ar.out_oproom_date) xbtime
      FROM sam_anar ar 
      left join ons_reg_worker worker on worker.sam_apply_id = ar.sam_apply_id
      WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss')
      --group by worker.WORKER_NAME,ar.sam_apply_id:万一多次交接，所以不能group
      union all 
      select ar.sam_apply_id,
              hs.employee_name,
              rop.职员,
              ar.in_oproom_date sbtime,
              ar.out_oproom_date xbtime
      FROM sam_anar ar         
      left join (SELECT * 
                 FROM (select sam_reg_id,
                        max(SCRUB_NURSE_01) SCRUB_NURSE_01,max(SCRUB_NURSE_02) SCRUB_NURSE_02,--洗手
                        max(circuit_nurse_01) circuit_nurse_01,max(circuit_nurse_02) circuit_nurse_02--巡回
                       from sam_reg_op group by sam_reg_id
                       ) rop
                 unpivot (姓名ID for 职员 in (SCRUB_NURSE_01 as '洗手',SCRUB_NURSE_02 as '洗手',circuit_nurse_01 as '巡回',circuit_nurse_02 as '巡回'))
                 )rop on ar.sam_apply_id = rop.sam_reg_id--护士工作量使用
       left join hrm_employee hs on hs.id=rop.姓名ID--护士姓名：护士工作量使用       
       left join ons_reg_worker worker on worker.sam_apply_id = ar.sam_apply_id and hs.employee_name = worker.WORKER_NAME
       where worker.sam_apply_id is null
      )jjb
```



###### 护理

```sql
--护理主刀&手术助手
from (SELECT * FROM ons_reg g WHERE g.oper_date between to_date('${start}','yyyy-mm-dd') and to_date('${end}'||' 23:59:59','yyyy-mm-dd hh24:mi:ss'))g
left join (SELECT orw.ons_reg_id,
                  max(case when orw.worker_type = '00' then he.employee_name else null end) zd,
                  max(case when orw.worker_type = '01' then he.employee_name else null end) zs1,
                  max(case when orw.worker_type = '02' then he.employee_name else null end) zs2
           FROM ons_reg_worker orw
           left join hrm_employee he on he.id = orw.worker_id
           group by orw.ons_reg_id)orw on orw.ons_reg_id=g.id
           
--新护理ons_reg_worker：'20'xh；'30'xs 

--护理的洗手巡回
left join (select oaw.apply_id,
                  max(case when oaw.worker_type = '20' then em.employee_name else null end) xh,
                  max(case when oaw.worker_type = '30' then em.employee_name else null end) xs  
           from ons_apply_worker oaw
           left join hrm_employee em on em.id = oaw.worker_id
           where oaw.jieban_time is null group by oaw.apply_id) oaw on reg.id = oaw.apply_id

--时间节点
SELECT reg.sam_apply_id,--关联sam_apply
       oot.time_node_id,
       oot.node_time node_time,
       oot.remark,
       otn.OP_USE_STATE
FROM  ons_oper_time oot
LEFT JOIN ons_reg reg ON reg.id = oot.ons_reg_id
LEFT JOIN ONS_TIME_NODES otn ON otn.id = oot.TIME_NODE_ID
where ons_reg_id = '' 


--工作量:ons_apply_worker
left join (SELECT oaw.apply_id,
                  oot.手术开始,
                  oot.患者出室,
                  oaw.worker_type,
                  (case when oaw.jieban_time is null then oot.手术开始 else oaw.jieban_time end) sbtime,
                  (case when oaw1.jieban_time is null then oot.患者出室 else oaw1.jieban_time end) xbtime
           FROM(SELECT oaw.apply_id,
                       oaw.jieban_time,
                       oaw.worker_type,
                       row_number() over(partition by oaw.apply_id,oaw.worker_type order by oaw.jieban_time nulls first) rn
                FROM ons_apply_worker oaw
                inner join (SELECT a.id,a.scheduled_date FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = oaw.apply_id
                )oaw
           left join (SELECT oot.ons_reg_id,
                             max(case when oot.TIME_NODE_ID = 'n5' then oot.NODE_TIME else null end) 手术开始,
                             max(case when oot.TIME_NODE_ID = 'n13' then oot.NODE_TIME else null end) 患者出室
                      FROM ONS_OPER_TIME oot
                      inner join (SELECT a.id,a.scheduled_date FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = oot.ons_reg_id
                      WHERE oot.TIME_NODE_ID in ('n5','n13')
                      group by oot.ons_reg_id
                      )oot on oot.ons_reg_id = oaw.apply_id
           left join (SELECT oaw.apply_id,
                             oaw.jieban_time,
                             row_number() over(partition by oaw.apply_id,oaw.worker_type order by oaw.jieban_time nulls first) rn
                      FROM ons_apply_worker oaw
                      inner join (SELECT a.id,a.scheduled_date FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = oaw.apply_id
                      )oaw1 on oaw1.apply_id = oaw.apply_id and oaw1.rn = oaw.rn + 1
            ) info

```

###### 护理获取时间节点

```sql
left join (SELECT oper.ons_reg_id,
                  max(case when oper.TIME_NODE_ID = 'n1' then oper.NODE_TIME end) 入室时间,
                  max(case when oper.TIME_NODE_ID = 'n10' then oper.NODE_TIME end) 手术结束
           FROM ONS_OPER_TIME oper
           inner join sam_apply a on oper.ons_reg_id = a.id 
                 and a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss')
           WHERE oper.TIME_NODE_ID in ('n1','n10')
           group by oper.ons_reg_id
           )oper on oper.ons_reg_id = a.id--获取时间节点
left join (SELECT en.sam_apply_id,
                  max(case when en.OP_USE_STATE = '40' and en.rn = 1 then en.ordered_date end) 入室时间,
                  max(case when en.OP_USE_STATE = '70' and en.rn = 1 then en.ordered_date end) 手术结束
           FROM
           (SELECT en.sam_apply_id,
                   en.OP_USE_STATE,
                   en.ordered_date,
                   row_number() over(partition by en.sam_apply_id,en.OP_USE_STATE order by en.input_date desc) rn
           FROM SAM_ANAR_ENENT en
           inner join sam_apply a on en.sam_apply_id = a.id 
                 and a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss')
           WHERE en.OP_USE_STATE in ('40','70')
           )en
           group by en.sam_apply_id
           )en on en.sam_apply_id = a.id--获取时间节点
```



###### 手术名称&ICD-9

```sql
left join (SELECT sam_apply_id,
                  max(decode(rn,1,operation_name,null)) operation_name,
                  max(decode(rn,2,operation_name,null)) operation_name1,
                  max(decode(rn,3,operation_name,null)) operation_name2,
                  max(decode(rn,4,operation_name,null)) operation_name3,
                  max(decode(rn,1,OPERATION_CODE,null)) OPERATION_CODE
           FROM (select sam_apply_id,operation_name,OPERATION_CODE,
                        row_number() over(partition by sam_apply_id order by is_main_operation) rn
                 from sam_apply_op)
           group by sam_apply_id) aop on a.id = aop.sam_apply_id              
left join (select sam_reg_id,
                  max(decode(rn,1,operation_name,null)) operation_name,
                  max(decode(rn,2,operation_name,null)) operation_name1,
                  max(decode(rn,3,operation_name,null)) operation_name2,
                  max(decode(rn,4,operation_name,null)) operation_name3,
                  max(decode(rn,1,OPERATION_CODE,null)) OPERATION_CODE
           FROM (select sam_reg_id,operation_name,OPERATION_CODE,
                        row_number() over(partition by sam_reg_id order by is_main_operation) rn
                 from sam_reg_op)
           group by sam_reg_id) rop on reg.id = rop.sam_reg_id
left join icd_9_cm3 icd on icd.s_icd_9_cm3_dm=nvl(rop.operation_code,aop.operation_code)--ICD-9编码
```



###### 术前术后随访

```sql
--一台手术有多个访视
left join (select vi.apply_id applyid,max(valuejson(vi.visit_json, '"head_dead_date"')) 死亡时间
            from poiv_views vi
            where vi.create_date >= TO_DATE('${start}', 'yyyy-mm-dd hh24:mi:ss')
            and vi.type = 'VA'
            group by vi.apply_id) poiv on poiv.applyid = ar.sam_apply_id
```



###### 职员名单（护士、麻醉医生、主刀）

```sql
left join (SELECT * 
           FROM (select sam_reg_id,
                  max(SCRUB_NURSE_01) SCRUB_NURSE_01,max(SCRUB_NURSE_02) SCRUB_NURSE_02,--洗手
                  max(circuit_nurse_01) circuit_nurse_01,max(circuit_nurse_02) circuit_nurse_02--巡回
                 from sam_reg_op group by sam_reg_id
                 ) rop
           unpivot (姓名ID for 职员 in (SCRUB_NURSE_01 as '洗手1',SCRUB_NURSE_02 as '洗手2',circuit_nurse_01 as '巡回1',circuit_nurse_02 as '巡回2'))
           )rop on a.id = rop.sam_reg_id--护士工作量使用
left join hrm_employee hs on hs.id=rop.姓名ID--护士姓名：护士工作量使用

left join (SELECT * 
           FROM (select sam_reg_id,max(operator_doctor_id)operator_doctor_id,
                  max(operator_assistant_1) operator_assistant_1,max(operator_assistant_2) operator_assistant_2,
                  max(operator_assistant_3) operator_assistant_3
                 from sam_reg_op group by sam_reg_id
                 ) rop
           unpivot (姓名ID for 职员 in (operator_doctor_id as '主刀',operator_assistant_1 as '主刀1助',operator_assistant_2 as '主刀2助',operator_assistant_3 as '主刀3助'))
           )rop on a.id = rop.sam_reg_id--手术医生工作量使用
left join hrm_employee zd on zd.id=rop.姓名ID--手术医生姓名：手术医生工作量使用

left join (SELECT sam_reg_id,姓名ID,职位
           FROM (select sam_reg_id,narcotic_doctor_id,narcotic_assistant_1,narcotic_assistant_2,narcotic_assistant_3
                 from sam_reg_op
                 WHERE is_main_operation='1'
                 ) rop
           unpivot (姓名ID for 职位 in (narcotic_doctor_id as '主麻',narcotic_assistant_1 as '一助',narcotic_assistant_2 as '二助',narcotic_assistant_3 as '三助'))
           )rop on a.id = rop.sam_reg_id--麻醉医生工作量使用
left join hrm_employee mz on mz.id=rop.姓名ID--麻醉医生姓名：麻醉医生工作量使用
```

###### 麻醉效果

```sql
left join (select r.sam_apply_id,max(n.node_value) mzxg
               from sam_emr_rec r
               left join sam_emr_rec_nv n
                 on n.sam_emr_rec_id = r.id
              where r.rss_emr_ver_id = 'huaxi_mzzl'
                and n.node_name = 'AnestheticEffect'
                and n.node_value is not null
              group by r.sam_apply_id) mzxg on mzxg.sam_apply_id = a.id--麻醉质量评估的麻醉效果
```

###### 交接工作时长—麻醉医生

```sql
--麻醉医生有交接  
left join(SELECT mzjjb.sam_apply_id,max(ar.ana_beging_date),max(ar.ana_end_date),
                max(case when mzjjb.交接顺序=1 then nvl(mzjjb.交班用户,mzjjb.交班用户ID) else null end) 排班医生,
                max(case when mzjjb.交接顺序=1 then to_char(round((mzjjb.交班时间-ar.ana_beging_date)*24,1),'fm9999999999999990.0') else null end) 排班医生上班时长,
                listagg(nvl(mzjjb.接班用户,mzjjb.接班用户ID),'+') within group(order by mzjjb.交接顺序) 接班医生,--样式：江雪+甘正权+江雪+甘正权+江雪+甘正权
                listagg((case when mzjjb.交接顺序<>1 then to_char(round((mzjjb.交班时间-mzjjb.交班人上班时间)*24,1),'fm9999999999999990.0') else null end),'+') within group(order by mzjjb.交接顺序)||max(nvl('+'||(case when mzjjb.交接倒序=1 then to_char(round((ar.ana_end_date-mzjjb.交班时间)*24,1),'fm9999999999999990.0') else null end),'')) 交班医生上班时长--样式：0.4+0.3+0.8+2.2+0.2+21.2
                FROM(select r.sam_apply_id,r.id,
                           max(decode(n.node_name,'jiaobanuser',n.node_value,null)) 交班用户ID,
                           max(decode(n.node_name,'jiaobanusername',n.node_value,null)) 交班用户,
                           max(decode(n.node_name,'jiebanuser',n.node_value,null)) 接班用户ID,
                           max(decode(n.node_name,'jiebanusername',n.node_value,null)) 接班用户,
                           to_date(max(decode(n.node_name,'jiaobantime',n.node_value,null)),'yyyy-mm-dd hh24:mi:ss') 交班时间,
                           to_date(max(decode(n.node_name,'jaobrensbtime',n.node_value,null)),'yyyy-mm-dd hh24:mi:ss') 交班人上班时间,
                           --max(decode(n.node_name,'jbuserisjieban',n.node_value,null)) 是否自己交接自己,--2否null自主交班；1和0不清楚；逻辑核定
                           rank() over(partition by r.sam_apply_id order by max(decode(n.node_name,'jaobrensbtime',n.node_value,null))) 交接顺序,
                           rank() over(partition by r.sam_apply_id order by max(decode(n.node_name,'jaobrensbtime',n.node_value,null)) desc) 交接倒序
                           from sam_emr_rec r
                           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
                           where r.rss_emr_type_id = 'huaxi_sam_jbjl'
                           group by r.sam_apply_id,r.id)mzjjb
                           left join sam_anar ar on ar.sam_apply_id=mzjjb.sam_apply_id
                           group by mzjjb.sam_apply_id)mzjjb on mzjjb.sam_apply_id=a.id 
```

###### 输血

```sql
--输血1
left join (SELECT en.sam_apply_id,listagg(en.szhss||decode(en.szhss,null,null,en.hsl)||pj.s_jldw_cmc,'+') within group(order by en.szhss) hs,listagg(en.yx||decode(en.yx,null,null,en.yxl)||pj1.s_jldw_cmc,'+') within group(order by en.yx) yx
          from (SELECT en.sam_apply_id,
                       (case when en.event_text='自体血' then en.event_text else null end) szhss,--自体血
                       sum(case when en.event_text='自体血' then en.single_dose else 0 end) hsl,(case when en.event_text='自体血' then en.single_dose_unit else null end) hsdw,--自体血单位
                       (case when en.event_text!='自体血' then en.event_text else null end) yx,--异血
                       sum(case when en.event_text!='自体血' then en.single_dose else 0 end) yxl,(case when en.event_text!='自体血' then en.single_dose_unit else null end) yxdw--异血单位
                FROM sam_anar_enent en WHERE  en.s_mzsjlb_dm='31' group by en.sam_apply_id,en.single_dose_unit,en.event_text)en
                left join pub_jldw pj on pj.s_jldw_dm = en.hsdw
                left join pub_jldw pj1 on pj1.s_jldw_dm = en.yxdw
                group by en.sam_apply_id)sx on sx.sam_apply_id=a.id
--输血2              
left join (select sae.sam_apply_id,
                  sum(case when pj.s_jldw_cmc in ('u','U','治疗量') then sae.single_dose * 200 else sae.single_dose end ) singledose
          from sam_anar_enent sae 
          left join pub_jldw pj on pj.s_jldw_dm = sae.single_dose_unit
          where sae.s_mzsjlb_dm = '31'
          group by sae.sam_apply_id) sx on sx.sam_apply_id = a.id
```

###### 出血

```sql
left join (select sae.sam_anar_id,
                  sum(case when pj.s_jldw_cmc = 'u' then sae.single_dose * 200 when pj.s_jldw_cmc = 'U' then sae.single_dose * 200 when pj.s_jldw_cmc = '治疗量' then sae.single_dose * 200  else sae.single_dose end) singledose
           from sam_anar_enent sae 
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = sae.sam_apply_id
           left join pub_jldw pj on pj.s_jldw_dm = sae.single_dose_unit
           where sae.s_mzsjlb_dm = '40' and sae.s_mzsj_dm ='40_2' --and sae.event_text ='血量'
           group by sae.sam_anar_id) chuxueinfo on chuxueinfo.sam_anar_id = ar.id--出血
```

###### 神经阻滞

```sql
--神经阻滞
left join (select r.sam_apply_id,max(n.cjq) cjq,max(n.csyd) csyd,listagg(n.zzfs,';') within group(order by r.sam_apply_id) zzfs
          from sam_emr_rec r
          left join (SELECT n.sam_emr_rec_id,decode(n.node_name,'ORDERED_DATE',n.node_value) ORDERED_DATE,
          listagg((case when n.node_name in ('JCSJZZ','BCSJZZ','YCSJZZ','ZGSJZZ','GWCPSJZZ','QJMZZ','GSJZZ','WGZZ2','HZZ2','BKSJZZ','TPSJZZ','TAPZZ','ZPZZ','FZJQSJZZ','YFJSJZZ','QJJZZ','QT_ZZBW') then n.node_value else null end), '+') within group(order by n.sam_emr_rec_id) zzfs,--阻滞方式
          sum(case when n.node_name in ('JCSJZZ','BCSJZZ','YCSJZZ','ZGSJZZ','GWCPSJZZ','QJMZZ','GSJZZ','WGZZ2','HZZ2','BKSJZZ','TPSJZZ','TAPZZ','ZPZZ','FZJQSJZZ','YFJSJZZ','QJJZZ','QT_ZZBW') then 1 else 0 end) zzcs,--阻滞次数
          max(decode(n.node_name,'SJCJQ',n.node_value)) cjq,--刺激器
          max(decode(n.node_name,'CSYD',n.node_value)) csyd--超声引导
          from sam_emr_rec_nv n
          group by n.sam_emr_rec_id,decode(n.node_name,'ORDERED_DATE',n.node_value)
          )n on n.sam_emr_rec_id = r.id
          where r.rss_emr_type_id='sam_sjzz'
          and n.zzcs>0
          group by r.sam_apply_id)sjzz on sjzz.sam_apply_id=a.id
          
--神经阻滞
inner join (select r.sam_apply_id,n1.node_value zzsj,--阻滞时间
                   sum(case when n.node_name in ('JCSJZZ','BCSJZZ','YCSJZZ','ZGSJZZ','GWCPSJZZ','QJMZZ','GSJZZ','WGZZ2','HZZ2','BKSJZZ','TPSJZZ','TAPZZ','ZPZZ','FZJQSJZZ','YFJSJZZ','QJJZZ','QT_ZZBW') then 1 else 0 end) zzcs--阻滞次数
            from sam_emr_rec r
            inner join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id and n.node_name in ('JCSJZZ','BCSJZZ','YCSJZZ','ZGSJZZ','GWCPSJZZ','QJMZZ','GSJZZ','WGZZ2','HZZ2','BKSJZZ','TPSJZZ','TAPZZ','ZPZZ','FZJQSJZZ','YFJSJZZ','QJJZZ','QT_ZZBW') and n.node_value is not null--阻滞种类
            inner join sam_emr_rec_nv n1 on n1.sam_emr_rec_id = r.id and n1.node_name = 'ORDERED_DATE'--阻滞时间
            where r.rss_emr_type_id='sam_sjzz'
            group by r.sam_apply_id,n1.node_value)sjzz on sjzz.sam_apply_id=a.id
```



###### 入恢复室

```sql
left join (SELECT rs.sam_apply_id FROM sam_anar_enent rs where rs.s_mzsj_dm='' group by rs.sam_apply_id)rs on rs.sam_apply_id=a.id
```

###### 血气分析

```sql
inner join(SELECT VS.SAM_ANAR_ID,
                  VS.TIME_POINT 血气分析时间,
                  LISTAGG(VS.VSPD_NAME||':'||VS.VSPD_VALUE,';') WITHIN GROUP(ORDER BY VS.TIME_POINT,VS.VSPD_NAME) 血气结果
           FROM SAM_ANAR_VS VS 
           inner join SAM_ANAR AR on AR.IN_OPROOM_DATE BETWEEN  TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss') and vs.sam_anar_id = ar.id
           inner join sam_anar_vspd vspd on VS.sam_anar_vspd_id = vspd.id and vspd.curve_type in ('pH','PCO2','PO2','Hct','Na','K','Ca','Glu','Lac','tHb','SO2','cHCO3','BE','Cl','COHb','BUN','nBili')
           where VS.is_display is null
           --and VS.SAM_ANAR_VS_DEV_ID is not null
           group by VS.SAM_ANAR_ID,VS.TIME_POINT)vs)vs on vs.sam_anar_id = ar.id--血气分析：每次详情
          
inner join(SELECT VS.SAM_ANAR_ID,
                  COUNT(distinct VS.TIME_POINT) 血气分析次数
           FROM SAM_ANAR_VS VS 
           inner join SAM_ANAR AR on AR.IN_OPROOM_DATE BETWEEN  TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss') and vs.sam_anar_id = ar.id
           inner join sam_anar_vspd vspd on VS.sam_anar_vspd_id = vspd.id and vspd.curve_type in ('pH','PCO2','PO2','Hct','Na','K','Ca','Glu','Lac','tHb','SO2','cHCO3','BE','Cl','COHb','BUN','nBili')
           where VS.is_display is null
           --and VS.SAM_ANAR_VS_DEV_ID is not null
           group by VS.SAM_ANAR_ID)vs on vs.sam_anar_id = ar.id--血气分析次数

```

###### 超声引导

```sql
left join (select r.sam_apply_id,
                  COUNT(*) 超声引导次数
           from sam_emr_rec r
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id in ('sam_sjzz','sam_zgnmz','sam_yccz')
           and n.node_name = 'CSYD'
           and n.node_value = '是' 
           group by r.sam_apply_id)csyd on csyd.sam_apply_id = a.id
```

###### 椎管内麻醉

```sql
left join (select r.sam_apply_id
           from sam_emr_rec r
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'sam_zgnmz'
           group by r.sam_apply_id)zgnmz on zgnmz.sam_apply_id = a.id--椎管内麻醉
```

###### 是否插管

```sql
left join (select r.sam_apply_id
           from sam_emr_rec r
           inner join (SELECT ar.sam_apply_id FROM sam_anar ar WHERE ar.oper_beging_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.sam_apply_id = r.sam_apply_id
           where r.rss_emr_type_id in ('sam_ist_pipe','sam_hz')
           group by r.sam_apply_id)cg on cg.sam_apply_id = a.id
```



###### 双腔插管

```sql
left join (select r.sam_apply_id,
                  COUNT(*) 双腔管次数
           from sam_emr_rec r
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'sam_ist_pipe'
           and n.node_name = 'EVENT_TEXT'
           and n.node_value = '双腔气管插管' 
           group by r.sam_apply_id)sq on sq.sam_apply_id = a.id
```

###### 喉罩

```sql
left join (select r.sam_apply_id,
                  COUNT(*) 喉罩次数
           from sam_emr_rec r
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = r.sam_apply_id
           where r.rss_emr_type_id = 'sam_hz'
           group by r.sam_apply_id)hz on hz.sam_apply_id = a.id
           
--喉罩
left join (select r.sam_apply_id
           from sam_emr_rec r
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'sam_hz'
           group by r.sam_apply_id)hz on hz.sam_apply_id = a.id
```



###### 有创

```sql
--主表
--静脉
left join (select r.sam_apply_id
           from sam_emr_rec r
           inner join (SELECT ar.sam_apply_id FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.sam_apply_id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id='sam_yccz'
           and n.node_name in ('JN', 'SGX', 'JDM','JWJM')
           and n.node_value is not null 
           group by r.sam_apply_id) jm on jm.sam_apply_id = a.id
--动脉
left join (select r.sam_apply_id
           from sam_emr_rec r
           inner join (SELECT ar.sam_apply_id FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.sam_apply_id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where  r.rss_emr_type_id='sam_yccz'
           and n.node_name in ('RDM','GDM','GONG_DM','ZBDM','CDM','JDM_DM','ZDY_DM_NAME')
           and n.node_value is not null                 
           group by r.sam_apply_id) dm on dm.sam_apply_id = a.id	
           
--明细表
left join (select r.sam_apply_id,listagg(decode(n.node_name,'JN','颈内','SGX','锁骨下','JDM','股静脉','JWJM','颈外静脉'),';') within group(order by n.node_name) mc
           from sam_emr_rec r
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id='sam_yccz'
           and n.node_name in ('JN', 'SGX', 'JDM','JWJM')
           and n.node_value is not null 
           group by r.sam_apply_id) jm on jm.sam_apply_id = info.apply_id
left join (select r.sam_apply_id,listagg(decode(n.node_name,'RDM','桡动脉','GDM','股动脉','GONG_DM','肱动脉','ZBDM','足背动脉','CDM','尺动脉','JDM_DM','胫后动脉','ZDY_DM_NAME','自定义的名字'),';') within group(order by n.node_name) mc
           from sam_emr_rec r
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id='sam_yccz'
           and n.node_name in ('RDM','GDM','GONG_DM','ZBDM','CDM','JDM_DM','ZDY_DM_NAME')
           and n.node_value is not null                 
           group by r.sam_apply_id) dm on dm.sam_apply_id = info.apply_id
```

###### 患者去向

```sql
left join (select max(en.tw_place) tw_place,en.sam_apply_id from sam_anar_enent en where en.s_mzsjlb_dm='10' and en.event_text='出手术室' and en.is_rec_enent='2' group by en.sam_apply_id)csqx on csqx.sam_apply_id=a.id
left join hra00_department de1 on de1.id = csqx.tw_place
```

###### 体征体温

```sql
left join (SELECT vs.sam_anar_id,
                  max(case when vs.is_rec_event = '2' and vs.rn = '1' then vs.vspd_value else null end) a,--手术室开始体温
                  min(case when vs.is_rec_event = '2' then to_number(vs.vspd_value) else null end) b,--手术室最低体温
                  sum(case when vs.is_rec_event = '2' and to_number(vs.vspd_value) < 36 then 1 else 0 end)*5 c,--麻醉单上（术中）低于36的点数*5
                  max(case when vs.is_rec_event = '1' and vs.rn = '1' then vs.vspd_value else null end) d,--恢复室开始体温
                  max(case when vs.is_rec_event = '1' and vs.rn_dx = '1' then vs.vspd_value else null end) e,--恢复室最后一次体温
                  min(case when vs.is_rec_event = '2' and vs.rn_sj = '1' then vs.time_point else null end) f--手术室最低体温
           FROM (SELECT vs.sam_anar_id,
                        vs.is_rec_event,
                        (ROW_NUMBER() OVER(PARTITION BY vs.sam_anar_id,vs.is_rec_event ORDER BY vs.time_point)) rn,--获取体温值by时间点顺序
                        (ROW_NUMBER() OVER(PARTITION BY vs.sam_anar_id,vs.is_rec_event ORDER BY vs.time_point desc)) rn_dx,--获取体温值by时间点逆顺
                        (ROW_NUMBER() OVER(PARTITION BY vs.sam_anar_id,vs.is_rec_event ORDER BY to_number(vs.vspd_value))) rn_sj,--获取体温值对应时间值
                        vs.time_point,
                        vs.vspd_value
                 FROM sam_anar_vs vs WHERE vs.sam_anar_vspd_id in ('54','55','56')) vs
                 inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.id = vs.sam_anar_id
           group by vs.sam_anar_id
            ) vs on vs.sam_anar_id = ar.id--体温体征
```

###### 用药

```sql
inner join (SELECT en.sam_apply_id,
                   en.drug_id,
                   max(en.event_text) event_text,
                   max(nvl(en.specification,drm.specification)) specification,
                   max(en.batch_no) batch_no,
                   max(pj1.s_jldw_cmc) s_jldw_cmc,
                   max(ar.in_oproom_date) in_oproom_date,
                   sum(en.single_dose * 
                       (case when instr(j.s_jldw_cmc, '/h') > 0 then (case when en.duration is null then 1 else round((en.end_date -en.ordered_date) * 24, 2) end)
                             when instr(j.s_jldw_cmc, '/min') > 0 then (case when en.duration is null then 1 else round((en.end_date - en.ordered_date) * 24 * 60, 1) end)
                       else 1 end) * 
                       (case when instr(j.s_jldw_cmc, '/kg') > 0 then ar.weight else 1 end) * 
                       (case when en.density is not null then (to_number(en.density) * 10) else 1 end) * 
                       n.udu_du_scale) 使用剂量,
                   ceil(sum(en.single_dose * 
                        (case when instr(j.s_jldw_cmc, '/h') > 0 then (case when en.duration is null then 1 else round((en.end_date -en.ordered_date) * 24, 2) end)
                              when instr(j.s_jldw_cmc, '/min') > 0 then (case when en.duration is null then 1 else round((en.end_date - en.ordered_date) * 24 * 60, 1) end)
                        else 1 end) * 
                        (case when instr(j.s_jldw_cmc, '/kg') > 0 then ar.weight else 1 end) * 
                        (case when en.density is not null then (to_number(en.density) * 10) else 1 end) * 
                        n.udu_du_scale)/max(drm.single_dose_specification)) * max(drm.single_dose_specification) 处方剂量,
                   max(case when drm.PSYCO_TYPE = '10' then '精一'
                            when drm.PSYCO_TYPE = '20' then '精二'
                            when drm.POISONOUS_HEMP_FLAG = '1' then '麻醉药'
                            end) 药品种类
            from (SELECT ar.sam_apply_id,ar.in_oproom_date,ar.weight FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss'))ar
            inner join sam_anar_enent en on ar.sam_apply_id = en.sam_apply_id
            inner join drm_dictionary drm on drm.id = en.drug_id and(drm.POISONOUS_HEMP_FLAG = '1' or drm.PSYCO_TYPE in ('10', '20'))
            left join drm_nuu_ds n on n.id = en.single_dose_unit
            left join pub_jldw j on j.s_jldw_dm = n.udu
            left join pub_jldw pj1 on pj1.s_jldw_dm = drm.single_dose_unit
            where 1=1
            ${if(len(yaopin) > 0, "and en.event_text like '%" + yaopin + "%'", "")}
            ${if(fenlei ==3, "and drm.PSYCO_TYPE = '20'", "")}
            group by en.sam_apply_id,en.drug_id)en on en.sam_apply_id = a.id
--另一个用药
left join (select * from(select * from sam_anar_enent e where e.s_mzsjlb_dm='22')yy
            left join drm_dictionary drm on drm.id = yy.drug_id
  		   left join pub_jldw dw on dw.s_jldw_dm = drm.single_dose_unit--使用单位，计算用量后的
            left join drm_nuu_ds n on yy.single_dose_unit = n.id
            left join pub_jldw ja on drm.ip_min_drug_unit = ja.s_jldw_dm--展示单位（计费的单位）支
            left join pub_jldw j on n.udu = j.s_jldw_dm--换算单位（用量的单位）计算用量
          )yy on yy.sam_apply_id=a.id
          
left join pub_yytj pyj on pyj.s_yytj_dm = en.use_way --药品用法

--使用量&余量
inner join (SELECT t.sam_apply_id,
                   max(t.event_text) 药品,
                   max(t.batch_no) 批号,
                   trunc(sum(t.single_dose *
                   n.udu_du_scale *
                   (case when instr(j.s_jldw_cmc, '/h') > 0 then (case when t.duration is null then 1 else round((t.end_date -t.ordered_date) * 24, 2) end)
                   when instr(j.s_jldw_cmc, '/min') > 0 then (case when t.duration is null then 1 else round((t.end_date - t.ordered_date) * 24 * 60, 1) end)
                   else 1 end) *
                   (case when instr(j.s_jldw_cmc, '/kg') > 0 then sar.weight else 1 end) *
                   (case when t.density is not null then (to_number(t.density) * 10) else 1 end)
                   ),3) 用量,
                   ceil(sum(t.single_dose * 
                               (case when instr(j.s_jldw_cmc, '/h') > 0 then (case when t.duration is null then 1 else round((t.end_date -t.ordered_date) * 24, 2) end)
                                     when instr(j.s_jldw_cmc, '/min') > 0 then (case when t.duration is null then 1 else round((t.end_date - t.ordered_date) * 24 * 60, 1) end)
                               else 1 end) * 
                               (case when instr(j.s_jldw_cmc, '/kg') > 0 then sar.weight else 1 end) * 
                               (case when t.density is not null then (to_number(t.density) * 10) else 1 end) * 
                               n.udu_du_scale)/max(drm.single_dose_specification)) * max(drm.single_dose_specification) 处方量
            from sam_anar_enent t
            inner join sam_apply a on a.id = t.sam_apply_id 
                  and a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss')
            left join drm_dictionary drm on t.drug_id = drm.id
            left join drm_nuu_ds n on t.single_dose_unit = n.id
            left join pub_jldw j on j.s_jldw_dm = n.udu
            left join sam_anar sar on sar.id = t.sam_anar_id
            WHERE t.s_mzsjlb_dm = '22' 
            and (t.event_text like '%橼酸舒芬太尼注射液%' 
                or t.event_text like '%盐酸麻黄碱注射液%' 
                or t.event_text like '%马来酸麦角新碱注射液%' 
                or t.event_text like '%枸橼酸芬太尼注射液%')
            group by t.sam_apply_id,t.drug_id
            ) yy on yy.sam_apply_id = a.id
```

###### 毒麻药

```sql
left join(SELECT en.sam_anar_id,
                 listagg(en.event_text,'+') within group(order by en.ordered_date) ypmc,
                 listagg(en.drug_id,'+') within group(order by en.ordered_date) ypdm,
                 listagg(to_char(en.single_dose,'fm9999999999999990.0'),'+') within group(order by en.ordered_date) ypjl,
                 listagg(j.s_jldw_cmc,'+') within group(order by en.ordered_date) ypjl
          FROM (SELECT * FROM sam_anar_enent en WHERE en.s_mzsjlb_dm in ('22','32'))en
          inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.id = en.sam_anar_id--事件
          inner join drm_dictionary drm on drm.id = en.drug_id and (drm.POISONOUS_HEMP_FLAG = '1' or drm.PSYCO_TYPE in ('10','20'))
          left join drm_nuu_ds n on en.single_dose_unit = n.id
          left join pub_jldw j on n.udu = j.s_jldw_dm--换算单位（用量的单位）
group by en.sam_anar_id)dmy on dmy.sam_anar_id = ar.id--毒麻药
```



###### 镇痛泵（用药方式）

```sql
left join (SELECT en.sam_anar_id
           FROM sam_anar_enent en
           inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.id = en.sam_anar_id--事件
           WHERE en.s_mzsjlb_dm in ('22','32')
           and en.use_way='sm12'
           group by en.sam_anar_id)ztb on ztb.sam_anar_id = ar.id
```

###### 术中-镇痛泵使用

```sql
left join sam_ztb ztb on ztb.sam_apply_id = a.id--镇痛泵类型、使用方法
left join pub_mzsj ztbsj on ztb.ztb_type = ztbsj.s_mzsj_dm--镇痛泵名称
left join (SELECT ev.sam_apply_id,listagg(concat(concat(concat(ev.event_text,':'),to_char(ev.single_dose,'fm9999999999999990.0')),(case when instr(pj.s_jldw_cmc,'/')>0 then substr(pj.s_jldw_cmc,0,instr(pj.s_jldw_cmc,'/')-1) else pj.s_jldw_cmc end)), '；') within group(order by ev.event_text) ztpf
              FROM sam_anar_enent ev
              left join drm_nuu_ds dnd on dnd.id = ev.single_dose_unit
              left join pub_jldw pj on pj.s_jldw_dm = dnd.udu
              WHERE ev.enent_purpose = '镇痛泵' group by sam_apply_id)ev on ev.sam_apply_id = a.id--镇痛配方
              
left join (SELECT ev.sam_apply_id,
                  COUNT(*) 镇痛泵次数
           FROM sam_anar_enent ev
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = ev.sam_apply_id
           WHERE ev.enent_purpose = '镇痛泵' 
           group by sam_apply_id)ztb on ztb.sam_apply_id = a.id--镇痛配方
```

```sql
--走镇痛泵闭环
SELECT * FROM sam_ztb sz WHERE sz.status = '6'
--9：待确认；1：待审核；2：已审核；3：待取消；4：已取消；5：已接收；6：已使用
```



###### 恢复室护士

```sql
SELECT sam_apply_id,人员,职位,rec_in_date,ana_end_date
FROM (select r.sam_apply_id,
             max(case when n.node_name='MZHS1' then n.node_value else null end) MZHS1,
             max(case when n.node_name='MZHS2' then n.node_value else null end) MZHS2,
             max(case when n.node_name='MZHS3' then n.node_value else null end) MZHS3,
             max(case when n.node_name='MZHS4' then n.node_value else null end) MZHS4,
             max(ar.rec_in_date) rec_in_date,
             max(ar.rec_out_date) ana_end_date
      from sam_emr_rec r
      inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on r.sam_apply_id = ar.sam_apply_id
      left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
      where r.rss_emr_type_id = 'pacu_ssgd'
      and r.rss_emr_ver_id = '1'
      group by r.sam_apply_id
     )ws
unpivot (人员 for 职位 in (MZHS1 as 'PACU护士1',MZHS2 as 'PACU护士2',MZHS3 as 'PACU护士3',MZHS4 as 'PACU护士4'))
```

###### 填报

```sql
left join (select t.sam_apply_id,
           		  max(t.id) id,
                max(x.ph) ph
           from sam_emr_rec t
           inner join sam_apply a on t.sam_apply_id = a.id and a.scheduled_date between TO_DATE('${kssj}', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss')
           left join xmltable('/st/ph' passing
                              xmltype(t.cl_bc_xml) 　　　　
                              columns
                              ph varchar2(30) path 'text()'
                             )x on 1=1
           where t.rss_emr_type_id='sam_st_ph_tb' 
           group by t.sam_apply_id) tb on tb.sam_apply_id = a.id
```



###### 文书

```sql
left join (select r.sam_apply_id,
                  max(case when n.node_name='' and n.node_value='1' then 1 else null end) ,
                  max(case when n.node_name='' then n.node_value else null end) 
           from sam_emr_rec r
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'pacu_ssgd'
           and r.rss_emr_ver_id = ''
           --and n.node_name = ''
           --and r.sam_apply_id=''
           group by r.sam_apply_id)ws on ws.sam_apply_id = a.id
 
inner join (select r.sam_apply_id,
            	     max(case when n.node_name='' and n.node_value='1' then 1 else null end) ,
                   max(case when n.node_name='' then n.node_value else null end) 
            from sam_emr_rec r
            left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
            where r.rss_emr_type_id = 'pacu_ssgd'
            and r.rss_emr_ver_id = ''
            --and n.node_name = ''
            --and r.sam_apply_id=''
            group by r.sam_apply_id)ws on ws.sam_apply_id = a.id
 
select r.sam_apply_id,n.*
from sam_emr_rec r
left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
where r.rss_emr_type_id = 'pacu_ssgd'
--and r.rss_emr_ver_id = 'pacu_ssgd'
--and n.node_name = ''
--and r.sam_apply_id=''
```

###### 质控常见条件

```sql
--插管
and exists(SELECT 1 FROM sam_emr_rec r
           WHERE r.sam_apply_id = a.id 
       	   and r.rss_emr_type_id in ('sam_ist_pipe','sam_hz'))
       	   
--质量评估
inner join (select r.sam_apply_id
            from sam_emr_rec r
            inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE( '#start', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '#end', 'yyyy-mm-dd hh24:mi:ss' ))a on a.id = r.sam_apply_id
            left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
            where r.rss_emr_type_id in ('mzsqfs','sqfs')
            group by r.sam_apply_id)ws on ws.sam_apply_id = a.id
 
--质量评估	
inner join (select r.sam_apply_id
            from sam_emr_rec r
            inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE( '#start', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '#end', 'yyyy-mm-dd hh24:mi:ss' ))a on a.id = r.sam_apply_id
            left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
            where r.rss_emr_type_id = 'mzsqfs'
            and n.node_name = ''
            and n.node_value = ''
            group by r.sam_apply_id)ws on ws.sam_apply_id = a.id
        
--恢复室插管
where r.rss_emr_type_id = 'sam_ist_pipe_pacu'
        
--是否体温监测
and exists(SELECT 1 FROM sam_anar_vs vs 
           WHERE vs.sam_anar_id = ar.id 
       	   and vs.sam_anar_vspd_id in ('54','55','56') 
       	   and vs.is_rec_event = '2')

--事件：保温   	   
and exists(SELECT 1 FROM sam_anar_enent en 
           where en.sam_apply_id = a.id
           and en.event_text like '保温毯加温%'
           and en.is_rec_enent = '2')
           
--非计划转入ICU	
and exists(SELECT 1 FROM sam_anar_enent en 
           where en.sam_apply_id = a.id
           and en.tw_place  like '%icuOutPlan%')
           
--该测温点往后30分钟连续低体温
and exists(select 1 from sam_anar_vs v
           left join (SELECT v.sam_anar_id,v.vspd_value tw,v.time_point
       	   from sam_anar_vs v 
       	   where v.sam_anar_vspd_id in ('54','55','56')
       	   )info on info.time_point between v.time_point and v.time_point+30/(24*60) and info.sam_anar_id=v.sam_anar_id and info.tw>='36'--往后30分钟存在大于等于36的体温就不算
           where v.sam_anar_id = ar.id
           and v.sam_anar_vspd_id in ('54','55','56')
           and exists(SELECT 1 FROM sam_anar_vs aa 
                      where aa.sam_anar_id = v.sam_anar_id 
                      and aa.time_point >= v.time_point+30/(24*60))--该点存在往30分钟后的其他体温
           and info.sam_anar_id is null)
           
--恢复室入室低体温
inner join (select r.sam_apply_id
            from sam_emr_rec r
            inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE( '#start', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '#end', 'yyyy-mm-dd hh24:mi:ss' ))a on a.id = r.sam_apply_id
            left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
            where r.rss_emr_type_id = 'pacu_ssgd'
            and n.node_name = 'IN_PACU_TEMP'
            and to_number(n.node_value) < '36'
            group by r.sam_apply_id)ws on ws.sam_apply_id = a.id
            
--择期术前访视
and nvl(reg.is_emergency,a.is_emergency) !='1'
and exists(select 1 from poiv_views vi WHERE vi.apply_id = a.id and vi.type='VB')

--术后镇痛满意率VAS≦3
--活动疼痛评分：head_mvsa
--静息疼痛评分：head_rvsa
--总体疼痛评分：pca_gvsa
and exists(select 1 
           from poiv_views vi 
           WHERE vi.apply_id = a.id 
           and vi.type='VA'
           and valuejson(vi.visit_json,'"head_mvsa"') between 0 and 3)
           
--是否使用镇痛泵
and exists (select 1 
            from sam_ztb ztb 
            where ztb.sam_apply_id = a.id 
            and ztb.status = '6')
```

###### 插拔管

```sql
left join (select r.sam_apply_id
           from sam_emr_rec r
           inner join (SELECT a.id FROM sam_apply a WHERE a.scheduled_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))a on a.id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where  r.rss_emr_type_id='sam_ist_pipe'
           and n.node_name = 'EVENT_TEXT'
           and n.node_value like '%%'           
           group by r.sam_apply_id) cg on cg.sam_apply_id = a.id--插管

left join (SELECT sam_apply_id,listagg(插管详情,chr(10)) within group(order by ORDERED_DATE) cgsj 
           FROM(SELECT info_cg.sam_apply_id,
                       (case when info_cg.S_MZSJLB_DM = '71' then info_cg.ORDERED_DATE || ' 插管(' || info_cg.S_MZSJ_CMC || ',型号:' || info_cg.XH_CMC || ',深度:' || info_cg.CGSD || 'cm)' else null end) cg,
                       (case when info_cg.S_MZSJLB_DM = '76' then info_cg.ORDERED_DATE || ' 面罩(' || info_cg.S_MZSJ_CMC || decode(info_cg.XH_CMC,null,null,',型号:' || info_cg.XH_CMC) || ')' else null end) mz,
                       (case when info_cg.S_MZSJLB_DM = '74' then info_cg.ORDERED_DATE || ' 喉罩(' || info_cg.S_MZSJ_CMC || decode(info_cg.XH_CMC,null,null,',型号:' || info_cg.XH_CMC) || ')' else null end) hz,
                       ORDERED_DATE
          FROM (select r.sam_apply_id,
                       max(case when n.node_name='S_MZSJLB_DM' then n.node_value else null end) S_MZSJLB_DM,
                       max(case when n.node_name='S_MZSJ_CMC' then n.node_value else null end) S_MZSJ_CMC,
                       max(case when n.node_name='XH_CMC' then n.node_value else null end) XH_CMC,
                       max(case when n.node_name='ORDERED_DATE' then substr(n.node_value,12,5) else null end) ORDERED_DATE,
                       max(case when n.node_name='CGSD' then n.node_value else null end) CGSD
          from sam_emr_rec r
          --inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.sam_apply_id = r.sam_apply_id
          left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
          where r.rss_emr_type_id in ('sam_ist_pipe','sam_hz','sam_mz')
          group by r.sam_apply_id,r.id)info_cg
          )unpivot (插管详情 for 类型 in (cg as 'cg',
                                          mz as 'mz',
                                          hz as 'hz'))
          group by sam_apply_id)cg on cg.sam_apply_id=a.id--插管信息

left join (select r.sam_apply_id,min(n.node_value) cgsj--首次插管时间
           from sam_emr_rec r
           inner join (SELECT ar.sam_apply_id FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.sam_apply_id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'sam_ist_pipe'
           and n.node_name = 'ORDERED_DATE'
           group by r.sam_apply_id)cg on cg.sam_apply_id=a.id--插管时间
left join (select en.sam_anar_id,
                  --max(en.tw_place) tw_place,--去向
                  --min(en.ORDERED_DATE) zx,--首次拔管时间
                  max(en.ORDERED_DATE) zd--末次拔管时间
                  --count(*) bg--拔管次数
           from sam_anar_enent en
           inner join (SELECT ar.id FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.id = en.sam_anar_id
           where en.op_use_state = '400'
           group by en.sam_anar_id) bg on bg.sam_anar_id=ar.id--拔管
left join (select r.sam_apply_id,
                  min(n.node_value) cgsj--首次插管时间
           from sam_emr_rec r
           inner join (SELECT ar.sam_apply_id FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.sam_apply_id = r.sam_apply_id
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id in ('sam_ist_pipe','sam_hz','sam_mz','sam_repe_Pipe')
           and n.node_name = 'ORDERED_DATE'
           group by r.sam_apply_id)cg on cg.sam_apply_id=a.id--建立人工气道
```

###### 麻醉非预期

```sql
left join (select r.sam_apply_id,
           max(decode(n.node_name,'QMQG','是','否')) QMQG,--全麻气管拔管后声音嘶哑
           max(decode(n.node_name,'RCCG','是','否')) RCCG,--非计划二次插管
           max(decode(n.node_name,'QSMZYW','是','否')) QSMZYW,--全身麻醉结束时是否使用吹醒药物
           max(decode(n.node_name,'ZRICU','是','否')) ZRICU,--非计划转入ICU
           max(decode(n.node_name,'SZZX','是','否')) SZZX,--术中知晓
           max(decode(n.node_name,'YCSS','是','否')) YCSS--术中牙齿损伤
           from sam_emr_rec r
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'pacu_fyqsj'
           and r.rss_emr_ver_id='1'
           group by r.sam_apply_id)mzfyq on mzfyq.sam_apply_id = a.id
```

###### 血液字典

```sql
left join (SELECT mzsj.s_mzsj_dm,mzsj.s_mzsj_cmc,pj2.s_jldw_cmc 
            FROM pub_mzsj mzsj 
            left join pub_jldw pj2 on pj2.s_jldw_dm = mzsj.single_dose_unit
            WHERE mzsj.s_mzsjlb_dm='31' --输血
            and mzsj.s_sfyx='1' --有效
            and mzsj.health_service_org_id='RSS20171211000000001' --机构
          )mzsj on mzsj.s_mzsj_dm=en.s_mzsj_dm
```



##### 条件块

###### 常见条件

```sql
--
${if( == '',"and . = '" +  + "'","")}
--
${if(len() > 0,"and . = '" +  + "'","")}
--院区
${if(len(yuanqu) > 0, "and nvl(reg.health_service_org_id,a.health_service_org_id) = '" + yuanqu + "'", "")}
--患者科室
${if(len(keshi) > 0, "and de.department_chinese_name = '" + keshi + "'", "")}
--接收科室
${if(len(jsks) > 0, "and jsks.department_chinese_name ='" + jsks + "'", "")}
--申请科室
${if(len(sqks) > 0, "and req.department_chinese_name ='" + sqks + "'", "")}
--住院号
${if(len(zyh) > 0, "and nvl(ipi.ipi_registration_no,opc.opc_registration_no) = '" + zyh + "'", "")}
where 1 = 1
--患者姓名
${if(len(hzxm) > 0,"and nvl(reg.patient_name,a.patient_name) = '" + hzxm + "'","")}
--住院号
${if(len(zyh) > 0, "and ipi.ipi_registration_no = '" + zyh + "'","")}
--麻醉医生
${if(len(mzys) > 0, "and mz.id = '" + mzys + "'", "")}
--麻醉方式
${if(len(mzfs) > 0, "and nvl(mzfs.mzfsCmc,mzfs2.s_mzfs_cmc) like '%" + mzfs + "%'","")}
--主刀医生
${if(len(zdys) > 0, "and zd.id = '" + zdys + "'", "")}
--麻醉助手
${if(len(mzzs) > 0, "and mzzs1.id = '" + mzzs + "'", "")}
--麻醉护士
${if(len(mzhs) > 0, "and mzhs1.id = '" + mzhs + "'", "")}
--手术间
${if(len(room) > 0, "and rm.oper_room = '" + room + "'", "")}
--是否计费:from ipc_drug_presc_d dd left join ipc_drug_presc_h dh on dh.id = dd.drug_presc_h_id
${if(jf == '是',"and dh.s_jfzt_dm not in ('10','30','50')","")}
${if(jf == '否',"and dh.s_jfzt_dm in ('10','30','50')","")}

and a.s_sssyzt_dm ='90'--手术完成
and (a.is_reject is null or a.is_reject = '2')--未取消手术
and a.oper_type = 'ROOM_OPER'
and nvl(reg.is_emergency,a.is_emergency) = '2'--择期
and a.oper_type in ('ROOM_OPER','BED_OPER')--住院和门诊
--排班前取消:0;排班后入室前取消:9;正常手术:2/null;3: 审核不通过;4: 入手术室后取消手术或取消麻醉;5: 麻醉科原因取消手术;
--6: 也是麻醉科原因取消，但是在我们手麻业务上面有一点区别;7: 护理取消;8: 资阳市人民医院单独提的 入室后停止(未实施麻醉);
(case when (a.is_reject is null or a.is_reject = '2') then '正常手术' 
      when a.is_reject = '9' then '排班后入室前取消'
      when a.is_reject = '3' then '审核不通过'
      when a.is_reject = '4' then '入手术室后取消手术或取消麻醉'
      when a.is_reject in ('5','6') then '麻醉科原因取消手术'
      when a.is_reject = '7' then '护理取消'
      when a.is_reject = '8' then '入室后停止(未实施麻醉)'
      when a.is_reject = '0' then '排班前取消'
      end) 手术取消
and nvl(rop.is_main_operation,aop.is_main_operation)='1'--主手术
```

###### 质控条件

```sql
--文书
	   and exists (select 1 
                    from sam_emr_rec r 
                    where r.sam_apply_id = a.id 
                    and r.rss_emr_type_id = 'sam_sqfsd')
                    
--插管
	   and exists (select 1 
                    from sam_emr_rec r 
                    where r.sam_apply_id = a.id 
                    and r.rss_emr_type_id in ('sam_ist_pipe','sam_hz','sam_repe_Pipe'))
                    
--文书节点
        and exists (select 1 
                    from sam_emr_rec r 
                    inner join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id 
                    and n.node_name = 'zb33'
                    and n.node_value = '1'
                    where r.sam_apply_id = a.id 
                    and r.rss_emr_type_id = 'hxmzzl'
                    and r.rss_emr_ver_id = 'huaxi_mzzl')
--事件
        and exists (select 1 
                    from sam_anar_enent en 
                    WHERE en.sam_apply_id = a.id
                    and en.event_text = '心脏停跳'
                    and en.is_rec_enent <> '1')
                    
--事件
        and exists (select 1 
                    from sam_anar_enent en 
                    WHERE en.sam_apply_id = a.id
                    and en.event_text like '%麻醉过敏%'
                    and en.is_rec_enent <> '1')
--麻醉方式        
    left join (select r.sam_apply_id,
                      max(case when n.node_name = 'DM' and n.node_value like '01%' then 1 end) mzfsDm,
                      listagg((case when n.node_name = 'S_MZFS_DM' then n.node_value end), ';') within group(order by n.id) mzfsCmc
           from sam_emr_rec r
           inner join sam_apply a on r.sam_apply_id = a.id
           and a.scheduled_date between TO_DATE( '#start', 'yyyy-mm-dd hh24:mi:ss' ) AND TO_DATE( '#end', 'yyyy-mm-dd hh24:mi:ss' ) 
           left join sam_emr_rec_nv n
             on n.sam_emr_rec_id = r.id
          where r.rss_emr_type_id = 'sam_mzfs'
            and n.node_name in ('S_MZFS_DM','DM')
          group by r.sam_apply_id) mzfs
   on mzfs.sam_apply_id = info.apply_id
   left join pub_mzfs2 mzfs2 on mzfs2.s_mzfs_dm = info.s_mzfs_dm
WHERE (mzfs.mzfsDm = 1 or (mzfs.sam_apply_id is null and info.s_mzfs_dm like '02%'))
```



###### 时间筛选条件

```sql
--年月
from (SELECT * FROM sam_anar ar WHERE ar.IN_OPROOM_DATE between TO_DATE('${year1}'||'-'||'${month1}'||'-01', 'yyyy-mm-dd') AND last_day(TO_DATE('${year1}'||'-'||'${month1}'||'-01','yyyy-mm-dd')+1-1/86400))ar
--年月日
from (SELECT ar.in_oproom_date,ar.sam_apply_id FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss'))ar
```



##### 模板块

说明：用来记录常用的报表下拉控件的sql。

```sql
Sunbing9@
${kssj}_${jssj}--标题设置导出时带日期
标题颜色：99ccff
合计：ccccff
普通行背景：eeeeee； 条件属性：row() % 2 = 0
彩色行背景：ffccff、ccffcc
标题大小：18号字、加粗居中
行标题：11号加粗居中
内容：10号居中；
合计：10号加粗居中
蓝紫：aec3ff
灰：d9d9d9
绿：6fddb2
粉红:ffccff

months_between(sysdate,sysdate)

条件属性公式：
row() % 2 = 0
len(B3) = 0

判断表格数据公式：
sum(MAPARRAY(a6,if(find($endDate,item)>0,b6,0)))

to_date('1900-01-01 00:00:00','yyyy-mm-dd hh24:mi:ss')

填报ID：
IF(ISNULL(a3),UUID(32),a3)

 + 86399/86400

行变色：加载结束
8：https://bbs.fanruan.com/wenda/question/156975.html
11：_g().addEffect('highlightRow',{
	color: 'red',
	trigger: 'mousedown',
	single:false
});

coalesce():同nvl();

填报成功刷新：
setTimeout(function() {
	_g().refreshAllSheets();
}, 500)

填报优化
var row = FR.cellStr2ColumnRow(this.options.location).row + 1;//获取当前行号
_g().setCellValue('K' + row, null, 1);//给当前行的L列单元格赋值

帆软函数使用
时间时长计算：
DATESUBDATE(S3, R3, "h") + "小时" + DATESUBDATE(S3, R3, "m") % 60 + "分"
floor(3661/3600)+"时"+floor(Mod(3661,3600)/60)+"分"+floor(Mod(3661,60))+"秒"
获取天数与字符串截取：
DATEDIF(B4,left(R4,10),'D')
参数去掉分页：sssqdbb.cpt&__bypagesize__=false

手麻系统操作参数：openMzjldOperationAuth

I、II、III、IV、V、VI

点击查询：
$(function() {
  $('button.fr-btn-text:contains("查询")').trigger('click');
});

$(function() {
  $('button.fr-btn-text').each(function() {
    if ($(this).text().trim() === "查询") {
      $(this).trigger('click');
    }
  });
});

当月最后一天：
concatenate(DATEDELTA(MONTHDELTA(DATEINMONTH(TODAY(),1),1),-1),' 23:59:59')
当月第一天：
concatenate(DATEINMONTH(TODAY(),1),' 00:00:00')
上月第一天：
concatenate(MONTHDELTA(DATEINMONTH(TODAY(),1),-1),' 00:00:00')
上月最后一天：
concatenate(DATEDELTA(DATEINMONTH(TODAY(),1),-1),' 23:59:59')
上月：
MONTHDELTA(TODAY(),-1) 
时间为月时：
WHERE ar.rec_in_date between to_date(concat('${kssj}','/01 00:00:00'),'yyyy/mm/dd hh24:mi:ss') and to_date(concat(to_char(last_day(to_date('${jssj}','yyyy-mm')),'yyyy/mm/dd'),' 23:59:59'),'yyyy/mm/dd hh24:mi:ss')

帆软列去重：
COUNT(UNIQUEARRAY(l3))
count(o4{o4='有'})
```

###### 医生

```sql
SELECT he.employee_name FROM hrm_employee he WHERE he.s_gzlb_dm = 'U05' order by he.employee_name

--主麻
SELECT distinct he.employee_name
FROM sam_anar ar 
left join sam_reg_op rop on rop.sam_reg_id = ar.sam_apply_id
left join hrm_employee he on he.id = rop.narcotic_doctor_id
WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss')
and he.employee_name is not null 
ORDER BY he.employee_name
--主麻&副麻
select mzem.employee_no mzdoc_id,
  mzem.employee_name mzys_name
  from (select distinct nvl(o.narcotic_doctor_id,aop.narcotic_doctor_id) mzdoc_id
        from sam_apply a
        left join sam_reg reg  on reg.id =  a.id 
        left join sam_reg_op o on reg.id = o.sam_reg_id 
        left join sam_apply_op aop on a.id = aop.sam_apply_id 
        where nvl(o.narcotic_doctor_id,aop.narcotic_doctor_id) is not null
        union 
        select distinct nvl(o.NARCOTIC_ASSISTANT_1,aop.NARCOTIC_ASSISTANT_1) mzdoc_id
        from sam_apply a
        left join sam_reg reg  on reg.id =  a.id 
        left join sam_reg_op o on reg.id = o.sam_reg_id 
        left join sam_apply_op aop on a.id = aop.sam_apply_id 
        where nvl(o.NARCOTIC_ASSISTANT_1,aop.NARCOTIC_ASSISTANT_1) is not null
        union
        select distinct nvl(o.NARCOTIC_ASSISTANT_2,aop.NARCOTIC_ASSISTANT_2) mzdoc_id
        from sam_apply a
        left join sam_reg reg  on reg.id =  a.id 
        left join sam_reg_op o on reg.id = o.sam_reg_id 
        left join sam_apply_op aop on a.id = aop.sam_apply_id 
        where nvl(o.NARCOTIC_ASSISTANT_2,aop.NARCOTIC_ASSISTANT_2) is not null
        union
        select distinct nvl(o.NARCOTIC_ASSISTANT_3,aop.narcotic_assistant_3) mzdoc_id
        from sam_apply a
        left join sam_reg reg  on reg.id =  a.id 
        left join sam_reg_op o on reg.id = o.sam_reg_id 
        left join sam_apply_op aop on a.id = aop.sam_apply_id 
        where nvl(o.NARCOTIC_ASSISTANT_3,aop.narcotic_assistant_3) is not null
  ) info  
  left join hrm_employee mzem on mzem.id = info.mzdoc_id
  order by SORT_ORDER
  
--主刀
select zdem.id,zdem.employee_name zdys_name
from (select distinct nvl(o.operator_doctor_id,aop.operator_doctor_id)zddoc_id
      from sam_apply a
      left join sam_reg reg  on reg.id =  a.id 
      left join sam_reg_op o on reg.id = o.sam_reg_id 
      left join sam_apply_op aop on a.id = aop.sam_apply_id 
      where nvl(o.operator_doctor_id,aop.operator_doctor_id) is not null) info  
left join hrm_employee zdem on zdem.id = info.zddoc_id
order by zdys_name
```

###### 护士

```sql
--巡回洗手
select mzem.employee_no mzdoc_id,
  mzem.employee_name mzys_name
  from (select distinct nvl(rop.scrub_nurse_01,aop.scrub_nurse_01) mzdoc_id
        from sam_reg_op rop
        left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id 
        where nvl(rop.scrub_nurse_01,aop.scrub_nurse_01) is not null
        union 
        select distinct nvl(rop.circuit_nurse_01,aop.circuit_nurse_01) mzdoc_id
        from sam_reg_op rop
        left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id 
        where nvl(rop.circuit_nurse_01,aop.circuit_nurse_01) is not null
        union 
        select distinct nvl(rop.scrub_nurse_02,aop.scrub_nurse_02) mzdoc_id
        from sam_reg_op rop
        left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id 
        where nvl(rop.scrub_nurse_02,aop.scrub_nurse_02) is not null
        union 
        select distinct nvl(rop.circuit_nurse_02,aop.circuit_nurse_02) mzdoc_id
        from sam_reg_op rop
        left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id 
        where nvl(rop.circuit_nurse_02,aop.circuit_nurse_02) is not null
  ) info  
  left join hrm_employee mzem on mzem.id = info.mzdoc_id
  order by SORT_ORDER
--麻醉护士
select distinct mzhs.employee_no mzdoc_id,mzhs.employee_name mzys_name,mzhs.sort_order
from sam_reg_op rop
left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id
left join hrm_employee mzhs on mzhs.id = nvl(rop.narcotic_nurse,aop.narcotic_nurse)
where nvl(rop.narcotic_nurse,aop.narcotic_nurse) is not null
order by mzhs.sort_order
```

###### 患者科室

```sql
select a.patient_dept_id id,dept.department_chinese_name department_chinese_name
from sam_apply a
left join hra00_department dept on a.patient_dept_id = dept.id
where a.patient_dept_id is not null
group by a.patient_dept_id,dept.department_chinese_name
order by max(SORT_ORDER)

--用这个
select t.id,t.department_chinese_name deptname
from hra00_department t
where  t.is_vaild = '1'
and t.department_nature in ('100','200', '300' ,'500')
order by deptname
```

###### 接受科室

```sql
select a.receive_dept_id id,dept.department_chinese_name department_chinese_name
from sam_apply a
left join hra00_department dept on a.receive_dept_id = dept.id
where a.patient_dept_id is not null
group by a.receive_dept_id, dept.department_chinese_name
order by max(SORT_ORDER)
```

###### 人员科室

```sql
--巡回洗手科室
select hsks.id,
       hsks.department_chinese_name
  from (select distinct nvl(rop.scrub_nurse_01,aop.scrub_nurse_01) mzdoc_id
        from sam_reg_op rop
        left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id 
        where nvl(rop.scrub_nurse_01,aop.scrub_nurse_01) is not null
        union 
        select distinct nvl(rop.circuit_nurse_01,aop.circuit_nurse_01) mzdoc_id
        from sam_reg_op rop
        left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id 
        where nvl(rop.circuit_nurse_01,aop.circuit_nurse_01) is not null
        union 
        select distinct nvl(rop.scrub_nurse_02,aop.scrub_nurse_02) mzdoc_id
        from sam_reg_op rop
        left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id 
        where nvl(rop.scrub_nurse_02,aop.scrub_nurse_02) is not null
        union 
        select distinct nvl(rop.circuit_nurse_02,aop.circuit_nurse_02) mzdoc_id
        from sam_reg_op rop
        left join sam_apply_op aop on rop.sam_reg_id = aop.sam_apply_id 
        where nvl(rop.circuit_nurse_02,aop.circuit_nurse_02) is not null
  ) info  
  left join hrm_employee mzem on mzem.id = info.mzdoc_id
  left join hra00_department hsks on hsks.id = mzem.department_id--工作人员科室
  order by hsks.sort_order
```

###### 院区

```sql
select org.id, org.organization_chinese_name
from sam_apply a
left join hra00_health_service_org org on org.id = a.health_service_org_id 
where org.organization_chinese_name is not null
group by org.id, org.organization_chinese_name
ORDER BY max(org.sort_order)
```

###### 药品

```sql
select id,DRUG_COMMON_NAME from drm_dictionary 
where ( POISONOUS_HEMP_FLAG = '1' or PSYCO_TYPE in (10, 20))
--分类
${if(fenlei ==3, "and PSYCO_TYPE = '20'","") }--精一
${if(fenlei ==2, "and PSYCO_TYPE = '10'","") }--精二
${if(fenlei == 1, "and POISONOUS_HEMP_FLAG = '1'","")}--麻醉药
ORDER BY sort_order
```

###### 手术间

```sql
select id, oper_room from sam_room order by SORT_ORDER
SELECT rm.id,rm.oper_room FROM sam_room rm where rm.is_rec_bed <> '1' ORDER BY rm.oper_room
```

###### 获取就近年份作为控件选项

```sql
select fint from (select level fint from dual connect by level <= to_number(to_char(sysdate,'yyyy'))) a where a.fint > to_number(to_char(sysdate,'yyyy'))-5 ORDER BY fint desc
```



##### 数据查看

###### 常用查询

```sql
 + 86399/86400
CDXTPASSWORD
http://172.17.100.114:8181/cdxt-sam/pages/cockpit/quality2022/quality2022_index.html?type=2&user=8081519f4a9b1d410000&dept=88ef50ae029780810e11&hospital=RSS20160520000000001&hospital_name=RSS20160520000000001&healthServiceOrgCode=723203231-1&loginuser=admin

--质控路径：
http://localhost/:8080/cdxt-sam/pages/cockpit/quality2022/quality2022_index.html?type=1&user=8081519f4a9b1d410000&dept=88ef50ae029780810e11&hospital=RSS20180628000000001&hospital_name=RSS20180628000000001&healthServiceOrgCode=723203231-1&loginuser=admin&gzType=U05
角色路径
/toUserSysFunc.do?user=8081519f4a9b1d410000&dept=88ef50ae029780810e11&hospital=RSS20180628000000001&hospital_name=RSS20180628000000001&healthServiceOrgCode=723203231-1&loginuser=AG123&gzType=U05&t=0.859290843639352

--护理工作站：
http://localhost:8080/cdxt-sam/pages/hlgzz/hlgzz_login.html
--文书字典表
SELECT * FROM rss_emr_ver aa WHERE aa.rss_emr_type_id='' and  aa.s_uiap like '%%';

--质控
select rowid ,a.* from sam_quality_2022 a where a.quality_name like '%%';
--质控更新语句
update sam_quality_2022 aa set aa.fenzi_sql = replace(aa.fenzi_sql,'and a.reject_reason is null','and (a.is_reject = ''2'' or a.is_reject is null)');
update sam_quality_2022 aa set aa.fenmu_sql = replace(aa.fenmu_sql,'and a.reject_reason is null','and (a.is_reject = ''2'' or a.is_reject is null)') ;

--获取指定表所有的列名
SELECT COLUMN_NAME
FROM ALL_TAB_COLUMNS
WHERE TABLE_NAME = 'SAM_REG';

--接台时长核心sql
(case when info1.op_time>1 then (info1.in_oproom_date - lag(info1.out_oproom_date, 1, info1.in_oproom_date) over(order by xuhao)) else 0 end) jtsc，
nvl(a.op_time,row_number() over(partition by rm.id,to_char(a.scheduled_date,'yyyy-mm-dd') order by ar.in_oproom_date,a.scheduled_date)) op_time

--时差
select (to_date('2023-04-17 12:40:00','yyyy-mm-dd hh24:mi:ss')-to_date('2023-04-17 12:40:00','yyyy-mm-dd hh24:mi:ss'))*24 from dual

select (to_date('2023/04/17 12:40:00','yyyy/mm/dd hh24:mi:ss')-to_date('2023/04/17 12:40:00','yyyy/mm/dd hh24:mi:ss'))*24 from dual
--患者基础数据
SELECT a.id apply_id,ar.id anar_id,nvl(reg.patient_name,a.patient_name) 姓名,ipi.ipi_registration_no 住院号,
ar.in_oproom_date 入室时间,a.scheduled_date 排程时间,
a.s_sssyzt_dm 手术状态码,a.is_reject 拒绝状态,
(case when nvl(reg.is_emergency,a.is_emergency)='1' then '急诊' when nvl(reg.is_emergency,a.is_emergency)='2' and nvl(reg.is_daytime,a.is_daytime) ='1' then '择期日间' when nvl(reg.is_emergency,a.is_emergency)='2' and nvl(reg.is_daytime,a.is_daytime) !='1' then '择期非日间' else null end) 手术类型  
FROM sam_apply a
left join sam_reg reg on reg.id=a.id
left join ipi_registration ipi on ipi.id=nvl(reg.ipi_registration_id,a.ipi_registration_id)
left join sam_anar ar on ar.sam_apply_id=a.id
WHERE 1=1
--and a.id=''
--and ar.id=''
--and ipi.ipi_registration_no=''
--and nvl(reg.patient_name,a.patient_name)=''

--文书
select r.sam_apply_id,n.*
       from sam_emr_rec r
       left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
       where r.rss_emr_type_id = ''
       --and r.rss_emr_ver_id = ''
       --and n.node_name = ''
       --and r.sam_apply_id=''
       --group by r.sam_apply_id
       
--事件
select sj.sam_apply_id,sj.event_text sj,sj.*
       from sam_anar_enent sj
       where sj.event_text like '%%'
       --and sj.s_mzsjlb_dm=''
       --and sj.sam_apply_id=''
       --group by sj.sam_apply_id

--护理事件字典
SELECT * FROM ons_time_nodes;

--工作人员职位类别字典
SELECT * FROM pub_gzlb;

--药品类别
select * from pub_ypjslb;

--麻醉方式
SELECT * FROM pub_mzfs
SELECT * FROM pub_mzfs2--带大类（麻醉方式代码有父类索引）

--ICD-9编码
SELECT aop.OPERATION_CODE,icd.* 
FROM icd_9_cm3 icd
inner join sam_apply_op aop on aop.OPERATION_CODE=icd.s_icd_9_cm3_dm
--inner join sam_reg_op rop on rop.OPERATION_CODE=icd.s_icd_9_cm3_dm

--体征字典
SELECT t.id 体征类型ID,t.curve_type 体征类型,t.vspd_name 类型名称,t.health_service_org_id 机构代码
from sam_anar_vspd t
left join sam_warning_config a on t.curve_type=a.quota;

--用药方式
SELECT * FROM sam_yytj_map;

--住院医嘱
SELECT * FROM IPD_DOCTOR_ORDERS;

--ca签名表
SELECT qm.sam_apply_id,qm.sign_time,qm.pic_base64
FROM sam_anar_steal_result qm 
WHERE qm.steal_type = 'mzjld' 
and qm.invalid = '0'
and qm.sign_phase = 'mzys'
and qm.sam_apply_id = '83ab40b05cc951fa0000'

--用药途径
SELECT pub.* FROM sam_mzsj_itpkg t
left join PUB_YYTJ pub on pub.s_yytj_dm = t.s_yytj_dm
SELECT * FROM PUB_YYTJ pub WHERE pub.s_yytj_dm = ''

--库存表
 SELECT * FROM  pms_batch_stock;

--用药单位
SELECT
pj1.s_jldw_cmc,--规格单位
pj2.s_jldw_cmc,--没有数据
pj3.s_jldw_cmc,--持续用药
pj4.s_jldw_cmc--瓶支
from sam_anar_enent t
left join drm_dictionary dd on dd.id = t.drug_id
left join drm_nuu_ds dnd on t.single_dose_unit = dnd.id
left join pub_jldw pj1 on pj1.s_jldw_dm = dd.single_dose_unit
left join pub_jldw pj2 on pj2.s_jldw_dm = t.single_dose_unit
left join pub_jldw pj3 on pj3.s_jldw_dm = dnd.udu
left join pub_jldw pj4 on pj4.s_jldw_dm = dd.ip_min_drug_unit
where t.event_text='注射用盐酸瑞芬太尼'

--手术状态
SELECT * FROM pub_sssyzt;

--访视字典
SELECT * FROM POIV_DICTIONARY jj where jj.word_label like '%%';

--麻醉事件其他属性
SELECT * FROM pub_mzsjqtsx--输液：晶体&胶体、呼吸：辅助呼吸&自主呼吸、插拔管：气管&喉罩

--手麻字典
select s_smzdlb_dm lbdm,
      s_smzd_dm dm,
      s_smzd_cmc cmc,
      s_pyjm pyjm,
      s_bz bz,
      s_syys syys,s_sfyx
    from pub_smzd
    where s_smzdlb_dm='3202'--静脉通道sam_anar_enent.iv_line
     -- and org_id=#{hospital}
    and s_sfyx='1'
    order by i_ywpx
```

###### 穿刺



```sql
LEFT JOIN (
  SELECT
    zz.sam_apply_id,
    '椎管内麻醉:' || zz.name1 || ',穿刺点:' || zz.name2 || ',超声引导：' || zz.name3 name
  FROM
    (
    SELECT
      c.sam_apply_id,
      MAX(DECODE(n.node_name, 'EVENT_TEXT', n.node_value)) AS name1,
      MAX(DECODE(n.node_name, 'INSERT_TUBE_ZGLCCD', n.node_value)) AS name2,
      MAX(DECODE(n.node_name, 'CSYD', n.node_value)) AS name3
    FROM
      sam_emr_rec c
    LEFT JOIN sam_emr_rec_nv n ON
      c.id = n.sam_emr_rec_id
    WHERE
      c.rss_emr_type_id = 'sam_zgnmz'
    GROUP BY
      c.sam_apply_id) zz) cc ON
  cc.sam_apply_id = p.id
```



###### 时长计算：年月日时

```sql
TRUNC(MONTHS_BETWEEN(a.scheduled_date,nvl(reg.birthday,a.birthday)) / 12)||'年'||
TRUNC(MOD(MONTHS_BETWEEN(a.scheduled_date,nvl(reg.birthday,a.birthday)), 12))||'月'||
TRUNC(a.scheduled_date - ADD_MONTHS(nvl(reg.birthday,a.birthday),TRUNC(MONTHS_BETWEEN(a.scheduled_date,nvl(reg.birthday,a.birthday)))))||'日'||
TRUNC((a.scheduled_date - ADD_MONTHS(nvl(reg.birthday,a.birthday),TRUNC(MONTHS_BETWEEN(nvl(reg.birthday,a.birthday),a.scheduled_date)))
       - TRUNC(a.scheduled_date - ADD_MONTHS(nvl(reg.birthday,a.birthday),TRUNC(MONTHS_BETWEEN(nvl(reg.birthday,a.birthday),a.scheduled_date))))
) * 24)||'时' 
```



###### 中国标准时间格式化

```sql
SELECT regexp_substr('Thu Jul 20 2023 18:55:00 GMT+0800 (中国标准时间)', '[^ ]+', 1, 4)||'-' || 
       decode(regexp_substr('Thu Jul 20 2023 18:55:00 GMT+0800 (中国标准时间)', '[^ ]+', 1, 2),
       'Jan','01','Feb','02','Mar','03','Apr','04','May','05','Jun','06','Jul','07','Aug','08','Sep','09','Oct','10','Nov','11','Dec','12',null)||'-'||
       regexp_substr('Thu Jul 20 2023 18:55:00 GMT+0800 (中国标准时间)', '[^ ]+', 1, 3)||' ' ||
       regexp_substr('Thu Jul 20 2023 18:55:00 GMT+0800 (中国标准时间)', '\d{2}[:]+\d{2}[:]+\d{2}')  
FROM dual
```

###### 体征

```sql
SELECT 
distinct
nvl(vspd.vspd_name,vspd.curve_type) 体征类型,vs.sam_anar_vspd_id
--,vs.vspd_value
FROM sam_anar_vs vs
left join sam_anar_vspd vspd on vs.sam_anar_vspd_id = vspd.id
WHERE vs.is_rec_event = 
--'1'
'2'
and nvl(vspd.vspd_name,vspd.curve_type) = '';
```

###### 接台数据

```sql
--接台获取思路：拿到所有数据进行排序并获得序号,再拿到每台手术的台次,然后通过台次不为1,并结合函数来给每台手术添加该条1与上台或下台手术之间的数据
select info1.*,(case when info1.op_time>1 then (info1.in_oproom_date - lag(info1.out_oproom_date, 1, info1.in_oproom_date) over(order by xuhao)) else 0 end) jtsc
from(select rownum xuhao,info.*        
    from (select to_char(ar.IN_OPROOM_DATE, 'yyyy-mm-dd') schedate,
    ar.in_oproom_date in_oproom_date,
    ar.out_oproom_date out_oproom_date,
    rank() over(partition by reg.sam_room_id, to_char(a.scheduled_date, 'yyyy-mm-dd') order by ar.in_oproom_date, ar.oper_beging_date) op_time
    from sam_apply a
    left join sam_reg reg on reg.id = a.id
    left join sam_anar ar on a.id = ar.sam_apply_id
    left join hra00_department de on de.id = reg.patient_dept_id
    left join sam_room room on room.id = reg.sam_room_id
    where ar.IN_OPROOM_DATE between TO_DATE('2023-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('2023-01-31',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss') 
    order by room.id,op_time,ar.IN_OPROOM_DATE
    ) info) info1
```

###### 椎管内麻醉

```sql
--麻醉记录单右侧椎管内麻醉
select rec.sam_apply_id,
               '椎管内麻醉' s_f_mzfs_cmc,
               listagg(nv.node_value, ',') within group(order by rec.sam_apply_id) ymzfs
          from sam_emr_rec rec
          left join sam_emr_rec_nv nv
            on nv.sam_emr_rec_id = rec.id
         where rec.rss_emr_type_id = 'sam_zgnmz'
         and rec.rss_emr_ver_id = '1'
         and nv.node_name = 'EVENT_TEXT'
         group by rec.sam_apply_id

--麻醉记录单右侧椎管内麻醉列表
SELECT * 
FROM pub_mzsj t 
WHERE t.s_mzsjlb_dm='60' 
and t.s_sfyx='1' 
and t.health_service_org_id='RSS20171211000000001';
```

###### 恢复室

```sql
SELECT
--PACU基础表 
ipi.ipi_registration_no 登记号,
reg.patient_name 姓名,
xb.s_xb_cmc 性别,
f_j_getage(ar.oper_end_date,nvl(reg.birthday,a.birthday)) 年龄,
ar.weight 体重,
pasa.s_asamzfj_cmc ASA分级,
de.department_chinese_name 科室,
nvl(reg.main_diag ,a.main_diag) 诊断名称,
ws.随身管道,--这里数量、引流性状、未倾倒ml未展示
jkzt.使用止吐药,
jkzt.使用拮抗药,
ws.合并症,
gms.药过敏史,
nvl(mzfs.mzfsCmc,mzfs2.s_mzfs_cmc) 麻醉方式,
to_char(ar.rec_in_date,'yyyy-mm-dd') 入PACU日期,
rm.building||'-'||rm.floor||' '||rm.oper_room PACU床位,
to_char(ar.rec_in_date,'hh24:mi') "入PACU时间/入麻醉苏醒室",
to_char(ar.rec_out_date,'hh24:mi') "出PACU时间/出麻醉苏醒室",
round((ar.oper_end_date-ar.oper_beging_date)*24,1) 手术总时间,
round((ar.rec_out_date-ar.rec_in_date)*24,1) 麻醉苏醒室总时间,
--PACU用药表
yy.用药,
sy.输液,
sx.输血,
cl.出量,
--PACU事件表
ald.*,
--PACU生命体征表
tzsj.收缩压,
tzsj.舒张压,
tzsj.SPO2,
tzsj.脉搏,
tzsj.呼吸频率,
tzsj.有创收缩压,
tzsj.有创舒张压,
--PACU备注表)
bz.备注事件
from (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('&开始时间', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('&结束时间',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss') --and ar.out_oproom_date is not null
)ar
inner join sam_apply a on a.id = ar.sam_apply_id
left join sam_reg reg on reg.id = a.id
left join hra00_department de on de.id = nvl(reg.patient_dept_id,a.patient_dept_id)--患者科室
left join ipi_registration ipi on ipi.id = nvl(reg.ipi_registration_id,a.ipi_registration_id)--住院号
left join GB_T_2261_1_2003 xb on xb.s_xb_dm = nvl(reg.s_xb_dm,a.s_xb_dm)--性别
left join (select sam_apply_id,max(s_asamzfj_dm)s_asamzfj_dm
             from sam_apply_op group by sam_apply_id) aop on a.id = aop.sam_apply_id              
left join (select sam_reg_id,max(s_asamzfj_dm)s_asamzfj_dm
                 from sam_reg_op group by sam_reg_id) rop on a.id = rop.sam_reg_id
left join pub_asamzfj pasa on nvl(rop.s_asamzfj_dm,aop.s_asamzfj_dm) = pasa.s_asamzfj_dm--asa分级
/*left join (SELECT r.sam_apply_id,listagg(x.管道名, ';') within group(order by rowid) 随身管道
           FROM (SELECT r.sam_apply_id,r.cl_bc_xml FROM sam_emr_rec r where r.rss_emr_type_id = 'pacu_ssgd' and r.rss_emr_ver_id = '1')r,
           xmltable('/request/objectList/SAMANARENENT/S_SSGD_DMS/S_SSGD' passing
           xmltype(r.cl_bc_xml) 　　　　
           columns
           管道名 varchar2(30) path 'text()'
           --,管道代码 varchar2(30) path '@v'
           )x
           group by r.sam_apply_id)ssgd on ssgd.sam_apply_id=a.id--随身管道*/
inner join (select r.sam_apply_id,
                  listagg(case when n.node_name='S_SSGD' then n.node_value else null end,';') within group(order by n.node_value) 随身管道,
                  max(case when n.node_name='HBZ' then n.node_value else null end) 合并症
           from sam_emr_rec r
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'pacu_ssgd'
           and r.rss_emr_ver_id = '1'
           group by r.sam_apply_id)ws on ws.sam_apply_id = a.id--随身管道&合并症
left join (SELECT en.sam_apply_id,
                  nvl(listagg(case when en.other_attr='1' then en.event_text||'：'||en.single_dose||j.s_jldw_cmc else null end,';') within group(order by en.ordered_date),'否') 使用止吐药,
                  nvl(listagg(case when en.other_attr='2' then en.event_text||'：'||en.single_dose||j.s_jldw_cmc else null end,';') within group(order by en.ordered_date),'否') 使用拮抗药
           FROM sam_anar_enent en 
           left join drm_dictionary drm on drm.id = en.drug_id
           left join drm_nuu_ds n on en.single_dose_unit = n.id
           left join pub_jldw j on n.udu = j.s_jldw_dm
           where en.s_mzsjlb_dm='22'
           and en.is_rec_enent='1'
           group by en.sam_apply_id)jkzt on jkzt.sam_apply_id=a.id--止吐&拮抗
left join (select r.sam_apply_id,
                  listagg(n.node_value, ',') within group(order by n.node_value) 药过敏史
           from sam_emr_rec_nv n
           left join sam_emr_rec r on n.sam_emr_rec_id = r.id
           left join sam_anar a on a.sam_apply_id = r.sam_apply_id
           where (n.node_name = 'S_GM' or n.node_name = 'GMS_NAME')
           group by r.sam_apply_id)gms on gms.sam_apply_id=a.id--过敏
left join (select r.sam_apply_id,listagg(n.node_value,'+') within group(order by n.id) mzfsCmc
           from sam_emr_rec r
           left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
           where r.rss_emr_type_id = 'sam_mzfs'
           and n.node_name = 'S_MZFS_DM'
           group by r.sam_apply_id) mzfs on mzfs.sam_apply_id = a.id--麻醉方式 
left join pub_mzfs mzfs2 on mzfs2.s_mzfs_dm = a.s_mzfs_dm--申请时记录的麻醉方式
left join (select t.sam_apply_id,
                  listagg(x.mzfscmc, '+') within group(order by t.sam_apply_id) mzfscmc,
                  max(case when x.mzfsdm in ('03','0201') then 1 else 0 end) jm,
                  max(case when x.mzfsdm = '05' then 1 else 0 end) fh,
           from (SELECT t.sam_apply_id,t.cl_bc_xml
                 FROM sam_emr_rec t
                 inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on t.sam_apply_id = ar.sam_apply_id
                 where t.rss_emr_type_id='sam_mzfs'
                 )t,
           xmltable('/request/objectList/SAMANARENENT/S_MZFS_DMDS/S_MZFS_DM' passing
                    xmltype(t.cl_bc_xml) columns 
                    mzfscmc varchar2(30) path 'text()',　　　　 
                    mzfsdm varchar2(30) path '@v'
                   )x
           group by t.sam_apply_id) mzfs on mzfs.sam_apply_id = a.id--麻醉方式 
left join sam_room rm on rm.id=nvl(reg.sam_room_id,a.sam_room_id)--手术间
left join (SELECT yy.sam_apply_id,listagg(yy.用药,';'||chr(10)) within group(order by yy.sam_apply_id) 用药
                  FROM (SELECT en.sam_apply_id,
                  --格式：该种药的名称：用量/处方剂量 单位
                  en.event_text
                  ||'：'||
                  to_char(sum(en.single_dose * 
                  (case when instr(j.s_jldw_cmc, '/h') > 0 then (case when en.duration is null then 1 else round((en.end_date - en.ordered_date) * 24, 2) end)
                        when instr(j.s_jldw_cmc, '/min') > 0 then (case when en.duration is null then 1 else round((en.end_date - en.ordered_date) * 24 * 60, 1) end)
                  else 1 end) * 
                  (case when instr(j.s_jldw_cmc, '/kg') > 0 then ar.weight else 1 end) * 
                  (case when en.density is not null then (to_number(en.density) * 10) else 1 end) * 
                  n.udu_du_scale),'fm9999999999999990.00')
                  ||'/'||
                  to_char(ceil(sum(en.single_dose * 
                  (case when instr(j.s_jldw_cmc, '/h') > 0 then (case when en.duration is null then 1 else round((en.end_date - en.ordered_date) * 24, 2) end)
                  when instr(j.s_jldw_cmc, '/min') > 0 then (case when en.duration is null then 1 else round((en.end_date - en.ordered_date) * 24 * 60, 1) end)
                  else 1 end) * 
                  (case when instr(j.s_jldw_cmc, '/kg') > 0 then ar.weight else 1 end) * 
                  (case when en.density is not null then (to_number(en.density) * 10) else 1 end) * 
                  n.udu_du_scale)/max(drm.single_dose_specification)) * max(drm.single_dose_specification),'fm9999999999999990.00')
                  ||max(j.s_jldw_cmc) 用药
                  FROM (SELECT * FROM sam_anar_enent en WHERE en.s_mzsjlb_dm='22' and en.is_rec_enent='1')en
                  inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('&开始时间', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('&结束时间',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss') --and ar.out_oproom_date is not null
                              )ar on ar.id=en.sam_anar_id
                  left join drm_dictionary drm on drm.id = en.drug_id
                  left join drm_nuu_ds n on en.single_dose_unit = n.id
                  left join pub_jldw j on n.udu = j.s_jldw_dm
                  group by en.sam_apply_id,en.event_text,en.batch_no,en.specification)yy group by yy.sam_apply_id)yy on yy.sam_apply_id=a.id--用药
left join (SELECT sy.sam_apply_id,listagg(sy.输液,';'||chr(10)) within group(order by sy.sam_apply_id) 输液
                  FROM (SELECT en.sam_apply_id,
                  --格式：该种药的名称：用量/处方剂量 单位
                  en.event_text
                  ||'：'||
                  sum(case when j.s_jldw_cmc='L' then en.single_dose*1000 else en.single_dose end)
                  ||'/'||
                  ceil(sum(case when j.s_jldw_cmc='L' then en.single_dose*1000 else en.single_dose end)/max(drm.single_dose_specification))*max(drm.single_dose_specification)
                  ||max(j.s_jldw_cmc) 输液
                  FROM (SELECT * FROM sam_anar_enent en WHERE en.s_mzsjlb_dm='32' and en.is_rec_enent='1')en
                  inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('&开始时间', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('&结束时间',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss') --and ar.out_oproom_date is not null
                              )ar on ar.id=en.sam_anar_id
                  left join drm_dictionary drm on drm.id = en.drug_id
                  left join drm_nuu_ds n on en.single_dose_unit = n.id
                  left join pub_jldw j on n.udu = j.s_jldw_dm
                  group by en.sam_apply_id,en.event_text,en.batch_no,en.specification)sy group by sy.sam_apply_id)sy on sy.sam_apply_id=a.id--输液
left join (SELECT sx.sam_apply_id,listagg(sx.输血,';'||chr(10)) within group(order by sx.sam_apply_id) 输血
                  FROM (SELECT en.sam_apply_id,
                               en.event_text
                               ||'：'||
                               sum(case when pj.s_jldw_cmc = 'u' then en.single_dose * 200 when pj.s_jldw_cmc = 'U' then en.single_dose * 200 when pj.s_jldw_cmc = '治疗量' then en.single_dose * 200  else en.single_dose end)
                               ||max(pj.s_jldw_cmc) 输血
                         FROM (SELECT * FROM sam_anar_enent en WHERE en.s_mzsjlb_dm='31' and en.is_rec_enent='1')en
                         inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('&开始时间', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('&结束时间',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss') --and ar.out_oproom_date is not null
                                     )ar on ar.id=en.sam_anar_id
                         left join pub_jldw pj on pj.s_jldw_dm = en.single_dose_unit
                         group by en.sam_apply_id,en.event_text)sx group by sx.sam_apply_id)sx on sx.sam_apply_id=a.id--输血
left join (SELECT cl.sam_apply_id,listagg(cl.出量,';'||chr(10)) within group(order by cl.sam_apply_id) 出量
                  FROM (SELECT en.sam_apply_id,
                               en.event_text
                               ||'：'||
                               sum(en.single_dose)
                               ||max(pj.s_jldw_cmc) 出量
                         FROM (SELECT * FROM sam_anar_enent en WHERE en.s_mzsjlb_dm='40' and en.is_rec_enent='1')en
                         inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('&开始时间', 'yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('&结束时间',' 23:59:59'), 'yyyy-mm-dd hh24:mi:ss') --and ar.out_oproom_date is not null
                                     )ar on ar.id=en.sam_anar_id
                         left join pub_jldw pj on pj.s_jldw_dm = en.single_dose_unit
                         group by en.sam_apply_id,en.event_text)cl group by cl.sam_apply_id)cl on cl.sam_apply_id=a.id--出量
left join (SELECT ald.sam_anar_id,ald.YSPF 意识评分,ald.HXPF 呼吸评分,ald.XHPF 循环评分,ald.YHPF 氧和评分,ald.HDL 活动力,ald.KCYS 口唇颜色,ald.zf 总分,
                  (case when ald.EXOT='0' then '无' when ald.EXOT='1' then '有' else null end) "恶心/呕吐",
                  (case when ald.HZ='0' then '无' when ald.HZ='1' then '有' else null end) 寒颤,ald.TTPF 疼痛评分,
                  --(case when ald.XBXZ='a' then '清亮' when ald.XBXZ='b' then '浑浊' when ald.XBXZ='c' then '淡血性' when ald.XBXZ='d' then '茶色' when ald.XBXZ='e' then '血性' else null end) 小便性状,
                  --(case when ald.KNCD='0' then '无哭闹' when ald.KNCD='1' then '轻度哭闹' when ald.KNCD='2' then '中度哭闹' when ald.KNCD='3' then '重度哭闹' else null end) 哭闹程度,
                  --(case when ald.JKZD='0' then '无' when ald.JKZD='1' then '有' else null end) 健康指导,
                  (case when ald.SKQK='0' then '无敷料' when ald.SKQK='1' then '有渗液' when ald.SKQK='2' then '无渗液' else null end) 伤口情况
           FROM (SELECT ald.sam_anar_id,ald.YSPF,ald.HXPF,ald.XHPF,ald.YHPF,ald.HDL,ald.KCYS,ald.zf,ald.EXOT,ald.HZ,ald.TTPF,ald.SKQK,
                        ald.XBXZ,ald.KNCD,ald.JKZD,
                        (ROW_NUMBER() OVER(PARTITION BY ald.sam_anar_id  ORDER BY ald.input_date desc)) rn
                 FROM sam_fss_ald ald)ald WHERE ald.rn=1)ald on ald.sam_anar_id=ar.id--Aldrete评分
left join (SELECT ald.sam_anar_id,
                  max(case when ald.EXOT='1' then 1 end) "恶心/呕吐",
                  max(case when ald.HZ='1' then 1 end) 寒颤,
                  max(case when to_number(ald.TTPF) >= 4 then 1 end) 疼痛评分,
                  COUNT(*) "入PACU超2小时"
           FROM (SELECT ald.sam_anar_id,ald.EXOT,ald.HZ,ald.TTPF,
                        (ROW_NUMBER() OVER(PARTITION BY ald.sam_anar_id  ORDER BY ald.input_date desc)) rn
                 FROM sam_fss_ald ald)ald 
           group by ald.sam_anar_id)ald on ald.sam_anar_id=ar.id--Aldrete评分2
left join (SELECT vs.sam_anar_id,
                  listagg((case when vspd.vspd_name='收缩压' then vs.vspd_value else null end),';') within group(order by vs.input_date) 收缩压,
                  listagg((case when vspd.vspd_name='舒张压' then vs.vspd_value else null end),';') within group(order by vs.input_date) 舒张压,
                  listagg((case when vspd.curve_type='SPO2' then vs.vspd_value else null end),';') within group(order by vs.input_date) SPO2,
                  listagg((case when vspd.vspd_name='脉搏' then vs.vspd_value else null end),';') within group(order by vs.input_date) 脉搏,
                  listagg((case when vspd.vspd_name='呼吸频率' then vs.vspd_value else null end),';') within group(order by vs.input_date) 呼吸频率,
                  listagg((case when vspd.vspd_name='有创收缩压' then vs.vspd_value else null end),';') within group(order by vs.input_date) 有创收缩压,
                  listagg((case when vspd.vspd_name='有创舒张压' then vs.vspd_value else null end),';') within group(order by vs.input_date) 有创舒张压
                  FROM (SELECT * FROM sam_anar_vs vs WHERE vs.is_rec_event='1') vs
                  left join sam_anar_vspd vspd on vs.sam_anar_vspd_id=vspd.id
                  group by vs.sam_anar_id)tzsj on tzsj.sam_anar_id=ar.id--体征数据
left join (SELECT sam_apply_id,listagg(节点,';'||chr(10)) within group(order by 时间) 备注事件
            FROM (SELECT * FROM (select r.sam_apply_id,
                         max(decode(n.node_name,'S_MZSJLB_CMC',n.node_value,null))||'：'||substr(max(decode(n.node_name,'ORDERED_DATE',n.node_value,null)),12,5) 节点,
                         to_date(max(decode(n.node_name,'ORDERED_DATE',n.node_value,null)),'yyyy-mm-dd hh24:mi:ss') 时间
                  from sam_emr_rec r
                  left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
                  where r.rss_emr_type_id like '%pacu%'
                  group by r.sam_apply_id,r.id,r.rss_emr_type_id,r.rss_emr_ver_id)
                  union all
                  (select sj.sam_apply_id,sj.event_text||'：'||to_char(sj.ordered_date,'hh24:mi') 节点,sj.ordered_date 时间
                  from sam_anar_enent sj
                  WHERE sj.is_rec_enent='1' and sj.s_mzsjlb_dm not in ('22','31','32','33','40')))
            WHERE 节点 !='：'
            group by sam_apply_id)bz on bz.sam_apply_id=a.id--备注
```

##### 参考块

##### 麻醉医生工作量王牌

```sql
left join (
--交接班：麻醉助手中间交接和最后接班
SELECT jb.sam_apply_id,jb.jiebanuser,jb.jiebanusername,to_date(jb.jiaobantime,'yyyy-mm-dd hh24:mi:ss') sbtime,
       (case when jb1.jiebanuser is not null then to_date(jb1.jiaobantime,'yyyy-mm-dd hh24:mi:ss') else jb.ana_end_date end) xbtime,2 gzlb--工作类别：1主2助手
FROM (
SELECT t.sam_apply_id,
       max(decode(n1.node_name,'jiaobanuser',n1.node_value,null)) jiaobanuser,
       max(decode(n1.node_name,'jiaobanusername',n1.node_value,null)) jiaobanusername,
       max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) jiebanuser,
       max(decode(n1.node_name,'jiebanusername',n1.node_value,null)) jiebanusername,
       max(decode(n1.node_name,'jiaobantime',n1.node_value,null)) jiaobantime,
       max(r.ana_end_date) ana_end_date,
       row_number() over(partition by t.sam_apply_id,max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn,
       row_number() over(partition by t.sam_apply_id order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn1                               
from sam_emr_rec t
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))r on t.sam_apply_id = r.sam_apply_id
left join sam_emr_rec_nv n1 on t.id = n1.sam_emr_rec_id
where t.rss_emr_type_id = 'huaxi_sam_stu_jbjl'
and r.ana_end_date is not null
group by t.sam_apply_id,t.id)jb
left join (
SELECT t.sam_apply_id,
       max(decode(n1.node_name,'jiaobanuser',n1.node_value,null)) jiaobanuser,
       max(decode(n1.node_name,'jiaobanusername',n1.node_value,null)) jiaobanusername,
       max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) jiebanuser,
       max(decode(n1.node_name,'jiebanusername',n1.node_value,null)) jiebanusername,
       max(decode(n1.node_name,'jiaobantime',n1.node_value,null)) jiaobantime,
       max(r.ana_end_date) ana_end_date,
       row_number() over(partition by t.sam_apply_id,max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn,
       row_number() over(partition by t.sam_apply_id order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn1 from sam_emr_rec t
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))r on t.sam_apply_id = r.sam_apply_id
left join sam_emr_rec_nv n1 on t.id = n1.sam_emr_rec_id
where t.rss_emr_type_id = 'huaxi_sam_stu_jbjl'
and r.ana_end_date is not null
group by t.sam_apply_id,t.id
)jb1 on jb1.sam_apply_id = jb.sam_apply_id and jb.jiebanuser = jb1.jiaobanuser and jb1.rn1 > jb.rn1
WHERE jb.jiebanusername is not null

union

--麻醉助手排班交班
SELECT reg.id,mz.id,mz.employee_name,ar.ana_beging_date sbtime,to_date(jb1.jiaobantime,'yyyy-mm-dd hh24:mi:ss') xbtime,2 gzlb
from sam_reg reg
left join (SELECT sam_reg_id,姓名ID,职位
           FROM (select sam_reg_id,narcotic_assistant_1,narcotic_assistant_2,narcotic_assistant_3
                 from sam_reg_op
                 WHERE is_main_operation='1'
                 ) rop
           unpivot (姓名ID for 职位 in (narcotic_assistant_1 as '一助',narcotic_assistant_2 as '二助',narcotic_assistant_3 as '三助'))
           )rop on reg.id = rop.sam_reg_id--麻醉医生工作量使用
left join hrm_employee mz on mz.id=rop.姓名ID--麻醉医生姓名：麻醉医生工作量使用
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on reg.id = ar.sam_apply_id            
inner join (
SELECT t.sam_apply_id,
       max(decode(n1.node_name,'jiaobanuser',n1.node_value,null)) jiaobanuser,
       max(decode(n1.node_name,'jiaobanusername',n1.node_value,null)) jiaobanusername,
       max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) jiebanuser,
       max(decode(n1.node_name,'jiebanusername',n1.node_value,null)) jiebanusername,
       max(decode(n1.node_name,'jiaobantime',n1.node_value,null)) jiaobantime,
       max(r.ana_end_date) ana_end_date,
       row_number() over(partition by t.sam_apply_id,max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn,
       row_number() over(partition by t.sam_apply_id order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn1 
       from sam_emr_rec t
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))r on t.sam_apply_id = r.sam_apply_id
left join sam_emr_rec_nv n1 on t.id = n1.sam_emr_rec_id
where t.rss_emr_type_id = 'huaxi_sam_stu_jbjl'
and r.ana_end_date is not null
group by t.sam_apply_id,t.id
)jb1 on jb1.sam_apply_id = reg.id and mz.employee_name = jb1.jiaobanusername

union 

--麻醉助手排班未进行交接
SELECT reg.id,mz.id,mz.employee_name,ar.ana_beging_date sbtime,ar.ana_end_date xbtime,2 gzlb
from sam_reg reg
inner join (SELECT sam_reg_id,姓名ID,职位
           FROM (select sam_reg_id,narcotic_assistant_1,narcotic_assistant_2,narcotic_assistant_3
                 from sam_reg_op
                 WHERE is_main_operation='1'
                 ) rop
           unpivot (姓名ID for 职位 in (narcotic_assistant_1 as '一助',narcotic_assistant_2 as '二助',narcotic_assistant_3 as '三助'))
           )rop on reg.id = rop.sam_reg_id--麻醉医生工作量使用
left join hrm_employee mz on mz.id=rop.姓名ID--麻醉医生姓名：麻醉医生工作量使用
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on reg.id = ar.sam_apply_id            
left join (
SELECT t.sam_apply_id,
       max(decode(n1.node_name,'jiaobanusername',n1.node_value,null)) jiaobanusername
from sam_emr_rec t   
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))r on t.sam_apply_id = r.sam_apply_id
left join sam_emr_rec_nv n1 on t.id = n1.sam_emr_rec_id
where t.rss_emr_type_id = 'huaxi_sam_stu_jbjl'
group by t.sam_apply_id,t.id
)jb1 on jb1.sam_apply_id = reg.id and mz.employee_name = jb1.jiaobanusername
where jb1.sam_apply_id is null
and ar.ana_end_date is not null

union

--主麻排班未进行交接
SELECT reg.id,mz.id,mz.employee_name,ar.ana_beging_date sbtime,ar.ana_end_date xbtime,1 gzlb
from sam_reg reg
inner join (SELECT sam_reg_id,姓名ID,职位
           FROM (select sam_reg_id,narcotic_doctor_id
                 from sam_reg_op
                 WHERE is_main_operation='1'
                 ) rop
           unpivot (姓名ID for 职位 in (narcotic_doctor_id as '主麻'))
           )rop on reg.id = rop.sam_reg_id--麻醉医生工作量使用
left join hrm_employee mz on mz.id=rop.姓名ID--麻醉医生姓名：麻醉医生工作量使用
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on reg.id = ar.sam_apply_id            
left join (
SELECT t.sam_apply_id,
       max(decode(n1.node_name,'jiaobanusername',n1.node_value,null)) jiaobanusername
from sam_emr_rec t   
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))r on t.sam_apply_id = r.sam_apply_id
left join sam_emr_rec_nv n1 on t.id = n1.sam_emr_rec_id
where t.rss_emr_type_id = 'huaxi_sam_jbjl'
group by t.sam_apply_id,t.id
)jb1 on jb1.sam_apply_id = reg.id and mz.employee_name = jb1.jiaobanusername
where jb1.sam_apply_id is null
and ar.ana_end_date is not null

union 

--交接班：主麻中间交接和最后接班
SELECT jb.sam_apply_id,jb.jiebanuser,jb.jiebanusername,to_date(jb.jiaobantime,'yyyy-mm-dd hh24:mi:ss') sbtime,
       (case when jb1.jiebanuser is not null then to_date(jb1.jiaobantime,'yyyy-mm-dd hh24:mi:ss') else jb.ana_end_date end) xbtime,1 gzlb 
FROM (
SELECT t.sam_apply_id,
       max(decode(n1.node_name,'jiaobanuser',n1.node_value,null)) jiaobanuser,
       max(decode(n1.node_name,'jiaobanusername',n1.node_value,null)) jiaobanusername,
       max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) jiebanuser,
       max(decode(n1.node_name,'jiebanusername',n1.node_value,null)) jiebanusername,
       max(decode(n1.node_name,'jiaobantime',n1.node_value,null)) jiaobantime,
       max(r.ana_end_date) ana_end_date,
       row_number() over(partition by t.sam_apply_id,max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn,
       row_number() over(partition by t.sam_apply_id order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn1                               
from sam_emr_rec t
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))r on t.sam_apply_id = r.sam_apply_id
left join sam_emr_rec_nv n1 on t.id = n1.sam_emr_rec_id
where t.rss_emr_type_id = 'huaxi_sam_jbjl'
and r.ana_end_date is not null
group by t.sam_apply_id,t.id)jb
left join (
SELECT t.sam_apply_id,
       max(decode(n1.node_name,'jiaobanuser',n1.node_value,null)) jiaobanuser,
       max(decode(n1.node_name,'jiaobanusername',n1.node_value,null)) jiaobanusername,
       max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) jiebanuser,
       max(decode(n1.node_name,'jiebanusername',n1.node_value,null)) jiebanusername,
       max(decode(n1.node_name,'jiaobantime',n1.node_value,null)) jiaobantime,
       max(r.ana_end_date) ana_end_date,
       row_number() over(partition by t.sam_apply_id,max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn,
       row_number() over(partition by t.sam_apply_id order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn1 from sam_emr_rec t
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))r on t.sam_apply_id = r.sam_apply_id
left join sam_emr_rec_nv n1 on t.id = n1.sam_emr_rec_id
where t.rss_emr_type_id = 'huaxi_sam_jbjl'
and r.ana_end_date is not null
group by t.sam_apply_id,t.id
)jb1 on jb1.sam_apply_id = jb.sam_apply_id and jb.jiebanuser = jb1.jiaobanuser and jb1.rn1 > jb.rn1
WHERE jb.jiebanusername is not null

union

--主麻排班交班
SELECT reg.id,mz.id,mz.employee_name,ar.ana_beging_date sbtime,to_date(jb1.jiaobantime,'yyyy-mm-dd hh24:mi:ss') xbtime,1 gzlb
from sam_reg reg
inner join (SELECT sam_reg_id,姓名ID,职位
           FROM (select sam_reg_id,narcotic_doctor_id
                 from sam_reg_op
                 WHERE is_main_operation='1'
                 ) rop
           unpivot (姓名ID for 职位 in (narcotic_doctor_id as '主麻'))
           )rop on reg.id = rop.sam_reg_id--麻醉医生工作量使用
left join hrm_employee mz on mz.id=rop.姓名ID--麻醉医生姓名：麻醉医生工作量使用
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on reg.id = ar.sam_apply_id            
inner join (
SELECT t.sam_apply_id,
       max(decode(n1.node_name,'jiaobanuser',n1.node_value,null)) jiaobanuser,
       max(decode(n1.node_name,'jiaobanusername',n1.node_value,null)) jiaobanusername,
       max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) jiebanuser,
       max(decode(n1.node_name,'jiebanusername',n1.node_value,null)) jiebanusername,
       max(decode(n1.node_name,'jiaobantime',n1.node_value,null)) jiaobantime,
       max(r.ana_end_date) ana_end_date,
       row_number() over(partition by t.sam_apply_id,max(decode(n1.node_name,'jiebanuser',n1.node_value,null)) order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn,
       row_number() over(partition by t.sam_apply_id order by to_date(max(decode(n1.node_name,'jiaobantime',n1.node_value,null)),'yyyy-mm-dd hh24:mi:ss') nulls last) rn1 
       from sam_emr_rec t
inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))r on t.sam_apply_id = r.sam_apply_id
left join sam_emr_rec_nv n1 on t.id = n1.sam_emr_rec_id
where t.rss_emr_type_id = 'huaxi_sam_jbjl'
and r.ana_end_date is not null
group by t.sam_apply_id,t.id
)jb1 on jb1.sam_apply_id = reg.id and mz.employee_name = jb1.jiaobanusername
)jjb on jjb.sam_apply_id = a.id
```



获取上行数据完美函数

```sql
lag(ar.ana_end_date,1) over(PARTITION BY nvl(reg.sam_room_id,a.sam_room_id),to_char(ar.in_oproom_date,'yyyy-mm-dd') order by nvl(reg.sam_room_id,a.sam_room_id),ar.in_oproom_date) rn
```



###### 麻醉方式

```sql
--单个麻醉方式的医院：
left join (SELECT mc.sam_apply_id,max(mc.mc) mc,max(n1.dm) dm
           FROM (select r.id,max(r.sam_apply_id)sam_apply_id,listagg(n.node_value, ';') within group(order by n.id) mc
                 from sam_emr_rec r
                 inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on a.id = ar.sam_apply_id
                 left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
                 where r.rss_emr_type_id = 'sam_mzfs'
                 and n.node_name = 'S_MZFS_DM'
                 group by r.id)mc
           left join (select n1.sam_emr_rec_id,n1.node_value dm from sam_emr_rec_nv n1 WHERE n1.node_name='DM') n1 on n1.sam_emr_rec_id = mc.id
           group by mc.sam_apply_id) mzfs on mzfs.sam_apply_id = info.apply_id

--多个麻醉方式的医院：截取：
left join (SELECT mc.sam_apply_id,max(mc.mc) mc,
                   --总计
                   COUNT(*) 总计,
                   --椎管内麻醉例数 02
                   sum(case when n1.dm = '02' then 1 else 0 end) 椎管内,
                   --插管全麻例数 01
                   sum(case when n1.dm = '01' then 1 else 0 end) 插管全,
                   --非插管全麻例数 06
                   sum(case when n1.dm = '06' then 1 else 0 end) 非插管全,
                   --复合麻醉例数 05
                   sum(case when n1.dm = '05' then 1 else 0 end) 复合麻,
                   --其他麻醉方式例数07,99
                   sum(case when n1.dm in ('07','99') then 1 else 0 end) 其他麻,
                   --局麻 03,04
                   sum(case when n1.dm in ('03','04') then 1 else 0 end) 局麻
            FROM (select r.id,max(r.sam_apply_id)sam_apply_id,listagg(n.node_value, ';') within group(order by n.id) mc
                         from sam_emr_rec r
                  inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on a.id = ar.sam_apply_id
                         left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
                         where r.rss_emr_type_id = 'sam_mzfs'
                         and n.node_name = 'S_MZFS_DM'
                         group by r.id)mc
            left join (select n1.sam_emr_rec_id,substr(n1.node_value,0,2) dm from sam_emr_rec_nv n1 WHERE n1.node_name='DM') n1 on n1.sam_emr_rec_id = mc.id
            WHERE n1.dm is not null
            group by mc.sam_apply_id) mzfs on mzfs.sam_apply_id = a.id
            
--麻醉方式王牌
SELECT mc.sam_apply_id,max(mc.mc) mc
FROM (select r.id,r.sam_apply_id,listagg(n.node_value, ';') within group(order by n.id) mc
      from sam_emr_rec r
      inner join (SELECT ar.* FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on a.id = ar.sam_apply_id
      left join sam_emr_rec_nv n on n.sam_emr_rec_id = r.id
      where r.rss_emr_type_id = 'sam_mzfs'
      and n.node_name = 'S_MZFS_DM'
      and r.sam_apply_id = 'daad44e4f539c3220000'
      group by r.id,r.sam_apply_id)mc
      inner join (select n1.sam_emr_rec_id,n1.node_value dm from sam_emr_rec_nv n1 WHERE n1.node_name='DM' and n1.node_value in ('020205')) n1 on n1.sam_emr_rec_id = mc.id--进行大类筛选：包含020205麻醉方式的患者就划入
      group by mc.sam_apply_id
```

###### 30分钟持续低体温

```sql
--获取当前时间点30分钟数据：查询所有,左连接,保留左侧排序号,关联条件30分钟内(主含体温：tw),再按anar_id&排序（或直接anar_id&时间点）分组获取
SELECT info.sam_apply_id,min(info.sflx) sflx FROM(
select v.sam_anar_id,v.time_point,count(*) cec,sum(case when info.tw<36 then 1 else 0 end) dwc,min(case when info.tw>36 then '否' else '是' end) sflx
from sam_anar_vs v
--该测温点往后30分钟：测温次、低温次、是否连续
left join (SELECT v.sam_anar_id,v.vspd_value tw,v.time_point
          from sam_anar_vs v where v.vspd_name='体温' and v.sam_anar_vspd_id in ('54','55','56')
          ) info on info.time_point between v.time_point and v.time_point+30/(24*60) and info.sam_anar_id=v.sam_anar_id
where v.vspd_name='体温'
and v.sam_anar_vspd_id in ('54','55','56')
group by v.sam_anar_id,v.time_point
) info
group by info.sam_apply_id

left join (SELECT info.sam_anar_id,min(info.sflx) sflx 
           FROM(select v.sam_anar_id,min(case when info.tw>36 then '否' else '是' end) sflx--,v.time_point,count(*) cec,sum(case when info.tw<36 then 1 else 0 end) dwc
                from sam_anar_vs v
                --该测温点往后30分钟：测温次、低温次、是否连续
                left join (SELECT v.sam_anar_id,v.vspd_value tw,v.time_point
                           from sam_anar_vs v 
                           where v.vspd_name='体温' 
                           and v.sam_anar_vspd_id in ('54','55','56')
                           and v.vspd_value > 30--排除掉设备未接入时的问题数据
                           and v.is_rec_event = '2'
                           ) info on info.time_point between v.time_point and v.time_point+30/(24*60) and info.sam_anar_id=v.sam_anar_id
                where v.vspd_name='体温'
                and v.sam_anar_vspd_id in ('54','55','56')
                and v.is_rec_event = '2'
                group by v.sam_anar_id,v.time_point) info--体温监测
```

术中保温

###### 生命体征

```sql
--vspd.vspd_name值根据字典表sam_anar_vspd来
left join (SELECT vs.sam_anar_id,
                  '血压：'||listagg((case when vspd.vspd_name='血压' then vs.vspd_value else null end),';') within group(order by vs.input_date)||'    '
                  ||'心率：'||listagg((case when vspd.vspd_name='心率' then vs.vspd_value else null end),';') within group(order by vs.input_date)||'    '
                  ||'脉搏：'||listagg((case when vspd.vspd_name='脉搏' then vs.vspd_value else null end),';') within group(order by vs.input_date)||'    '
                  ||'氧饱和度：'||listagg((case when vspd.vspd_name='氧饱和度' then vs.vspd_value else null end),';') within group(order by vs.input_date)tzsj
                  FROM sam_anar_vs vs
                  left join sam_anar_vspd vspd on vs.sam_anar_vspd_id=vspd.id
                  group by vs.sam_anar_id)tzsj on tzsj.sam_anar_id=ar.id--体征数据
                  
left join (SELECT vs.sam_anar_id
           FROM sam_anar_vs vs
           inner join (SELECT ar.id FROM sam_anar ar WHERE ar.in_oproom_date between TO_DATE('${kssj}','yyyy-mm-dd hh24:mi:ss') AND TO_DATE(CONCAT('${jssj}',' 23:59:59'),'yyyy-mm-dd hh24:mi:ss'))ar on ar.id = vs.sam_anar_id--事件
           left join sam_anar_vspd vspd on vs.sam_anar_vspd_id=vspd.id
           where vspd.curve_type = 'BIS'
           group by vs.sam_anar_id)tzsj on tzsj.sam_anar_id=ar.id--体征数据
```



###### 正则

```sql
https://baijiahao.baidu.com/s?id=1671336803173846684&wfr=spider&for=pc

YYYY-MM-DD HH:MM:SS： ^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$
时间：regexp_substr(trim(n.node_value),'^\d{2}[:]+\d{2}$')
    小数或数字：REGEXP_LIKE(,'^\-{0,1}[0-9]{0,}\.{0,1}[0-9]{0,}$')
更新中国标准时间格式的字符串为：'yyyy-mm-dd hh24:mi:ss'
update sam_emr_rec_nv n 
set n.node_value = regexp_substr(n.node_value, '[^ ]+', 1, 4)||'-' || 
       decode(regexp_substr(n.node_value, '[^ ]+', 1, 2),
       'Jan','01','Feb','02','Mar','03','Apr','04','May','05','Jun','06','Jul','07','Aug','08','Sep','09','Oct','10','Nov','11','Dec','12',null)||'-'||
       regexp_substr(n.node_value, '[^ ]+', 1, 3)||' ' ||
       regexp_substr(n.node_value, '\d{2}[:]+\d{2}[:]+\d{2}')
where n.node_name in ('jaobrensbtime') and n.node_value like '%中国标准时间%';
```



###### clob数据获取

```sql
--创建函数
CREATE OR REPLACE FUNCTION valuejson(p_jsonstr clob,p_key varchar2) RETURN varchar2
AS
    rtnVal varchar2(1000);
    endInx integer;
BEGIN
  IF instr(p_jsonstr, p_key) = 0 THEN
    rtnVal := '';
    RETURN rtnVal;
  END IF;
  endInx := instr(p_jsonstr,',',instr(p_jsonstr,p_key));
  if 0 = endInx then
    endInx := instr(p_jsonstr,'}',instr(p_jsonstr,p_key));
  end if;
  rtnVal := substr(p_jsonstr,instr(p_jsonstr,p_key),endInx-instr(p_jsonstr,p_key));
  rtnVal := substr(rtnVal,instr(rtnVal,':')+1);
  rtnVal := replace(rtnVal,'"');
  rtnVal := replace(rtnVal,'}');
  RETURN rtnVal;
END valuejson;
--使用
valuejson(字段, '"键值"')
```

###### 时分秒

```sql
floor(info2.pjjtsc * 24) || '小时' || floor(Mod(info2.pjjtsc * 1440, 60)) || '分' ||
 ROUND(Mod(info2.pjjtsc * 1440 * 60, 60), 0) || '秒'
```



###### 输血&输液

```sql
--术中输血&液事件
select sj.sam_apply_id,
                  sum(case when mzsj.s_mzsjlb_dm='32' then (case when j.s_jldw_cmc='L' then sj.single_dose*1000 else sj.single_dose end) else 0 end) 术中液体总量,
                  sum(case when mzsj.s_mzsjlb_dm='32' and mzsj.other_attr='3201' then (case when j.s_jldw_cmc='L' then sj.single_dose*1000 else sj.single_dose end) else 0 end) 术中晶体量,
                  sum(case when mzsj.s_mzsjlb_dm='32' and mzsj.other_attr='3202' then (case when j.s_jldw_cmc='L' then sj.single_dose*1000 else sj.single_dose end) else 0 end) 术中胶体量,
                  sum(case when mzsj.s_mzsjlb_dm='31' then (case when pj.s_jldw_cmc = 'u' then sj.single_dose * 200 when pj.s_jldw_cmc = 'U' then sj.single_dose * 200 when pj.s_jldw_cmc = '治疗量' then sj.single_dose * 200  else sj.single_dose end) else 0 end) 术中输血量,
                  sum(case when mzsj.s_mzsjlb_dm='31' and sj.s_mzsj_dm='31_3' then (case when pj.s_jldw_cmc = 'u' then sj.single_dose * 200 when pj.s_jldw_cmc = 'U' then sj.single_dose * 200 when pj.s_jldw_cmc = '治疗量' then sj.single_dose * 200  else sj.single_dose end) else 0 end) 术中输血浆量,
                  sum(case when mzsj.s_mzsjlb_dm='31' and sj.s_mzsj_dm in ('31_6','31_24') then (case when pj.s_jldw_cmc = 'u' then sj.single_dose * 200 when pj.s_jldw_cmc = 'U' then sj.single_dose * 200 when pj.s_jldw_cmc = '治疗量' then sj.single_dose * 200  else sj.single_dose end) else 0 end) 术中输冷沉淀或血小板量
           from sam_anar_enent sj
           inner join pub_mzsj mzsj on mzsj.s_mzsj_dm=sj.s_mzsj_dm and mzsj.s_mzsjlb_dm=sj.s_mzsjlb_dm
           left join drm_dictionary drm on drm.id = sj.drug_id
           left join drm_nuu_ds n on sj.single_dose_unit = n.id
           left join pub_jldw j on n.udu = j.s_jldw_dm--用药：换算单位（用量的单位）
           left join pub_jldw pj on pj.s_jldw_dm = sj.single_dose_unit--输血：单位
           where mzsj.s_mzsjlb_dm in ('31','32')
           and sj.is_rec_enent='2'
           group by sj.sam_apply_id
```



#### cpt汇总目录



#### 实施沟通

##### cpt测试

你可以改名放到服务器上，复制之前的访问路径，如：http://localhost:8078/WebReport/ReportServer?reportlet=Fshztsf.cpt
然后修改.cpt前面的名字Fshztsf

![img](file:///C:\Users\cDXt\AppData\Roaming\Tencent\Users\2041232076\QQ\WinTemp\RichOle\RUO4$~SYIG7X854~]$C9]}O.png)



#### 视图

```sql
--删除视图
DROP VIEW VIEW_SZDP;
--创建视图
CREATE OR REPLACE VIEW VIEW_SZDP AS
select * from table;
```

![](C:\Users\cDXt\Desktop\转义标注.png)

#### 手麻系统报表配置

![img](file:///D:\QQ\2041232076\Image\C2C\Image1\KEVDWZ59C@L_3DZ5II@{@N6.png)
1.找到功能配置块。看看报表一般放在那块的，
2.右键选择添加报表，如果选择添加功能，需要把url全地址配齐，根据提示，参考别的报表的内容，
如：527006001,准点与延迟开台率,ycktltj.cpt
他会自动拼接系统参数配的报表路径，
3.确定后然后把配好的鼠标右键托给右边对应的角色，
4.刷新即可看到对应处出来你配置的报表