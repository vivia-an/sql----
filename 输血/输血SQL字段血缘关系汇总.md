# 输血SQL字段血缘关系汇总 (更新版)

## 1. 核心表结构说明 (基于电子病历评级SQL完整分析)

### 1.1 BIS6_BLOODBAG_INPUT (血袋入库记录表) - 核心主表
- **数据库名称**: `hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT`
- **表功能**: 记录血液入库、出库和库存管理信息的核心表
- **核心字段**:
  - `BLOODBAG_ID`: 血袋编号 (主键，唯一标识)
  - `BLOOD_TYPE_ID`: 血液类型ID (关联键)
  - `ABO_BLOOD_GROUP`: ABO血型 ('O型', 'A型', 'B型', 'AB型')
  - `RH_BLOOD_GROUP`: RH血型
  - `BLOOD_AMOUNT`: 血液数量 (用于统计血量)
  - `BLOOD_UNIT`: 血液单位
  - `BLOODBAG_STATE`: 血袋状态 ('1'=入库, '2'=出库, 排除 '14','15','16')
  - `AREA_ID`: 院区ID (A001=本院, A002=温江, A003=天府, A004=锦江)
  - `IN_TIME` / `IN_DATE`: 入库时间 (字段名有变化)
  - `OUT_DATE`: 出库时间
  - `INSPECTION_ID`: 检验单ID (关联检验样本表)
  - `PAT_ID`: 患者标识 (关联患者)
  - `SENDBLOOD_TIME`: 输血时间 (实际输血执行时间)
  - `PREPARATION_DATE`: 制备日期/捐血时间
  - `OUT_PERSON`: 出库操作人员
  - `BLOOD_BAG_CODE`: 血袋编码/捐血者编码
  - `isdeleted`: 逻辑删除标识 ('0' 表示有效)

### 1.2 BIS6_BLOODBAG_MATCH (配血匹配记录表) - 核心业务表
- **数据库名称**: `hid0101_orcl_lis_xhbis.bis6_bloodbag_match`
- **表功能**: 记录配血操作过程和匹配结果，电子病历评级核心表
- **核心字段**:
  - `MATCH_ID`: 配血记录ID (主键)
  - `MACTH_DATE`: 配血时间 (注意：原始字段名拼写)
  - `BLOODBAG_ID`: 血袋编号/入库ID (关联BIS6_BLOODBAG_INPUT)
  - `INSPECTION_ID`: 检验单ID/标本标识 (关联LIS_INSPECTION_RESULT)
  - `MATCH_STATE`: 配血状态 (排除 '-1' 无效状态)
  - `METHOD_TYPE_ID`: 配血方法 (排除 '4' 无效方法)
  - `MACTH_PERSON`: 配血人 (操作人员)
  - `MATCH_CHECK_PERSON`: 配血核对人员
  - `BLOOD_charge_state`: 收费状态 ('charged'=已收费)
  - `isdeleted`: 逻辑删除标识 ('0' 表示有效)

### 1.3 BIS6_BLOODBAG_INFUSION (输血记录表) - 输血执行表
- **数据库名称**: `hid0101_orcl_lis_bis6.BIS6_BLOODBAG_INFUSION`
- **表功能**: 记录实际输血执行过程和时间
- **核心字段**:
  - `BLOODBAG_ID`: 血袋编号 (关联键，连接主表)
  - `R_CHECK_TIME`: 输血时间 (实际输血核查时间)
  - `PATIENT_ID`: 患者标识
  - `INFUSION_STATUS`: 输血状态
  - `isdeleted`: 逻辑删除标识 ('0' 表示有效)

### 1.4 BIS6_MATCH_BLOOD_TYPE (血型匹配关系表) - 关联表
- **数据库名称**: `hid0101_orcl_lis_bis6.BIS6_MATCH_BLOOD_TYPE`
- **表功能**: 建立血液类型与血液成分的匹配关系
- **核心字段**:
  - `BLOOD_TYPE_ID`: 血液类型ID (关联键，连接主表)
  - `COMPONENT_ID`: 血液成分ID (关联键，连接成分字典表)
  - `BLOOD_NAME`: 血液项目名称
  - `isdeleted`: 逻辑删除标识 ('0' 表示有效)

