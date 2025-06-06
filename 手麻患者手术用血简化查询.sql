-- 手麻患者手术用血简化查询 (日常统计版本)
-- 适配Presto查询引擎，优化性能

SELECT 
    -- 基础患者信息
    t.patient_name AS "患者姓名",                              -- [SAM_APPLY.PATIENT_NAME]
    t.person_info_id AS "患者ID",                             -- [SAM_APPLY.PERSON_INFO_ID]
    CASE t.s_xb_dm WHEN '1' THEN '男' WHEN '2' THEN '女' ELSE '未知' END AS "性别",
    t.age AS "年龄",                                          -- [SAM_APPLY.AGE]
    t.bed_no AS "床号",                                       -- [SAM_APPLY.BED_NO]
    
    -- 医生信息
    req_doc.name AS "开单医生",                               -- [HRM_EMPLOYEE.NAME]
    op_doc.name AS "主刀医生",                                -- [HRM_EMPLOYEE.NAME] 
    
    -- 手术信息
    date_format(sao.operator_begin_date, '%Y-%m-%d') AS "手术日期",
    date_format(sao.operator_begin_date, '%H:%i') AS "手术开始时间",
    date_format(sao.operator_end_date, '%H:%i') AS "手术结束时间",
    sao.operation_name AS "手术名称",                         -- [SAM_APPLY_OP.OPERATION_NAME]
    sl.s_ssjb_cmc AS "手术分级",                             -- [PUB_SSJB.S_SSJB_CMC]
    
    -- 用血信息
    CASE 
        WHEN bp.product_name LIKE '%红细胞%' THEN '红细胞'
        WHEN bp.product_name LIKE '%血浆%' THEN '血浆'
        WHEN bp.product_name LIKE '%血小板%' THEN '血小板'
        WHEN bp.product_name LIKE '%冷沉淀%' THEN '冷沉淀'
        ELSE bp.product_name
    END AS "输血品种",                                         -- [BTM_BP_CATALOG.PRODUCT_NAME]
    ae.single_dose AS "输血量",                              -- [SAM_ANAR_ENENT.SINGLE_DOSE]
    ae.single_dose_unit AS "输血单位",                       -- [SAM_ANAR_ENENT.SINGLE_DOSE_UNIT]
    date_format(ae.exec_date, '%Y-%m-%d %H:%i') AS "输血时间"  -- [SAM_ANAR_ENENT.EXEC_DATE]

FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply t
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply_op sao 
    ON t.id = sao.sam_apply_id 
    AND sao.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee req_doc 
    ON t.req_doctor_id = req_doc.id 
    AND req_doc.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee op_doc 
    ON sao.operator_doctor_id = op_doc.id 
    AND op_doc.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_ssjb sl 
    ON sao.s_ssjb_dm = sl.s_ssjb_dm
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ae 
    ON t.id = ae.sam_apply_id 
    AND ae.s_mzsjlb_dm = '04'  -- 输血事件
    AND ae.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.btm_bp_catalog bp 
    ON ae.btm_bp_catalog_id = bp.id 
    AND bp.isdeleted = '0'

WHERE t.health_service_org_id = 'HXSSMZK'
    AND t.oper_type = 'ROOM_OPER'
    AND t.is_reject = '2'
    AND t.s_sssyzt_dm = '90'
    AND t.isdeleted = '0'
    AND sao.operator_begin_date >= date('2024-01-01')  -- 可调整时间范围

ORDER BY sao.operator_begin_date DESC, t.patient_name;


-- ========================================
-- 统计分析查询示例
-- ========================================

-- 1. 按血制品类型统计用血量
/*
SELECT 
    CASE 
        WHEN bp.product_name LIKE '%红细胞%' THEN '红细胞'
        WHEN bp.product_name LIKE '%血浆%' THEN '血浆'
        WHEN bp.product_name LIKE '%血小板%' THEN '血小板'
        WHEN bp.product_name LIKE '%冷沉淀%' THEN '冷沉淀'
        ELSE '其他'
    END AS "血制品类型",
    COUNT(*) AS "使用次数",
    SUM(ae.single_dose) AS "总用量",
    AVG(ae.single_dose) AS "平均用量",
    ae.single_dose_unit AS "单位"
FROM hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ae
JOIN hid0101_orcl_operaanesthisa_emrhis.btm_bp_catalog bp ON ae.btm_bp_catalog_id = bp.id
WHERE ae.s_mzsjlb_dm = '04' AND ae.isdeleted = '0' AND bp.isdeleted = '0'
GROUP BY "血制品类型", ae.single_dose_unit
ORDER BY "使用次数" DESC;
*/

-- 2. 按科室统计用血情况
/*
SELECT 
    dept.department_chinese_name AS "科室名称",
    COUNT(DISTINCT t.id) AS "手术台次",
    COUNT(ae.id) AS "用血次数",
    SUM(ae.single_dose) AS "总用血量"
FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply t
JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department dept ON t.patient_dept_id = dept.id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ae ON t.id = ae.sam_apply_id AND ae.s_mzsjlb_dm = '04'
WHERE t.health_service_org_id = 'HXSSMZK' AND t.isdeleted = '0'
GROUP BY dept.department_chinese_name
HAVING COUNT(ae.id) > 0
ORDER BY "用血次数" DESC;
*/

-- 3. 按手术级别统计用血率
/*
SELECT 
    sl.s_ssjb_cmc AS "手术级别",
    COUNT(DISTINCT sao.sam_apply_id) AS "手术总数",
    COUNT(DISTINCT ae.sam_apply_id) AS "用血手术数",
    ROUND(COUNT(DISTINCT ae.sam_apply_id) * 100.0 / COUNT(DISTINCT sao.sam_apply_id), 2) AS "用血率_百分比"
FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply_op sao
JOIN hid0101_orcl_operaanesthisa_emrhis.pub_ssjb sl ON sao.s_ssjb_dm = sl.s_ssjb_dm
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ae ON sao.sam_apply_id = ae.sam_apply_id AND ae.s_mzsjlb_dm = '04'
WHERE sao.isdeleted = '0'
GROUP BY sl.s_ssjb_cmc
ORDER BY "用血率_百分比" DESC;
*/ 