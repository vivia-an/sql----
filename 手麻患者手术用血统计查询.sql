-- 手麻患者手术用血统计查询
-- 适配Presto查询引擎，统一库名：hid0101_orcl_operaanesthisa_emrhis
-- 包含逻辑删除筛选条件

WITH patient_surgery_base AS (
    -- 基础手术患者信息
    SELECT 
        -- 患者基本信息 (来源: SAM_APPLY)
        t.id AS apply_id,                                    -- 申请单ID
        t.patient_name,                                      -- 患者姓名 [SAM_APPLY.PATIENT_NAME]
        t.person_info_id,                                    -- 患者ID [SAM_APPLY.PERSON_INFO_ID] 
        t.s_xb_dm AS gender_code,                           -- 性别代码 [SAM_APPLY.S_XB_DM]
        CASE t.s_xb_dm 
            WHEN '1' THEN '男'
            WHEN '2' THEN '女' 
            ELSE '未知'
        END AS gender_name,                                  -- 性别名称
        t.age,                                              -- 年龄 [SAM_APPLY.AGE]
        t.s_nldw_dm AS age_unit_code,                       -- 年龄单位代码 [SAM_APPLY.S_NLDW_DM]
        t.birthday,                                         -- 出生日期 [SAM_APPLY.BIRTHDAY]
        t.patient_dept_id,                                  -- 患者科室ID [SAM_APPLY.PATIENT_DEPT_ID]
        t.bed_no,                                           -- 床号 [SAM_APPLY.BED_NO]
        t.main_diag,                                        -- 主要诊断 [SAM_APPLY.MAIN_DIAG]
        
        -- 医生信息 (来源: SAM_APPLY)
        t.req_doctor_id,                                    -- 开单医生ID [SAM_APPLY.REQ_DOCTOR_ID]
        req_doc.name AS req_doctor_name,                    -- 开单医生姓名 [HRM_EMPLOYEE.NAME]
        t.doctor_id AS attending_doctor_id,                 -- 主治医生ID [SAM_APPLY.DOCTOR_ID]
        att_doc.name AS attending_doctor_name,              -- 主治医生姓名 [HRM_EMPLOYEE.NAME]
        
        -- 手术基本信息 (来源: SAM_APPLY)
        t.scheduled_date,                                   -- 预计手术时间 [SAM_APPLY.SCHEDULED_DATE]
        t.req_date,                                         -- 申请时间 [SAM_APPLY.REQ_DATE]
        t.oper_room,                                        -- 手术间 [SAM_APPLY.OPER_ROOM]
        t.health_service_org_id                             -- 医疗机构ID [SAM_APPLY.HEALTH_SERVICE_ORG_ID]
        
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply t
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee req_doc 
        ON t.req_doctor_id = req_doc.id 
        AND req_doc.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee att_doc 
        ON t.doctor_id = att_doc.id 
        AND att_doc.isdeleted = '0'
    WHERE t.health_service_org_id = 'HXSSMZK'              -- 医疗机构限制
        AND t.oper_type = 'ROOM_OPER'                       -- 手术类型限制
        AND t.is_reject = '2'                               -- 未拒收
        AND t.s_sssyzt_dm = '90'                           -- 手术状态
        AND t.isdeleted = '0'                               -- 逻辑删除筛选
),

surgery_operation_info AS (
    -- 手术操作详细信息
    SELECT 
        sao.sam_apply_id,
        -- 手术信息 (来源: SAM_APPLY_OP)
        sao.operation_code,                                 -- 手术编码 [SAM_APPLY_OP.OPERATION_CODE]
        sao.operation_name,                                 -- 手术名称 [SAM_APPLY_OP.OPERATION_NAME]
        sao.operator_doctor_id,                             -- 主刀医生ID [SAM_APPLY_OP.OPERATOR_DOCTOR_ID]
        op_doc.name AS operator_doctor_name,                -- 主刀医生姓名 [HRM_EMPLOYEE.NAME]
        sao.operator_begin_date,                            -- 手术开始时间 [SAM_APPLY_OP.OPERATOR_BEGIN_DATE]
        sao.operator_end_date,                              -- 手术结束时间 [SAM_APPLY_OP.OPERATOR_END_DATE]
        sao.s_ssjb_dm AS surgery_level_code,               -- 手术级别代码 [SAM_APPLY_OP.S_SSJB_DM]
        sl.s_ssjb_cmc AS surgery_level_name,               -- 手术级别名称 [PUB_SSJB.S_SSJB_CMC]
        sao.s_mzfs_dm AS anesthesia_method_code,           -- 麻醉方式代码 [SAM_APPLY_OP.S_MZFS_DM]
        sao.narcotic_doctor_id,                             -- 麻醉医师ID [SAM_APPLY_OP.NARCOTIC_DOCTOR_ID]
        nar_doc.name AS narcotic_doctor_name,               -- 麻醉医师姓名 [HRM_EMPLOYEE.NAME]
        sao.is_main_operation,                              -- 是否主手术 [SAM_APPLY_OP.IS_MAIN_OPERATION]
        
        -- 时间计算
        CASE 
            WHEN sao.operator_begin_date IS NOT NULL AND sao.operator_end_date IS NOT NULL 
            THEN date_diff('minute', sao.operator_begin_date, sao.operator_end_date)
            ELSE NULL
        END AS surgery_duration_minutes                     -- 手术持续时间(分钟)
        
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply_op sao
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee op_doc 
        ON sao.operator_doctor_id = op_doc.id 
        AND op_doc.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee nar_doc 
        ON sao.narcotic_doctor_id = nar_doc.id 
        AND nar_doc.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_ssjb sl 
        ON sao.s_ssjb_dm = sl.s_ssjb_dm
    WHERE sao.isdeleted = '0'
),

