# AI大模型SQL生成指南 - 手麻系统

## 一、核心原则

### 1. 统一库名规则
所有表名前缀统一为：`hid0101_orcl_operaanesthisa_emrhis.`

### 2. 主表关联策略  
- **主表**: `SAM_ANA` (别名: an) - 麻醉记录表
- **核心关联**: `SAM_APPLY` (别名: t) - 手术申请表
- **关联条件**: `an.SAM_APPLY_ID = t.ID`

### 3. 必需的WHERE条件模板
```sql
WHERE t.HEALTH_SERVICE_ORG_ID = 'HXSSMZK'
  AND t.OPER_TYPE = 'ROOM_OPER'  
  AND t.IS_REJECT = '2'
  AND t.S_SSSYZT_DM = '90'
  AND t.isdeleted = '0'
```

## 二、字段映射快速查表

### 用户描述词 -> SQL字段映射

| 用户可能的描述 | 输出字段名 | SELECT片段 | JOIN要求 |
|---------------|-----------|------------|----------|
| **患者姓名, 病人姓名, 姓名** | 患者姓名 | `t.patient_name AS 患者姓名` | 基础关联即可 |
| **患者ID, 病人ID, 患者标识** | 患者标识 | `ipi.id AS 患者标识` | `LEFT JOIN ipi_registration ipi ON ipi.id = an.ipi_registration_id` |
| **患者登记号, 登记号, 病人号** | 患者登记号 | `ipi.ipi_registration_no AS 患者登记号` | `LEFT JOIN ipi_registration ipi ON ipi.id = an.ipi_registration_id` |
| **患者科室, 病人科室, 科室** | 患者科室 | `dep.department_chinese_name AS 患者科室` | `LEFT JOIN hra00_department dep ON dep.id=t.patient_dept_id` |
| **手术名称, 术式, 操作名称** | 手术名称 | `reg_p.operation_name AS 手术名称` | 需要登记表关联 |
| **手术日期, 手术时间, 预定时间** | 手术日期 | `t.scheduled_date AS 手术日期` | 基础关联即可 |
| **手术间, 手术室** | 手术间 | `sr.oper_room AS 手术间` | `LEFT JOIN sam_room sr ON t.sam_room_id = sr.id` |
| **主刀医生, 术者, 手术医生** | 主刀医生名字 | `ee.employee_name AS 主刀医生名字` | 需要员工表关联 |
| **麻醉医生, 麻醉师** | 麻醉医生姓名 | `ep.employee_name AS 麻醉医生姓名` | 需要员工表关联 |
| **手术结束时间, 结束时间** | 手术结束时间 | `an.oper_end_date AS 手术结束时间` | 基础关联即可 |
| **恢复室** | 进入/离开恢复室时间 | `an.rec_in_date, an.rec_out_date` | 基础关联即可 |
| **急诊** | 是否急诊 | `CASE WHEN reg.is_emergency='1' THEN '急诊' ELSE '非急诊' END AS 是否急诊` | 需要登记表 |
| **日间** | 是否日间 | `CASE WHEN reg.is_daytime='1' THEN '日间' ELSE '非日间' END AS 是否日间` | 需要登记表 |

## 三、标准JOIN模板

### 基础关联（最小必需）
```sql
FROM hid0101_orcl_operaanesthisa_emrhis.SAM_ANA an 
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.SAM_APPLY t ON an.SAM_APPLY_ID = t.ID
```

### 扩展关联模板（按需添加）
```sql
-- 手术登记信息（获取实际手术信息）
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg ON t.ID = reg.sam_apply_id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op reg_p ON reg_p.sam_reg_id = reg.id

-- 患者信息
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ipi ON ipi.id = an.ipi_registration_id

-- 科室信息  
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department dep ON dep.id=t.patient_dept_id

-- 医生信息
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ee ON reg_p.operator_doctor_id = ee.id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ep ON an.narcotic_doctor_id = ep.id

-- 手术间信息
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_room sr ON t.sam_room_id = sr.id

-- 麻醉事件（病人去向）
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent ent ON t.id = ent.sam_apply_id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department dept ON ent.tw_place = dept.department_code
```