### 1.5 BIS6_BLOOD_COMPONENT (血液成分字典表) - 字典表
- **数据库名称**: `hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT`
- **表功能**: 血液成分代码字典
- **核心字段**:
  - `COMPONENT_ID`: 血液成分编码 (主键)
    - `'00000009'`: 红细胞悬液 (hxb)
    - `'00000010'`: 血小板 (xj)
    - `'00000011'`: 新鲜冰冻血浆 (xxb)
    - `'00000012'`: 冷沉淀 (lcd)
  - `COMPONENT_NAME`: 血液成分名称
  - `isdeleted`: 逻辑删除标识 ('0' 表示有效)

### 1.6 LIS_INSPECTION_RESULT (检验结果表) - 检验数据表
- **数据库名称**: `hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT` ⚠️**注意库名修正**
- **表功能**: 检验结果信息，电子病历评级核心关联表
- **核心字段**:
  - `INSPECTION_ID`: 检验单ID/标本标识 (关联键)
  - `OUTPATIENT_ID`: 患者标识 (门诊/住院号)
  - `QUANTITATIVE_RESULT`: 定量检验结果
  - `CHINESE_NAME`: 配血检验项目名称
  - `TEST_ITEM_ID`: 检验项目ID
  - `GROUP_ID`: 血型编码 (用于血型一致性检查)
  - `REMARK`: 有效标记
  - `isdeleted`: 逻辑删除标识 ('0' 表示有效)

### 1.7 LIS6_INSPECT_SAMPLE (检验样本表) - 出库关联表
- **数据库名称**: `hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE`
- **表功能**: 检验样本信息，用于出库记录关联和样本统计
- **核心字段**:
  - `INSPECTION_ID`: 检验单ID (关联键)
  - `PATIENT_ID`: 患者标识
  - `SAMPLE_INFO`: 样本信息
  - `SAMPLE_TYPE`: 样本类型
  - `COLLECT_TIME`: 采集时间
  - `RECEIVE_TIME`: 接收时间
  - `isdeleted`: 逻辑删除标识 ('0' 表示有效)

## 2. 完整SQL血缘关系分析 (基于电子病历评级SQL)

### 2.1 核心表关联关系

#### 2.1.1 电子病历评级核心三表关联模式
```sql
-- 配血记录核心关联 (电子病历评级主要模式)
FROM (SELECT MACTH_DATE AS "配血时间", BLOODBAG_ID AS "入库ID", 
             INSPECTION_ID AS "标本标识", MATCH_STATE AS "配血状态",
             METHOD_TYPE_ID AS "配血方法", MACTH_PERSON AS "配血人",
             MATCH_CHECK_PERSON AS "核对人"
      FROM hid0101_orcl_lis_xhbis.bis6_bloodbag_match) "用血清单"
INNER JOIN (SELECT BLOODBAG_ID AS "入库ID", ABO_BLOOD_GROUP AS "血型编码",
                   OUT_DATE AS "出库时间", IN_DATE AS "入库时间",
                   BLOOD_TYPE_ID AS "血液编码", BLOOD_BAG_CODE AS "血袋编号",
                   BLOOD_AMOUNT AS "数量", BLOOD_UNIT AS "单位",
                   PAT_ID AS "患者标识", SENDBLOOD_TIME AS "输血时间"
            FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT) "血库记录表"
    ON "用血清单"."入库ID" = "血库记录表"."入库ID"
INNER JOIN (SELECT INSPECTION_ID AS "标本标识", OUTPATIENT_ID AS "患者标识",
                   QUANTITATIVE_RESULT AS "检验结果", 
                   CHINESE_NAME AS "配血检验项目名称",
                   GROUP_ID AS "血型编码"
            FROM hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT) "检验结果表"
    ON "用血清单"."标本标识" = "检验结果表"."标本标识"
```

#### 2.1.2 统计查询四表关联模式
```sql
-- 血液库存统计关联 (统计查询主要模式) 
FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a                    -- 主表(血袋记录)
INNER JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type b            -- 关联表(血型匹配)
    ON a.BLOOD_TYPE_ID = b.BLOOD_TYPE_ID
INNER JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c             -- 字典表(血液成分)
    ON b.COMPONENT_ID = c.COMPONENT_ID
INNER JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT d             -- 检验表(关联检验)
    ON a.INSPECTION_ID = d.INSPECTION_ID
-- 可选关联LIS6_INSPECT_SAMPLE (用于出库统计时)
-- LEFT JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE e
--     ON a.INSPECTION_ID = e.INSPECTION_ID
```