blood_usage_info AS (
    -- 手术用血信息
    SELECT 
        ae.sam_apply_id,
        -- 用血信息 (来源: SAM_ANAR_ENENT)
        ae.s_mzsjlb_dm AS event_type_code,                  -- 事件类别代码 [SAM_ANAR_ENENT.S_MZSJLB_DM]
        ae.s_mzsj_dm AS event_code,                         -- 事件代码 [SAM_ANAR_ENENT.S_MZSJ_DM]
        ae.event_text,                                      -- 事件正文 [SAM_ANAR_ENENT.EVENT_TEXT]
        ae.btm_bp_catalog_id,                               -- 血制品目录ID [SAM_ANAR_ENENT.BTM_BP_CATALOG_ID]
        bp.product_name AS blood_product_name,              -- 血制品名称 [BTM_BP_CATALOG.PRODUCT_NAME]
        ae.btm_spec_dict_id,                                -- 血制品规格ID [SAM_ANAR_ENENT.BTM_SPEC_DICT_ID]
        bs.spec AS blood_spec,                              -- 血制品规格 [BTM_SPEC_DICT.SPEC]
        bs.pack_unit AS blood_unit,                         -- 包装单位 [BTM_SPEC_DICT.PACK_UNIT]
        ae.single_dose AS blood_volume,                     -- 输血量 [SAM_ANAR_ENENT.SINGLE_DOSE]
        ae.single_dose_unit AS blood_volume_unit,           -- 输血量单位 [SAM_ANAR_ENENT.SINGLE_DOSE_UNIT]
        ae.exec_date AS blood_exec_time,                    -- 执行时间(取血/输血时间) [SAM_ANAR_ENENT.EXEC_DATE]
        ae.bb_barcode AS blood_bag_barcode,                 -- 血袋条码 [SAM_ANAR_ENENT.BB_BARCODE]
        ae.bp_barcode AS blood_product_barcode,             -- 血制品条码 [SAM_ANAR_ENENT.BP_BARCODE]
        ae.s_aboxx_dm AS abo_blood_type,                    -- ABO血型 [SAM_ANAR_ENENT.S_ABOXX_DM]
        ae.s_rhxx_dm AS rh_blood_type,                      -- RH血型 [SAM_ANAR_ENENT.S_RHXX_DM]
        
        -- 血制品分类
        CASE 
            WHEN bp.product_name LIKE '%红细胞%' OR bp.product_name LIKE '%RBC%' THEN '红细胞'
            WHEN bp.product_name LIKE '%血浆%' OR bp.product_name LIKE '%PLASMA%' THEN '血浆'
            WHEN bp.product_name LIKE '%血小板%' OR bp.product_name LIKE '%PLT%' THEN '血小板'
            WHEN bp.product_name LIKE '%冷沉淀%' OR bp.product_name LIKE '%CRYO%' THEN '冷沉淀'
            ELSE '其他血制品'
        END AS blood_product_category                       -- 血制品分类
        
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ae
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.btm_bp_catalog bp 
        ON ae.btm_bp_catalog_id = bp.id 
        AND bp.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.btm_spec_dict bs 
        ON ae.btm_spec_dict_id = bs.id 
        AND bs.isdeleted = '0'
    WHERE ae.s_mzsjlb_dm = '04'                            -- 输血事件类别
        AND ae.btm_bp_catalog_id IS NOT NULL               -- 有血制品信息
        AND ae.isdeleted = '0'
)

