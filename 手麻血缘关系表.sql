-- 手麻SQL字段血缘关系表
-- 此表用于帮助AI大模型根据用户描述自动生成SQL查询

CREATE TABLE hand_anesthesia_field_lineage (
    id INT PRIMARY KEY AUTO_INCREMENT,
    field_category VARCHAR(50) COMMENT '字段分类',
    output_field_name VARCHAR(100) COMMENT '输出字段名称',
    source_table VARCHAR(100) COMMENT '源表名',
    source_field VARCHAR(100) COMMENT '源字段名',
    data_type VARCHAR(50) COMMENT '数据类型',
    join_condition TEXT COMMENT '关联条件',
    where_condition TEXT COMMENT '筛选条件',
    calculation_logic TEXT COMMENT '计算逻辑',
    user_keywords TEXT COMMENT '用户可能使用的关键词',
    business_meaning VARCHAR(200) COMMENT '业务含义',
    usage_notes TEXT COMMENT '使用说明',
    priority_level INT COMMENT '优先级(1-高,2-中,3-低)',
    is_complex_field BOOLEAN COMMENT '是否复杂字段',
    created_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) COMMENT '手麻SQL字段血缘关系表';

-- 插入字段血缘关系数据
INSERT INTO hand_anesthesia_field_lineage 
(field_category, output_field_name, source_table, source_field, data_type, join_condition, where_condition, calculation_logic, user_keywords, business_meaning, usage_notes, priority_level, is_complex_field) VALUES

-- 患者基本信息
('患者信息', '患者标识', 'ipi_registration', 'id', 'VARCHAR', 'ipi.id = an.ipi_registration_id', NULL, NULL, '患者标识,患者ID,病人ID', '患者唯一标识符', '主键字段，用于关联患者信息', 1, FALSE),
('患者信息', '患者登记号', 'ipi_registration', 'ipi_registration_no', 'VARCHAR', 'ipi.id = an.ipi_registration_id', NULL, NULL, '患者登记号,登记号,病人号', '患者在医院的登记编号', '用于患者识别的业务号码', 2, FALSE),
('患者信息', '患者姓名', 'SAM_APPLY', 'patient_name', 'VARCHAR', 'AN.SAM_APPLY_ID = T.ID', NULL, NULL, '患者姓名,病人姓名,姓名', '患者的真实姓名', '患者基本信息，用于识别患者身份', 1, FALSE),
('患者信息', '患者科室', 'hra00_department', 'department_chinese_name', 'VARCHAR', 'dep.id=t.patient_dept_id', NULL, NULL, '患者科室,病人科室,科室,所在科室', '患者所属的医院科室', '用于科室统计和筛选', 2, FALSE),

-- 手术基本信息
('手术信息', '手术标识', 'SAM_ANA', 'sam_apply_id', 'VARCHAR', '主表字段', NULL, NULL, '手术标识,手术ID,申请ID', '手术申请的唯一标识', '手术业务主键，用于关联手术相关信息', 1, FALSE),
('手术信息', '手术名称', 'sam_reg_op', 'operation_name', 'VARCHAR', 'reg_p.sam_reg_id = reg.id', NULL, NULL, '手术名称,术式,操作名称,手术', '实际执行的手术名称', '优先使用实际手术信息，而非申请时信息', 1, FALSE),
('手术信息', '手术类型', 'SAM_APPLY', 'oper_type', 'VARCHAR', 'AN.SAM_APPLY_ID = T.ID', "= 'ROOM_OPER'", NULL, '手术类型,操作类型', '手术的分类类型', '通常筛选ROOM_OPER手术间手术', 2, FALSE),
('手术信息', '手术日期', 'SAM_APPLY', 'scheduled_date', 'DATETIME', 'AN.SAM_APPLY_ID = T.ID', NULL, NULL, '手术日期,手术时间,预定时间,计划时间', '预定的手术日期', '用于时间范围筛选的关键字段', 1, FALSE),
('手术信息', '手术间', 'sam_room', 'oper_room', 'VARCHAR', 't.sam_room_id = sr.id', NULL, NULL, '手术间,手术室', '手术执行的手术间编号', '用于手术间管理和统计', 2, FALSE),