#### 2.1.3 输血时效性分析关联模式
```sql
-- 输血时效性分析关联
FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT "血库记录表"
INNER JOIN hid0101_orcl_lis_bis6.BIS6_BLOODBAG_INFUSION "输血记录表"
    ON "血库记录表".BLOODBAG_ID = "输血记录表".BLOODBAG_ID
-- 时效性检查: 入库时间 < 出库时间 < 输血时间
WHERE "血库记录表".OUT_DATE > "血库记录表".IN_DATE 
  AND "输血记录表".R_CHECK_TIME > "血库记录表".OUT_DATE
```

#### 2.1.4 检验样本关联模式 (出库统计)
```sql
-- 出库记录与检验样本关联 (用于出库统计和样本分析)
FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a                    -- 主表(血袋记录)
INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE e            -- 检验样本表(出库关联)
    ON a.INSPECTION_ID = e.INSPECTION_ID
-- 用于出库记录的样本信息关联和时间分析
WHERE a.BLOODBAG_STATE IN ('2')  -- 出库状态
  AND e.isdeleted = '0'           -- 有效样本
```

### 2.2 核心业务维度血缘分析

#### 2.2.1 电子病历评级维度 ⭐️
**配血完整性评级字段血缘:**
- **患者标识**: `OUTPATIENT_ID` (来源: LIS_INSPECTION_RESULT.OUTPATIENT_ID)
- **配血检验项目**: `CHINESE_NAME` (来源: LIS_INSPECTION_RESULT.CHINESE_NAME)
- **检验结果**: `QUANTITATIVE_RESULT` (来源: LIS_INSPECTION_RESULT.QUANTITATIVE_RESULT)
- **配血时间**: `MACTH_DATE` (来源: BIS6_BLOODBAG_MATCH.MACTH_DATE)
- **配血人员**: `MACTH_PERSON` (来源: BIS6_BLOODBAG_MATCH.MACTH_PERSON)
- **核对人员**: `MATCH_CHECK_PERSON` (来源: BIS6_BLOODBAG_MATCH.MATCH_CHECK_PERSON)

**配血一致性评级字段血缘:**
- **血型编码**: `ABO_BLOOD_GROUP` (来源: BIS6_BLOODBAG_INPUT.ABO_BLOOD_GROUP)
- **检验血型**: `GROUP_ID` (来源: LIS_INSPECTION_RESULT.GROUP_ID)
- **血液项目名称**: `BLOOD_NAME` (来源: BIS6_MATCH_BLOOD_TYPE.BLOOD_NAME)

**时效性评级字段血缘:**
- **入库时间**: `IN_DATE`/`IN_TIME` (来源: BIS6_BLOODBAG_INPUT)
- **出库时间**: `OUT_DATE` (来源: BIS6_BLOODBAG_INPUT.OUT_DATE)
- **输血时间**: `R_CHECK_TIME` (来源: BIS6_BLOODBAG_INFUSION.R_CHECK_TIME)
- **配血时间**: `MACTH_DATE` (来源: BIS6_BLOODBAG_MATCH.MACTH_DATE)

#### 2.2.2 血型维度
**字段血缘关系:**
- **血型字段**: `ABO_BLOOD_GROUP` (来源: BIS6_BLOODBAG_INPUT)
- **血型取值**: 'O型', 'A型', 'B型', 'AB型'
- **统计逻辑**: 按血型分组统计不同血液成分

#### 2.2.3 血液成分维度  
**字段血缘关系:**
- **成分编码**: `COMPONENT_ID` (来源: BIS6_BLOOD_COMPONENT)
- **成分映射**:
  - `'00000009'` → 红细胞悬液 (hxb)
  - `'00000010'` → 血小板 (xj)  
  - `'00000011'` → 新鲜冰冻血浆 (xxb)
  - `'00000012'` → 冷沉淀 (lcd)

#### 2.2.4 统计单位维度
**计数维度:**
- **袋数统计**: `COUNT(DISTINCT BLOODBAG_ID)` - 按血袋唯一编号计数
- **血量统计**: `SUM(CAST(BLOOD_AMOUNT AS DOUBLE))` - 按血液数量求和