### 复杂字段：麻醉方式
```sql
-- 麻醉方式子查询
LEFT JOIN (
    SELECT r.sam_apply_id, 
           array_join(array_agg(r.node_value ORDER BY r.sam_apply_id), ';') AS mzfscmc 
    FROM (
        SELECT sam_apply_id, node_value 
        FROM hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec r
        LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec_nv n ON n.sam_emr_rec_id = r.id
        WHERE r.rss_emr_type_id = 'sam_mzfs' 
          AND n.node_name = 'S_MZFS_DM' 
          AND r.isdeleted = '0' 
          AND n.isdeleted = '0' 
        GROUP BY sam_apply_id, node_value
    ) r 
    GROUP BY r.sam_apply_id
) mz ON an.sam_apply_id = mz.sam_apply_id
```

## 四、WHERE条件构建策略

### 基础条件（必须包含）
```sql
WHERE t.HEALTH_SERVICE_ORG_ID = 'HXSSMZK'
  AND t.OPER_TYPE = 'ROOM_OPER'
  AND t.IS_REJECT = '2'
  AND t.S_SSSYZT_DM = '90'
  AND t.isdeleted = '0'
```

### 数据完整性条件（按需添加）
```sql
-- 如果使用了相关表，需要添加对应的isdeleted条件
AND reg.isdeleted = '0'          -- 使用sam_reg时
AND reg_p.isdeleted = '0'        -- 使用sam_reg_op时  
AND ipi.isdeleted = '0'          -- 使用ipi_registration时
AND ee.isdeleted = '0'           -- 使用hrm_employee(主刀医生)时
AND ep.isdeleted = '0'           -- 使用hrm_employee(麻醉医生)时
AND sr.isdeleted = '0'           -- 使用sam_room时
AND ent.isdeleted = '0'          -- 使用sam_anar_enent时
```

### 业务条件映射

| 用户描述 | WHERE条件 |
|---------|-----------|
| **时间范围查询** | `AND t.SCHEDULED_DATE BETWEEN '开始时间' AND '结束时间'` |
| **指定科室** | `AND t.patient_dept_id = '科室ID'` 或 `AND dep.department_chinese_name = '科室名称'` |
| **指定医生** | `AND (reg_p.operator_doctor_id = '医生ID' OR an.narcotic_doctor_id = '医生ID')` |
| **急诊手术** | `AND reg.is_emergency = '1'` |
| **日间手术** | `AND reg.is_daytime = '1'` |
| **未进恢复室** | `AND an.REC_IN_DATE IS NULL` |
| **未出恢复室** | `AND an.rec_out_date IS NULL` |
| **指定手术间** | `AND sr.oper_room = '手术间编号'` |
| **特定事件** | `AND ent.event_text = '出手术室'` |

## 五、SQL生成决策树

### 第一步：识别核心需求
```
用户提到 → 添加对应字段 → 确定JOIN需求
├─ 患者信息 → patient_name, ipi.* → 需要ipi_registration
├─ 手术信息 → operation_name, scheduled_date → 需要sam_reg_op  
├─ 医生信息 → employee_name → 需要hrm_employee
├─ 科室信息 → department_chinese_name → 需要hra00_department
├─ 时间信息 → oper_end_date, rec_in_date → 基础表即可
└─ 复杂计算 → 麻醉方式、去向等 → 需要特殊处理
```

### 第二步：构建JOIN语句
```
根据需要的字段 → 确定JOIN顺序 → 添加对应isdeleted条件
```

### 第三步：构建WHERE条件
```  
基础条件(必需) + 业务条件(按需) + 数据完整性条件(按表)
```