-- 时间相关信息
('时间信息', '手术结束时间', 'SAM_ANA', 'oper_end_date', 'DATETIME', '主表字段', NULL, NULL, '手术结束时间,结束时间,完成时间', '手术实际结束的时间', '记录手术完成的准确时间', 2, FALSE),
('时间信息', '进入恢复室时间', 'SAM_ANA', 'rec_in_date', 'DATETIME', '主表字段', NULL, NULL, '进入恢复室时间,恢复室进入时间', '患者进入恢复室的时间', '用于恢复室管理统计', 2, FALSE),
('时间信息', '离开恢复室时间', 'SAM_ANA', 'rec_out_date', 'DATETIME', '主表字段', NULL, NULL, '离开恢复室时间,恢复室离开时间,出恢复室时间', '患者离开恢复室的时间', '用于恢复室管理统计', 2, FALSE),

-- 医生信息
('医生信息', '主刀医生', 'sam_reg_op', 'operator_doctor_id', 'VARCHAR', 'reg_p.sam_reg_id = reg.id', NULL, NULL, '主刀医生,术者,主治医生,手术医生', '执行手术的主刀医生ID', '优先使用实际手术信息', 1, FALSE),
('医生信息', '主刀医生名字', 'hrm_employee', 'employee_name', 'VARCHAR', 'reg_p.operator_doctor_id = ee.id', NULL, NULL, '主刀医生名字,主刀医生姓名,术者姓名', '主刀医生的姓名', '通过医生ID关联获取姓名', 1, FALSE),
('医生信息', '麻醉医生', 'SAM_ANA', 'narcotic_doctor_id', 'VARCHAR', '主表字段', NULL, NULL, '麻醉医生,麻醉师,麻醉科医生', '负责麻醉的医生ID', '麻醉相关的责任医生', 1, FALSE),
('医生信息', '麻醉医生姓名', 'hrm_employee', 'employee_name', 'VARCHAR', 'an.narcotic_doctor_id = ep.id', NULL, NULL, '麻醉医生姓名,麻醉师姓名,麻醉医生名字', '麻醉医生的姓名', '通过麻醉医生ID关联获取姓名', 1, FALSE),

-- 复杂派生字段
('复杂字段', '麻醉方式', 'sam_emr_rec_nv', 'node_value', 'VARCHAR', '复杂子查询', "r.rss_emr_type_id = 'sam_mzfs' AND n.node_name = 'S_MZFS_DM'", 'array_join(array_agg(r.node_value order by r.sam_apply_id), '';'')', '麻醉方式,麻醉类型,麻醉方法', '患者使用的麻醉方式', '需要通过子查询聚合多个麻醉方式', 2, TRUE),
('复杂字段', '是否急诊', 'sam_reg', 'is_emergency', 'VARCHAR', 't.ID = reg.sam_apply_id', NULL, "CASE WHEN reg.is_emergency ='1' THEN '急诊' ELSE '非急诊' END", '是否急诊,急诊,急诊手术', '标识是否为急诊手术', '通过标志位判断急诊状态', 2, TRUE),
('复杂字段', '是否日间', 'sam_reg', 'is_daytime', 'VARCHAR', 't.ID = reg.sam_apply_id', NULL, "CASE WHEN reg.is_daytime='1' THEN '日间' ELSE '非日间' END", '是否日间,日间,日间手术', '标识是否为日间手术', '通过标志位判断日间手术状态', 2, TRUE),
('复杂字段', '去向', 'sam_anar_enent', 'tw_place', 'VARCHAR', 't.id = ent.sam_apply_id', "ent.event_text ='出手术室'", "CASE WHEN ent.tw_place LIKE '%ICU%' THEN 'ICU' WHEN ent.tw_place LIKE '%PACU%' THEN 'PACU' WHEN dept.department_code IS NOT NULL THEN '病房' ELSE '' END", '去向,病人去向,转移去向,出手术室去向', '患者出手术室后的去向', '需要结合科室表判断具体去向', 3, TRUE),