#### 2.2.5 记录类型维度
**业务场景:**
- **库存记录**: `BLOODBAG_STATE IN ('1','2')` - 包含入库和出库状态
- **有效记录**: `BLOODBAG_STATE NOT IN ('1','2','14','15','16')` - 排除无效状态
- **配血记录**: `MATCH_STATE <> '-1'` AND `METHOD_TYPE_ID <> '4'` - 有效配血
- **收费记录**: `BLOOD_charge_state = 'charged'` - 已收费配血

### 2.3 关键筛选条件血缘

#### 2.3.1 电子病历评级通用筛选条件 ⭐️
**核心业务筛选:**
```sql
-- 有效配血记录筛选
WHERE "用血清单"."配血状态" <> '-1'           -- 排除无效配血状态
  AND "用血清单"."配血方法" <> '4'            -- 排除无效配血方法  
  AND "血库记录表"."血液记录标识" NOT IN ('1','2','14','15','16') -- 排除无效血液状态
  AND "用血清单"."配血时间" BETWEEN '时间范围'  -- 评级时间范围筛选
```

**数据完整性筛选:**
```sql
-- 字段非空检查
AND "检验结果表"."检验结果" IS NOT NULL       -- 检验结果完整性
AND "用血清单"."配血时间" IS NOT NULL        -- 配血时间完整性  
AND "血库记录表"."血型编码" IS NOT NULL      -- 血型编码完整性
```

#### 2.3.2 逻辑删除筛选
**字段血缘**: `isdeleted = '0'` (所有表统一的逻辑删除标识)

#### 2.3.3 血袋状态筛选  
**字段血缘**: `BLOODBAG_STATE`
- **状态含义**: '1'=入库状态, '2'=出库状态
- **库存查询**: `IN ('1','2')` - 包含所有有效状态
- **评级查询**: `NOT IN ('1','2','14','15','16')` - 排除特定状态

#### 2.3.4 配血状态筛选
**字段血缘**: `MATCH_STATE` (来源: BIS6_BLOODBAG_MATCH)
- **有效配血**: `<> '-1'` - 排除无效配血状态
- **配血方法**: `METHOD_TYPE_ID <> '4'` - 排除无效配血方法

#### 2.3.5 院区维度筛选
**字段血缘**: `AREA_ID` (院区编码)
- **院区映射**:
  - `A001` → 本院
  - `A002` → 温江
  - `A003` → 天府  
  - `A004` → 锦江

#### 2.3.6 时效性筛选条件
**时间逻辑验证:**
```sql
-- 输血时效性检查
WHERE "血库记录表"."出库时间" > "血库记录表"."入库时间"    -- 出库晚于入库
  AND "输血记录表"."输血时间" > "血库记录表"."出库时间"    -- 输血晚于出库
  AND "用血清单"."配血时间" < "血库记录表"."出库时间"     -- 配血早于出库
```

## 3. 统计查询核心SQL模式

### 3.1 基础统计模式
```sql
-- 按血型和成分统计（袋数）
COUNT(DISTINCT CASE WHEN c.component_id='成分编码' AND a.abo_blood_group='血型' 
                    THEN a.bloodbag_id END) AS "统计结果"

-- 按血型和成分统计（血量）  
SUM(CASE WHEN c.component_id='成分编码' AND a.abo_blood_group='血型' 
         THEN CAST(a.blood_amount AS DOUBLE) ELSE 0 END) AS "统计结果"
```

### 3.2 通用筛选条件
```sql
-- 统计查询必需条件
WHERE a.isdeleted = '0'                    -- 逻辑删除筛选
  AND a.bloodbag_state IN ('1','2')       -- 血袋状态筛选(库存记录)
  AND a.area_id = '院区编码'               -- 院区筛选(参数化)
```

### 3.3 分类统计条件
```sql
-- 库存记录条件
WHERE a.bloodbag_state IN ('1','2')

-- 入库记录条件  
WHERE -- 按入库时间筛选
  AND (@{C:IN_TIME:A.IN_TIME})

-- 出库记录条件
INNER JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE d 
    ON a.inspection_id = d.inspection_id
WHERE -- 按出库时间筛选
  AND (@{C:IN_TIME:A.OUT_DATE})
```

## 4. 数据质量要求和优化建议

### 4.1 数据质量要求
1. **逻辑删除**: 所有表必须添加 `isdeleted = '0'` 筛选
2. **字段类型**: 数值字段使用 `CAST(field AS DOUBLE)` 转换
3. **中文字段**: Presto要求用双引号包围中文字段名
4. **关联完整性**: 确保 blood_type_id, component_id, inspection_id 关联有效

