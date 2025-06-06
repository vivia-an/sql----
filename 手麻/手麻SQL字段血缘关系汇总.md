# 手麻SQL字段血缘关系汇总

## 一、主要数据表结构（基于Presto查询引擎）

### 1. 核心业务表
- `sam_anar` - 麻醉记录表（主表）
- `sam_apply` - 手术申请表
- `sam_apply_op` - 手术申请操作表
- `sam_reg` - 手术登记表  
- `sam_reg_op` - 手术登记操作表（实际手术信息）

### 2. 患者相关表
- `ipi_registration` - 住院患者登记表
- `opc_registration` - 门诊患者登记表
- `hra00_person_info` - 个人基本信息表
- `hra00_department` - 科室部门表

### 3. 人员相关表
- `hrm_employee` - 员工表（医生、护士信息）
- `pub_gzlb` - 工作类别代码表

### 4. 设备场所表
- `sam_room` - 手术间表
- `sam_anar_enent` - 麻醉记录事件表（包含输血、用药等事件）

### 5. 电子病历表
- `sam_emr_rec` - 电子病历记录表
- `sam_emr_rec_nv` - 电子病历记录节点值表

### 6. 字典表
- `pub_sssyzt` - 手术使用状态代码表
- `pub_ssjb` - 手术级别代码表
- `pub_mzfs` - 麻醉方式代码表
- `pub_asamzfj` - ASA麻醉分级代码表
- `gb_t_2261_1_2003` - 性别代码表
- `pub_ssqk_dj` - 手术切口等级代码表
- `pub_jldw` - 计量单位代码表

## 二、字段血缘关系（按输出字段分类）

### A. 患者基本信息
| 输出字段名 | 源表 | 源字段 | 数据类型 | 关联条件 | 备注 |
|-----------|------|--------|----------|----------|------|
| 患者住院号 | ipi_registration | ipi_registration_no | VARCHAR | ipi.id = nvl(reg.ipi_registration_id,a.ipi_registration_id) | 住院登记号 |
| 患者门诊号 | opc_registration | opc_registration_no | VARCHAR | opc.id = nvl(reg.opc_registration_id,a.opc_registration_id) | 门诊登记号 |
| 患者姓名 | sam_apply/sam_reg | patient_name | VARCHAR | nvl(reg.patient_name,a.patient_name) | 优先使用登记表姓名 |
| 性别 | gb_t_2261_1_2003 | s_xb_cmc | VARCHAR | xb.s_xb_dm = nvl(reg.s_xb_dm,a.s_xb_dm) | 性别中文名称 |
| 年龄 | 计算字段 | - | VARCHAR | f_j_getage(日期,生日) 或字符串计算 | 年龄计算函数 |
| 患者科室 | hra00_department | department_chinese_name | VARCHAR | de.id = nvl(reg.patient_dept_id,a.patient_dept_id) | 患者所属科室 |
| 床号 | sam_apply/sam_reg | bed_no | VARCHAR | nvl(reg.bed_no,a.bed_no) | 患者床位号 |
| 证件号码 | ipi_registration/opc_registration | identity_no | VARCHAR | nvl(ipi.identity_no,opc.identity_no) | 身份证等证件号 |

### B. 手术基本信息
| 输出字段名 | 源表 | 源字段 | 数据类型 | 关联条件 | 备注 |
|-----------|------|--------|----------|----------|------|
| 手术申请号 | sam_apply | opa_no | VARCHAR | nvl(reg.opa_no,a.opa_no) | 手术申请编号 |
| 手术名称 | sam_reg_op/sam_apply_op | operation_name | VARCHAR | nvl(rop.operation_name,aop.operation_name) | 优先实际手术名称 |
| 手术编码 | sam_reg_op/sam_apply_op | operation_code | VARCHAR | nvl(rop.operation_code,aop.operation_code) | ICD-9编码 |
| 手术日期 | sam_apply | scheduled_date | VARCHAR | a.scheduled_date | 预定手术日期 |
| 手术间 | sam_room | oper_room | VARCHAR | rm.id = nvl(reg.sam_room_id,a.sam_room_id) | 手术间编号 |
| 手术级别 | pub_ssjb | s_ssjb_cmc | VARCHAR | ssjb.s_ssjb_dm = nvl(rop.s_ssjb_dm,aop.s_ssjb_dm) | 手术级别中文名称 |
| 手术类型 | sam_apply/sam_reg | is_emergency,is_daytime | VARCHAR | case when急诊择期日间逻辑 | 急诊/择期/日间 |
| 台次 | 计算字段 | - | NUMBER | row_number() over分区计算 | 当日手术间台次 |