## 六、常见SQL模板

### 模板1：基础患者手术信息
```sql
SELECT 
    ipi.id AS 患者标识,
    t.patient_name AS 患者姓名,
    reg_p.operation_name AS 手术名称,
    t.scheduled_date AS 手术日期,
    ee.employee_name AS 主刀医生名字,
    ep.employee_name AS 麻醉医生姓名
FROM hid0101_orcl_operaanesthisa_emrhis.SAM_ANA an
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.SAM_APPLY t ON an.SAM_APPLY_ID = t.ID
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg ON t.ID = reg.sam_apply_id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op reg_p ON reg_p.sam_reg_id = reg.id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ipi ON ipi.id = an.ipi_registration_id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ee ON reg_p.operator_doctor_id = ee.id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ep ON an.narcotic_doctor_id = ep.id
WHERE t.HEALTH_SERVICE_ORG_ID = 'HXSSMZK'
  AND t.OPER_TYPE = 'ROOM_OPER'
  AND t.IS_REJECT = '2'
  AND t.S_SSSYZT_DM = '90'
  AND t.isdeleted = '0'
  AND reg.isdeleted = '0'
  AND reg_p.isdeleted = '0'
  AND ipi.isdeleted = '0'
  AND ee.isdeleted = '0'
  AND ep.isdeleted = '0';
```

### 模板2：包含时间筛选
```sql
-- 在模板1基础上添加时间条件
AND t.SCHEDULED_DATE BETWEEN '2024-08-01 00:00:00' AND '2024-11-01 23:59:59'
```

### 模板3：恢复室相关
```sql  
-- 在基础模板上添加恢复室字段和条件
SELECT ..., 
    an.rec_in_date AS 进入恢复室时间,
    an.rec_out_date AS 离开恢复室时间
FROM ...
WHERE ... 
  AND (an.REC_IN_DATE IS NULL OR an.rec_out_date IS NULL)  -- 未完成恢复室流程
```

## 七、错误避免指南

### 常见错误及解决方案

1. **表名错误**: 必须使用完整的库名前缀
2. **字段优先级错误**: 手术名称优先用sam_reg_op.operation_name，不是SAM_APPLY_OP.operation_name  
3. **缺少isdeleted条件**: 每个JOIN的表都要添加对应的isdeleted = '0'
4. **JOIN顺序错误**: 先关联sam_reg，再关联sam_reg_op
5. **WHERE条件遗漏**: 基础的5个WHERE条件必须包含

### 调试检查清单
- [ ] 库名前缀正确
- [ ] 基础WHERE条件完整  
- [ ] JOIN表的isdeleted条件添加
- [ ] 字段来源表正确（特别是手术名称和医生信息）
- [ ] 复杂字段的子查询正确

## 八、使用示例

### 示例1：用户输入"查询患者姓名和主刀医生"
```sql
SELECT 
    t.patient_name AS 患者姓名,
    ee.employee_name AS 主刀医生名字
FROM hid0101_orcl_operaanesthisa_emrhis.SAM_ANA an
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.SAM_APPLY t ON an.SAM_APPLY_ID = t.ID
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg ON t.ID = reg.sam_apply_id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg_op reg_p ON reg_p.sam_reg_id = reg.id
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hrm_employee ee ON reg_p.operator_doctor_id = ee.id
WHERE t.HEALTH_SERVICE_ORG_ID = 'HXSSMZK'
  AND t.OPER_TYPE = 'ROOM_OPER'
  AND t.IS_REJECT = '2'
  AND t.S_SSSYZT_DM = '90'
  AND t.isdeleted = '0'
  AND reg.isdeleted = '0'
  AND reg_p.isdeleted = '0'
  AND ee.isdeleted = '0';
```

通过这个指南，AI大模型可以根据用户的自然语言描述，快速准确地生成符合手麻系统业务规则的SQL查询语句。 