### 4.2 性能优化建议
1. **索引建议**: 在 bloodbag_state, area_id, abo_blood_group, component_id 上建立索引
2. **分区设计**: 按院区(area_id)或时间分区
3. **物化视图**: 对于频繁查询的统计结果考虑物化视图
4. **查询优化**: 避免不必要的DISTINCT和复杂CASE表达式

## 5. 字段映射对照表 (完整版基于电子病历评级SQL)

### 5.1 BIS6_BLOODBAG_INPUT (血袋入库记录表)
| 业务字段 | 数据库字段 | 字段类型 | 说明 |
|---------|-----------|----------|------|
| 血袋编号 | BLOODBAG_ID | VARCHAR | 血袋唯一标识(主键) |
| 血液类型ID | BLOOD_TYPE_ID | VARCHAR | 血液类型标识(关联键) |
| ABO血型 | ABO_BLOOD_GROUP | VARCHAR | ABO血型('O型','A型','B型','AB型') |
| RH血型 | RH_BLOOD_GROUP | VARCHAR | RH血型 |
| 血液数量 | BLOOD_AMOUNT | VARCHAR | 血液数量(需转换为DOUBLE) |
| 血液单位 | BLOOD_UNIT | VARCHAR | 血液单位 |
| 血袋状态 | BLOODBAG_STATE | VARCHAR | 血袋状态('1'=入库,'2'=出库,排除'14','15','16') |
| 院区编码 | AREA_ID | VARCHAR | 院区ID(A001,A002,A003,A004) |
| 入库时间 | IN_TIME/IN_DATE | VARCHAR | 血液入库时间(字段名有变化) |
| 出库时间 | OUT_DATE | VARCHAR | 血液出库时间 |
| 检验单ID | INSPECTION_ID | VARCHAR | 检验单标识(关联键) |
| 患者标识 | PAT_ID | VARCHAR | 患者标识 |
| 输血时间 | SENDBLOOD_TIME | VARCHAR | 输血时间(实际输血执行时间) |
| 制备日期 | PREPARATION_DATE | VARCHAR | 制备日期/捐血时间 |
| 出库操作人员 | OUT_PERSON | VARCHAR | 出库操作人员 |
| 血袋编码 | BLOOD_BAG_CODE | VARCHAR | 血袋编码/捐血者编码 |
| 逻辑删除标识 | isdeleted | VARCHAR | 逻辑删除('0'=有效) |

### 5.2 BIS6_BLOODBAG_MATCH (配血匹配记录表) ⭐️
| 业务字段 | 数据库字段 | 字段类型 | 说明 |
|---------|-----------|----------|------|
| 配血记录ID | MATCH_ID | VARCHAR | 配血记录主键 |
| 配血时间 | MACTH_DATE | VARCHAR | 配血时间(注意原始拼写) |
| 血袋编号 | BLOODBAG_ID | VARCHAR | 血袋编号/入库ID(关联键) |
| 检验单ID | INSPECTION_ID | VARCHAR | 检验单ID/标本标识(关联键) |
| 配血状态 | MATCH_STATE | VARCHAR | 配血状态(排除'-1'无效状态) |
| 配血方法 | METHOD_TYPE_ID | VARCHAR | 配血方法(排除'4'无效方法) |
| 配血人 | MACTH_PERSON | VARCHAR | 配血操作人员 |
| 配血核对人 | MATCH_CHECK_PERSON | VARCHAR | 配血核对人员 |
| 收费状态 | BLOOD_charge_state | VARCHAR | 收费状态('charged'=已收费) |
| 逻辑删除标识 | isdeleted | VARCHAR | 逻辑删除('0'=有效) |

### 5.3 BIS6_BLOODBAG_INFUSION (输血记录表)
| 业务字段 | 数据库字段 | 字段类型 | 说明 |
|---------|-----------|----------|------|
| 血袋编号 | BLOODBAG_ID | VARCHAR | 血袋编号(关联键) |
| 输血时间 | R_CHECK_TIME | VARCHAR | 输血时间(实际输血核查时间) |
| 患者标识 | PATIENT_ID | VARCHAR | 患者标识 |
| 输血状态 | INFUSION_STATUS | VARCHAR | 输血状态 |
| 逻辑删除标识 | isdeleted | VARCHAR | 逻辑删除('0'=有效) |