-- 系统控制字段
('系统字段', '医疗机构', 'SAM_APPLY', 'HEALTH_SERVICE_ORG_ID', 'VARCHAR', 'AN.SAM_APPLY_ID = T.ID', "= 'HXSSMZK'", NULL, '医疗机构,医院,机构', '医疗服务机构标识', '固定值HXSSMZK，用于数据隔离', 1, FALSE),
('系统字段', '申请状态', 'SAM_APPLY', 'IS_REJECT', 'VARCHAR', 'AN.SAM_APPLY_ID = T.ID', "= '2'", NULL, '申请状态,审核状态', '手术申请的审核状态', '2表示已通过，用于筛选有效申请', 1, FALSE),
('系统字段', '手术状态', 'SAM_APPLY', 'S_SSSYZT_DM', 'VARCHAR', 'AN.SAM_APPLY_ID = T.ID', "= '90'", NULL, '手术状态,完成状态', '手术的执行状态', '90表示已完成，用于筛选完成的手术', 1, FALSE),
('系统字段', '主要手术标志', 'SAM_APPLY_OP', 'IS_MAIN_OPERATION', 'VARCHAR', 'P.SAM_APPLY_ID = T.ID', "= '1'", NULL, '主要手术,主手术', '是否为主要手术的标志', '1表示主要手术，避免重复统计', 1, FALSE),
('系统字段', '删除标志', '多个表', 'isdeleted', 'VARCHAR', '各表', "= '0'", NULL, '删除标志,有效数据', '记录是否被删除的标志', '0表示未删除，确保数据有效性', 1, FALSE);

-- 创建用户关键词索引，便于快速查找
CREATE INDEX idx_user_keywords ON hand_anesthesia_field_lineage(user_keywords);
CREATE INDEX idx_field_category ON hand_anesthesia_field_lineage(field_category);
CREATE INDEX idx_output_field_name ON hand_anesthesia_field_lineage(output_field_name);

-- 查询示例：根据用户关键词查找相关字段
-- SELECT * FROM hand_anesthesia_field_lineage 
-- WHERE user_keywords LIKE '%患者姓名%' OR user_keywords LIKE '%手术名称%';

-- 创建视图：常用字段组合
CREATE VIEW v_common_surgery_fields AS
SELECT 
    GROUP_CONCAT(DISTINCT 
        CASE 
            WHEN field_category = '患者信息' THEN CONCAT(source_table, '.', source_field, ' AS ', output_field_name)
            WHEN field_category = '手术信息' THEN CONCAT(source_table, '.', source_field, ' AS ', output_field_name)
            WHEN field_category = '医生信息' THEN CONCAT(source_table, '.', source_field, ' AS ', output_field_name)
            WHEN field_category = '时间信息' THEN CONCAT(source_table, '.', source_field, ' AS ', output_field_name)
        END 
        SEPARATOR ',\n    '
    ) AS select_fields,
    GROUP_CONCAT(DISTINCT 
        CASE 
            WHEN join_condition != '主表字段' AND join_condition IS NOT NULL 
            THEN CONCAT('LEFT JOIN ', source_table, ' ON ', join_condition)
        END 
        SEPARATOR '\n'
    ) AS join_statements,
    GROUP_CONCAT(DISTINCT where_condition SEPARATOR ' AND ') AS where_conditions
FROM hand_anesthesia_field_lineage 
WHERE field_category IN ('患者信息', '手术信息', '医生信息', '时间信息')
  AND is_complex_field = FALSE;

-- 创建存储过程：根据关键词生成SQL片段
DELIMITER //

CREATE PROCEDURE GetSQLFragmentByKeywords(IN keywords VARCHAR(1000))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE field_info TEXT;
    DECLARE select_part TEXT DEFAULT '';
    DECLARE join_part TEXT DEFAULT '';
    DECLARE where_part TEXT DEFAULT '';
    
    DECLARE cur CURSOR FOR 
        SELECT CONCAT(
            source_table, '.', source_field, ' AS ', output_field_name,
            IF(join_condition != '主表字段' AND join_condition IS NOT NULL, 
               CONCAT('\n-- JOIN: LEFT JOIN ', source_table, ' ON ', join_condition), ''),
            IF(where_condition IS NOT NULL, 
               CONCAT('\n-- WHERE: ', where_condition), ''),
            IF(calculation_logic IS NOT NULL, 
               CONCAT('\n-- CALC: ', calculation_logic), '')
        ) as field_info
        FROM hand_anesthesia_field_lineage 
        WHERE user_keywords LIKE CONCAT('%', keywords, '%')
        ORDER BY priority_level, field_category;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO field_info;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET select_part = CONCAT(select_part, field_info, ',\n');
    END LOOP;
    
    CLOSE cur;
    
    SELECT TRIM(TRAILING ',\n' FROM select_part) AS suggested_fields;
END //

DELIMITER ;

-- 使用示例
-- CALL GetSQLFragmentByKeywords('患者姓名');
-- CALL GetSQLFragmentByKeywords('主刀医生'); 