### C. 时间相关信息
| 输出字段名 | 源表 | 源字段 | 数据类型 | 关联条件 | 备注 |
|-----------|------|--------|----------|----------|------|
| 入室时间 | sam_anar | in_oproom_date | VARCHAR | ar.sam_apply_id = a.id | 进入手术室时间 |
| 出室时间 | sam_anar | out_oproom_date | VARCHAR | ar.sam_apply_id = a.id | 离开手术室时间 |
| 手术开始时间 | sam_anar | oper_beging_date | VARCHAR | ar.sam_apply_id = a.id | 手术开始时间 |
| 手术结束时间 | sam_anar | oper_end_date | VARCHAR | ar.sam_apply_id = a.id | 手术结束时间 |
| 麻醉开始时间 | sam_anar | ana_beging_date | VARCHAR | ar.sam_apply_id = a.id | 麻醉开始时间 |
| 麻醉结束时间 | sam_anar | ana_end_date | VARCHAR | ar.sam_apply_id = a.id | 麻醉结束时间 |
| 入PACU时间 | sam_anar | rec_in_date | VARCHAR | ar.sam_apply_id = a.id | 进入恢复室时间 |
| 出PACU时间 | sam_anar | rec_out_date | VARCHAR | ar.sam_apply_id = a.id | 离开恢复室时间 |

### D. 医生护士信息
| 输出字段名 | 源表 | 源字段 | 数据类型 | 关联条件 | 备注 |
|-----------|------|--------|----------|----------|------|
| 主刀医生 | hrm_employee | employee_name | VARCHAR | zd.id = nvl(rop.operator_doctor_id,aop.operator_doctor_id) | 主刀医生姓名 |
| 麻醉医生 | hrm_employee | employee_name | VARCHAR | mz.id = nvl(rop.narcotic_doctor_id,aop.narcotic_doctor_id) | 麻醉医生姓名 |
| 麻醉助手1 | hrm_employee | employee_name | VARCHAR | mzzs1.id = nvl(rop.narcotic_assistant_1,aop.narcotic_assistant_1) | 麻醉助手1姓名 |
| 麻醉助手2 | hrm_employee | employee_name | VARCHAR | mzzs2.id = nvl(rop.narcotic_assistant_2,aop.narcotic_assistant_2) | 麻醉助手2姓名 |
| 巡回护士 | hrm_employee | employee_name | VARCHAR | xh.id = nvl(rop.circuit_nurse_01,aop.circuit_nurse_01) | 巡回护士姓名 |
| 洗手护士 | hrm_employee | employee_name | VARCHAR | xs.id = nvl(rop.scrub_nurse_01,aop.scrub_nurse_01) | 洗手护士姓名 |
| 申请医生 | hrm_employee | employee_name | VARCHAR | sqys.id = nvl(reg.req_doctor_id,a.req_doctor_id) | 申请医生姓名 |

### E. 麻醉相关信息
| 输出字段名 | 源表 | 源字段 | 数据类型 | 关联条件 | 备注 |
|-----------|------|--------|----------|----------|------|
| 麻醉方式 | 复杂子查询 | - | VARCHAR | 通过sam_emr_rec获取 | 需要特殊处理 |
| ASA分级 | pub_asamzfj | s_asamzfj_cmc | VARCHAR | pasa.s_asamzfj_dm = nvl(rop.s_asamzfj_dm,aop.s_asamzfj_dm) | ASA分级中文名称 |
| 切口等级 | pub_ssqk_dj | s_ssqk_dj_cmc | VARCHAR | qk.s_ssqk_dj_dm = nvl(rop.s_ssqk_dj_dm,aop.s_ssqk_dj_dm) | 切口等级 |
| 诊断 | sam_apply/sam_reg | main_diag | VARCHAR | nvl(reg.main_diag,a.main_diag) | 主要诊断 |