### 5.4 BIS6_MATCH_BLOOD_TYPE (血型匹配关系表)
| 业务字段 | 数据库字段 | 字段类型 | 说明 |
|---------|-----------|----------|------|
| 血液类型ID | BLOOD_TYPE_ID | VARCHAR | 血液类型标识(关联键) |
| 血液成分ID | COMPONENT_ID | VARCHAR | 血液成分标识(关联键) |
| 血液项目名称 | BLOOD_NAME | VARCHAR | 血液项目名称 |
| 逻辑删除标识 | isdeleted | VARCHAR | 逻辑删除('0'=有效) |

### 5.5 BIS6_BLOOD_COMPONENT (血液成分字典表)
| 业务字段 | 数据库字段 | 字段类型 | 说明 |
|---------|-----------|----------|------|
| 血液成分编码 | COMPONENT_ID | VARCHAR | 成分编码(主键) |
| 血液成分名称 | COMPONENT_NAME | VARCHAR | 成分名称 |
| 逻辑删除标识 | isdeleted | VARCHAR | 逻辑删除('0'=有效) |

**血液成分编码对照:**
- `'00000009'`: 红细胞悬液 (hxb)
- `'00000010'`: 血小板 (xj)
- `'00000011'`: 新鲜冰冻血浆 (xxb)
- `'00000012'`: 冷沉淀 (lcd)

### 5.6 LIS_INSPECTION_RESULT (检验结果表) ⚠️
**库名**: `hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT` (注意库名修正)

| 业务字段 | 数据库字段 | 字段类型 | 说明 |
|---------|-----------|----------|------|
| 检验单ID | INSPECTION_ID | VARCHAR | 检验单ID/标本标识(关联键) |
| 患者标识 | OUTPATIENT_ID | VARCHAR | 患者标识(门诊/住院号) |
| 检验结果 | QUANTITATIVE_RESULT | VARCHAR | 定量检验结果 |
| 检验项目名称 | CHINESE_NAME | VARCHAR | 配血检验项目名称 |
| 检验项目ID | TEST_ITEM_ID | VARCHAR | 检验项目ID |
| 血型编码 | GROUP_ID | VARCHAR | 血型编码(用于血型一致性检查) |
| 有效标记 | REMARK | VARCHAR | 有效标记 |
| 逻辑删除标识 | isdeleted | VARCHAR | 逻辑删除('0'=有效) |

### 5.7 LIS6_INSPECT_SAMPLE (检验样本表)
| 业务字段 | 数据库字段 | 字段类型 | 说明 |
|---------|-----------|----------|------|
| 检验单ID | INSPECTION_ID | VARCHAR | 检验单ID(关联键) |
| 患者标识 | PATIENT_ID | VARCHAR | 患者标识 |
| 样本信息 | SAMPLE_INFO | VARCHAR | 样本信息 |
| 样本类型 | SAMPLE_TYPE | VARCHAR | 样本类型 |
| 采集时间 | COLLECT_TIME | VARCHAR | 样本采集时间 |
| 接收时间 | RECEIVE_TIME | VARCHAR | 样本接收时间 |
| 逻辑删除标识 | isdeleted | VARCHAR | 逻辑删除('0'=有效) |

## 6. 统计查询特殊说明

### 6.1 Presto适配要求
- **查询引擎**: 基于Presto大数据平台查询
- **字段类型**: 所有字段类型为VARCHAR，数值计算需CAST转换
- **中文字段**: 必须用双引号包围 (如: `"红细胞悬液"`)
- **逻辑删除**: 所有表必须添加 `isdeleted = '0'` 筛选

### 6.2 参数化查询说明
- **院区参数**: `@{C:AREA_ID:A.AREA_ID}` - 需要替换为具体院区编码
- **时间参数**: `@{C:IN_TIME:A.IN_TIME}` 和 `@{C:IN_TIME:A.OUT_DATE}` - 需要替换为具体时间条件
- **实际使用**: 参数占位符需要替换为实际筛选条件或删除

### 6.3 统计逻辑说明  
- **袋数统计**: 使用 `COUNT(DISTINCT bloodbag_id)` 避免重复计数
- **血量统计**: 使用 `SUM(CAST(blood_amount AS DOUBLE))` 进行数值求和
- **分组统计**: 按血型、成分、统计单位、记录类型四个维度交叉统计
- **排序规则**: 使用sort字段('001'-'030')确保结果顺序