-- 主查询：整合所有信息
SELECT 
    -- 患者基本信息
    psb.apply_id AS "申请单ID",                                           -- 申请单ID
    psb.patient_name AS "患者姓名",                                       -- 患者姓名
    psb.person_info_id AS "患者ID",                                     -- 患者ID  
    psb.gender_name AS "性别",                                        -- 性别
    psb.age AS "年龄",                                                -- 年龄
    psb.age_unit_code AS "年龄单位",                                      -- 年龄单位
    psb.birthday AS "出生日期",                                           -- 出生日期
    psb.patient_dept_id AS "患者科室ID",                                    -- 患者科室ID
    psb.bed_no AS "床号",                                             -- 床号
    psb.main_diag AS "主要诊断",                                          -- 主要诊断
    
    -- 医生信息
    psb.req_doctor_name AS "开单医生",                                    -- 开单医生
    psb.attending_doctor_name AS "主治医生",                              -- 主治医生
    soi.operator_doctor_name AS "主刀医生",                               -- 主刀医生
    soi.narcotic_doctor_name AS "麻醉医师",                               -- 麻醉医师
    
    -- 手术信息
    date_format(soi.operator_begin_date, '%Y-%m-%d') AS "手术日期",           -- 手术日期
    date_format(soi.operator_begin_date, '%H:%i:%s') AS "手术开始时间",     -- 手术开始时间
    date_format(soi.operator_end_date, '%H:%i:%s') AS "手术结束时间",         -- 手术结束时间
    soi.operation_name AS "手术名称",                                     -- 手术名称
    soi.surgery_level_name AS "手术分级",                                 -- 手术分级
    soi.surgery_duration_minutes AS "手术持续时间_分钟",                           -- 手术持续时间(分钟)
    
    -- 手术用血信息
    bui.blood_product_category AS "输血品种分类",                             -- 输血品种分类
    bui.blood_product_name AS "具体血制品名称",                                 -- 具体血制品名称
    bui.blood_volume AS "输血量",                                       -- 输血量
    bui.blood_volume_unit AS "输血量单位",                                  -- 输血量单位
    date_format(bui.blood_exec_time, '%Y-%m-%d %H:%i:%s') AS "取血输血时间",       -- 取血/输血时间
    bui.blood_bag_barcode AS "血袋条码",                                  -- 血袋条码
    bui.abo_blood_type AS "ABO血型",                                     -- ABO血型
    bui.rh_blood_type AS "RH血型",                                      -- RH血型
    
    -- 统计字段
    CASE WHEN bui.blood_product_category IS NOT NULL THEN 1 ELSE 0 END AS "是否用血标识",  -- 是否用血标识
    
    -- 时间戳字段（用于筛选）
    soi.operator_begin_date AS "手术开始完整时间",            -- 手术开始完整时间
    psb.req_date AS "申请时间"                          -- 申请时间

FROM patient_surgery_base psb
LEFT JOIN surgery_operation_info soi ON psb.apply_id = soi.sam_apply_id
LEFT JOIN blood_usage_info bui ON psb.apply_id = bui.sam_apply_id

-- 结果排序
ORDER BY 
    soi.operator_begin_date DESC,                          -- 按手术时间倒序
    psb.apply_id,                                          -- 按申请单ID
    bui.blood_exec_time                                    -- 按用血时间

-- 注释：字段来源说明
/*
字段血缘关系汇总：
1. 患者信息主要来源：SAM_APPLY表
2. 医生信息来源：SAM_APPLY表的医生ID + HRM_EMPLOYEE表的姓名
3. 手术详细信息来源：SAM_APPLY_OP表
4. 手术级别来源：PUB_SSJB字典表
5. 用血信息来源：SAM_ANAR_ENENT事件表
6. 血制品信息来源：BTM_BP_CATALOG目录表 + BTM_SPEC_DICT规格表

核心关联逻辑：
- SAM_APPLY (主表) ← SAM_APPLY_OP (手术操作)
- SAM_APPLY ← SAM_ANAR_ENENT (麻醉事件，通过SAM_APPLY_ID关联)
- 所有医生ID通过HRM_EMPLOYEE表获取姓名
- 血制品通过BTM_BP_CATALOG和BTM_SPEC_DICT获取详细信息

筛选条件说明：
- 医疗机构：HXSSMZK
- 手术类型：ROOM_OPER
- 未拒收：IS_REJECT = '2'
- 手术状态：S_SSSYZT_DM = '90'
- 输血事件：S_MZSJLB_DM = '04'
- 逻辑删除：所有表都加入 isdeleted = '0' 筛选
*/ 