### F. 血液制品信息（通过麻醉事件表获取）
| 输出字段名 | 源表 | 源字段 | 数据类型 | 关联条件 | 备注 |
|-----------|------|--------|----------|----------|------|
| 血液制品类型 | sam_anar_enent | event_text | VARCHAR | en.s_mzsjlb_dm = '31' | 输血事件 |
| 血液制品用量 | sam_anar_enent | single_dose | VARCHAR | en.s_mzsjlb_dm = '31' | 输血剂量 |
| 输血时间 | sam_anar_enent | ordered_date | VARCHAR | en.s_mzsjlb_dm = '31' | 输血时间 |
| 红细胞 | sam_anar_enent | event_text | VARCHAR | en.event_text like '%红细胞%' | 红细胞制品 |
| 血浆 | sam_anar_enent | event_text | VARCHAR | en.event_text like '%血浆%' | 血浆制品 |
| 血小板 | sam_anar_enent | event_text | VARCHAR | en.event_text like '%血小板%' | 血小板制品 |

## 三、表关联关系图（适配Presto）

### 主要关联路径
```
sam_apply (手术申请表)
├── sam_anar (麻醉记录) [ar.sam_apply_id = a.id]
├── sam_reg (手术登记) [reg.id = a.id]
│   ├── sam_reg_op (手术登记操作) [rop.sam_reg_id = reg.id]
│   └── ipi_registration (住院患者) [ipi.id = reg.ipi_registration_id]
│   └── opc_registration (门诊患者) [opc.id = reg.opc_registration_id]
├── sam_apply_op (手术申请操作) [aop.sam_apply_id = a.id]
├── hra00_department (科室) [de.id = a.patient_dept_id]
├── sam_room (手术间) [rm.id = a.sam_room_id]
├── sam_anar_enent (麻醉事件) [en.sam_apply_id = a.id]
├── hrm_employee (各类医护人员) [多个关联条件]
└── 各种字典表
```

## 四、关键过滤条件（Presto适配）

### 数据有效性条件
| 条件 | 说明 | 作用 |
|------|------|------|
| isdeleted = '0' | 逻辑删除标志 | 所有表必须添加 |
| health_service_org_id = 'HXSSMZK' | 医疗机构限制 | 指定医院 |
| oper_type = 'ROOM_OPER' | 手术类型限制 | 手术间手术 |
| is_reject = '2' | 申请状态 | 已通过申请 |
| s_sssyzt_dm = '90' | 手术状态 | 已完成手术 |

### Presto特殊处理
| 条件 | 说明 | Presto处理 |
|------|------|-----------|
| 中文字段名 | 需要双引号包围 | AS "患者姓名" |
| varchar日期 | 字段都是varchar类型 | 使用substr()函数处理 |
| 库名统一 | 所有表添加库名前缀 | hid0101_orcl_operaanesthisa_emrhis. |
| 年龄计算 | varchar字符串计算 | substr()提取年份计算 |

## 五、复杂字段解析（Presto版本）

### 1. 麻醉方式字段获取
```sql
-- 通过电子病历记录获取麻醉方式
SELECT r.sam_apply_id,
       array_join(array_agg(DISTINCT n.node_value), ';') AS "麻醉方式"
FROM hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec r
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec_nv n 
  ON n.sam_emr_rec_id = r.id
WHERE r.rss_emr_type_id = 'sam_mzfs'
  AND n.node_name = 'S_MZFS_DM'
  AND r.isdeleted = '0'
  AND n.isdeleted = '0'
GROUP BY r.sam_apply_id
```

### 2. 年龄计算（varchar适配）
```sql
-- Presto中varchar日期的年龄计算
CASE 
    WHEN length(info.birthday) >= 4 AND length(info.scheduled_date) >= 4
    THEN CAST(CAST(substr(info.scheduled_date, 1, 4) AS INTEGER) - 
              CAST(substr(info.birthday, 1, 4) AS INTEGER) AS VARCHAR)
    ELSE ''
END AS "年龄"
```

### 3. 台次计算
```sql
-- 手术台次计算
ROW_NUMBER() OVER(
    PARTITION BY info.room_id, substr(info.scheduled_date, 1, 10) 
    ORDER BY info.in_oproom_date, info.operator_begin_date
) AS "台次"
```