### 6.4 业务规则验证
1. **血袋状态一致性**: 确保bloodbag_state值的准确性
2. **血液成分完整性**: 验证四种成分编码覆盖完整
3. **院区数据完整性**: 确保各院区数据的平衡性
4. **关联表数据质量**: 检查JOIN关联的数据完整性

---

## 7. 系统升级血缘变化记录

### 7.1 表结构升级对比
| 原表名 | 新表名 | 变化说明 |
|--------|--------|----------|
| BIS_BLOOD_INPUT | BIS6_BLOODBAG_INPUT | 表名升级，字段名优化 |
| BIS_BLOOD_CROSS_LIST | BIS6_MATCH_BLOOD_TYPE | 配血逻辑改为血型匹配 |
| LIS_INSPECTION_RESULT | LIS6_INSPECT_SAMPLE | 检验结果改为检验样本 |
| BIS_BLOOD_TYPE | BIS6_BLOOD_COMPONENT | 血液类型改为血液成分 |

### 7.2 库名升级对比 ⚠️修正版
| 原库名 | 新库名 | 变化说明 |
|--------|--------|----------|
| hid0101_orcl_lis_bis | hid0101_orcl_lis_bis6 | 版本升级到6.x |
| hid0101_orcl_lis_dbo | hid0101_orcl_lis_dbo | **保持不变** (之前错误认为是xhdata) |
| - | hid0101_orcl_lis_xhdata | LIS6_INSPECT_SAMPLE等检验样本表数据源库 |

---

## 8. 电子病历评级SQL血缘关系专项说明 ⭐️

### 8.1 核心发现和修正
根据电子病历评级SQL文件分析，发现以下重要血缘关系：

#### 8.1.1 新增核心表
- **BIS6_BLOODBAG_MATCH**: 配血匹配记录表，电子病历评级核心业务表
- **BIS6_BLOODBAG_INFUSION**: 输血记录表，时效性分析关键表
- **LIS6_INSPECT_SAMPLE**: 检验样本表，出库关联和样本统计表 (保留原有表结构)

#### 8.1.2 库名修正
- **LIS_INSPECTION_RESULT**: 库名修正为 `hid0101_orcl_lis_dbo` (不是 `hid0101_orcl_lis_xhdata`)

#### 8.1.3 字段名规范化
- 所有字段名采用大写格式 (如 `BLOODBAG_ID`, `ABO_BLOOD_GROUP`)
- 入库时间字段存在变化: `IN_TIME` 和 `IN_DATE` 两种格式

### 8.2 电子病历评级应用场景
1. **完整性评级**: 配血记录的患者标识、检验项目、检验结果、配血时间完整性检查
2. **一致性评级**: 血型编码与配血检验项目的一致性验证
3. **时效性评级**: 入库→出库→输血时间逻辑检查
4. **整合性评级**: 血液库存记录与血液使用记录的对照验证

### 8.3 关键业务规则
- 配血状态排除 `'-1'` 无效状态
- 配血方法排除 `'4'` 无效方法  
- 血液记录状态排除 `'1','2','14','15','16'` 特定状态
- 收费状态 `'charged'` 表示已收费配血

---

## 更新记录
- 创建时间: 2024-12-29
- 血缘分析更新: 2025-01-27  
- **电子病历评级SQL血缘更新**: 2025-01-27 ⭐️
- 版本: v3.0 (基于电子病历评级SQL完整分析)
- 数据源: 输血历史sql-电子病理评级 + 输血统计查询带注释说明.sql
- 更新内容: 
  - 新增BIS6_BLOODBAG_MATCH和BIS6_BLOODBAG_INFUSION表血缘
  - 保留LIS6_INSPECT_SAMPLE表血缘关系(出库关联和样本统计)
  - 修正LIS_INSPECTION_RESULT库名为hid0101_orcl_lis_dbo
  - 完善电子病历评级相关字段血缘关系
  - 规范化所有字段名为大写格式
  - 新增电子病历评级业务规则和筛选条件


## 输血补充
涉及以下内容的信息，提示用户从原始表中查看字段来取合适的字段，完成sql查询。

输血申请信息表 - hid0101_orcl_lis_xhbis.bis6_req_info 查找his申请信息
输血回传申请信息给his的表 - hid0101_orcl_lis_xhbis.bis6_req_blood 查找his 信息
