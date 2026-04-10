SELECT c.patient_dept_name,
                 count(distinct c.outpatient_id) rs,
                 sum(case when d.component_name='红细胞'  then a.blood_amount else 0 end) hxb,
                 sum(case when d.component_name='血浆'  then a.blood_amount else 0 end) xj,
                 sum(case when d.component_name='血小板'  then a.blood_amount else 0 end) xxb,
                 sum(case when d.component_name='冷沉淀'  then a.blood_amount else 0 end) lcd,
                 sum(A.BLOOD_CHARGE) charge
                 from xh_bis.bis6_bloodbag_input a
                 inner join xh_bis.bis6_match_blood_type b
                 on a.blood_type_id=b.blood_type_id
                 inner join xh_data.lis6_inspect_sample c
                 on a.inspection_id=c.inspection_id
                 inner join xh_bis.bis6_blood_component d
                 on b.component_id=d.component_id
                 where (@{C:AREA_ID:A.AREA_ID})
                AND (@{C:OUT_DATE:A.OUT_DATE})           
                group by  C.patient_dept_name