### 4. 血液制品聚合查询
```sql
-- 血液制品信息聚合
SELECT en.sam_apply_id,
       array_join(array_agg(
           CASE WHEN en.event_text LIKE '%红细胞%' 
                THEN en.event_text || ':' || CAST(en.single_dose AS VARCHAR) || 'ml'
                ELSE NULL END
       ), ';') AS "红细胞制品",
       array_join(array_agg(
           CASE WHEN en.event_text LIKE '%血浆%' 
                THEN en.event_text || ':' || CAST(en.single_dose AS VARCHAR) || 'ml'
                ELSE NULL END
       ), ';') AS "血浆制品",
       array_join(array_agg(
           CASE WHEN en.event_text LIKE '%血小板%' 
                THEN en.event_text || ':' || CAST(en.single_dose AS VARCHAR) || 'ml'
                ELSE NULL END
       ), ';') AS "血小板制品"
FROM hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent en
WHERE en.s_mzsjlb_dm = '31'  -- 输血事件
  AND en.isdeleted = '0'
GROUP BY en.sam_apply_id
```

## 六、推荐的SQL生成策略（Presto版本）

### 1. 基础查询模板
```sql
SELECT 
    -- 患者信息
    COALESCE(ieg.ipi_registration_no, opc.opc_registration_no) AS "患者住院号",
    info.patient_name AS "患者姓名",
    xb.s_xb_cmc AS "性别",
    CASE 
        WHEN length(info.birthday) >= 4 AND length(info.scheduled_date) >= 4
        THEN CAST(CAST(substr(info.scheduled_date, 1, 4) AS INTEGER) - 
                  CAST(substr(info.birthday, 1, 4) AS INTEGER) AS VARCHAR)
        ELSE ''
    END AS "年龄",
    dpt.department_chinese_name AS "科室",
    
    -- 手术信息
    info.operation_name AS "手术名称",
    info.operation_code AS "手术编码",
    ssjb.s_ssjb_cmc AS "手术级别",
    rm.oper_room AS "手术间",
    
    -- 时间信息
    info.in_oproom_date AS "入室时间",
    info.out_oproom_date AS "出室时间",
    info.operator_begin_date AS "手术开始时间",
    info.operator_end_date AS "手术结束时间",
    
    -- 医生信息
    ssem.employee_name AS "主刀医生",
    mzem.employee_name AS "麻醉医生"
    
FROM (
    -- 主查询逻辑，整合sam_apply, sam_reg, sam_anar等核心表
    SELECT 
        a.id AS apply_id,
        COALESCE(reg.patient_name, a.patient_name) AS patient_name,
        COALESCE(reg.birthday, a.birthday) AS birthday,
        COALESCE(reg.ipi_registration_id, a.ipi_registration_id) AS ipi_registration_id,
        COALESCE(reg.opc_registration_id, a.opc_registration_id) AS opc_registration_id,
        COALESCE(reg.patient_dept_id, a.patient_dept_id) AS patient_dept_id,
        COALESCE(reg.sam_room_id, a.sam_room_id) AS room_id,
        COALESCE(reg.s_xb_dm, a.s_xb_dm) AS s_xb_dm,
        a.scheduled_date,
        ar.in_oproom_date,
        ar.out_oproom_date,
        ar.oper_beging_date AS operator_begin_date,
        ar.oper_end_date AS operator_end_date,
        COALESCE(rop.operation_name, aop.operation_name) AS operation_name,
        COALESCE(rop.operation_code, aop.operation_code) AS operation_code,
        COALESCE(rop.operator_doctor_id, aop.operator_doctor_id) AS operator_doctor_id,
        COALESCE(rop.narcotic_doctor_id, aop.narcotic_doctor_id) AS narcotic_doctor_id,
        COALESCE(rop.s_ssjb_dm, aop.s_ssjb_dm) AS s_ssjb_dm
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg 
      ON reg.id = a.id AND reg.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar 
      ON ar.sam_apply_id = a.id AND ar.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply_op aop 
      ON aop.sam_apply_id = a.id AND aop.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op rop 
      ON rop.sam_reg_id = reg.id AND rop.isdeleted = '0'
    WHERE a.health_service_org_id = 'HXSSMZK'
      AND a.oper_type = 'ROOM_OPER'
      AND a.is_reject = '2'
      AND a.s_sssyzt_dm = '90'
      AND a.isdeleted = '0'
) info
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ieg 
  ON ieg.id = info.ipi_registration_id AND ieg.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.opc_registration opc 
  ON opc.id = info.opc_registration_id AND opc.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department dpt 
  ON dpt.id = info.patient_dept_id AND dpt.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_room rm 
  ON rm.id = info.room_id AND rm.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.gb_t_2261_1_2003 xb 
  ON xb.s_xb_dm = info.s_xb_dm
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.pub_ssjb ssjb 
  ON ssjb.s_ssjb_dm = info.s_ssjb_dm
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ssem 
  ON ssem.id = info.operator_doctor_id AND ssem.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee mzem 
  ON mzem.id = info.narcotic_doctor_id AND mzem.isdeleted = '0'
```

## 七、AI生成SQL参考指南

### 用户描述 -> 字段映射（Presto版本）
| 用户描述 | 对应字段 | 源表 | Presto处理 |
|----------|----------|------|-----------|
| 患者姓名/病人姓名 | patient_name | sam_apply/sam_reg | nvl()函数优先级 |
| 手术名称/术式 | operation_name | sam_reg_op/sam_apply_op | nvl()函数优先级 |
| 主刀医生/术者 | employee_name | hrm_employee | 通过doctor_id关联 |
| 麻醉医生/麻醉师 | employee_name | hrm_employee | 通过narcotic_doctor_id关联 |
| 手术时间/手术日期 | scheduled_date | sam_apply | varchar类型，注意格式化 |
| 血液制品/输血 | event_text, single_dose | sam_anar_enent | s_mzsjlb_dm = '31' |
| 红细胞 | event_text | sam_anar_enent | event_text like '%红细胞%' |
| 血浆 | event_text | sam_anar_enent | event_text like '%血浆%' |
| 血小板 | event_text | sam_anar_enent | event_text like '%血小板%' |

### 常用WHERE条件模板（Presto版本）
```sql
-- 基础条件（必须）
WHERE a.health_service_org_id = 'HXSSMZK'
  AND a.oper_type = 'ROOM_OPER'
  AND a.is_reject = '2'
  AND a.s_sssyzt_dm = '90'
  AND a.isdeleted = '0'
  AND reg.isdeleted = '0'
  AND ar.isdeleted = '0'

-- 时间条件（varchar处理）
  AND a.scheduled_date BETWEEN '{开始时间}' AND '{结束时间}'

-- 血液制品条件
  AND en.s_mzsjlb_dm = '31'  -- 输血事件类别
  AND en.event_text LIKE '%{血液制品类型}%'

-- 字段别名（中文需要双引号）
SELECT field AS "中文字段名"
```

## 八、血液制品专项字段映射

### 血液制品事件表字段详解
| 字段名 | 字段含义 | 数据示例 | 筛选条件 |
|--------|----------|----------|----------|
| s_mzsjlb_dm | 麻醉事件类别代码 | '31' | 输血事件 |
| event_text | 事件内容/血液制品名称 | '悬浮红细胞', '新鲜冰冻血浆' | 血液制品类型 |
| single_dose | 单次剂量/用量 | 200, 400 | 输血量(ml) |
| single_dose_unit | 剂量单位 | 'ml', 'u' | 计量单位 |
| ordered_date | 医嘱时间/输血时间 | '2024-01-01 10:30:00' | 输血时间点 |
| sam_apply_id | 手术申请ID | 关联主表 | 表关联字段 |

### 常见血液制品类型匹配
```sql
CASE 
    WHEN en.event_text LIKE '%红细胞%' OR en.event_text LIKE '%RBC%' THEN '红细胞'
    WHEN en.event_text LIKE '%血浆%' OR en.event_text LIKE '%FFP%' THEN '血浆'  
    WHEN en.event_text LIKE '%血小板%' OR en.event_text LIKE '%PLT%' THEN '血小板'
    WHEN en.event_text LIKE '%全血%' THEN '全血'
    WHEN en.event_text LIKE '%白蛋白%' THEN '白蛋白'
    WHEN en.event_text LIKE '%免疫球蛋白%' THEN '免疫球蛋白'
    ELSE '其他血液制品'
END AS "血液制品类型"
``` 