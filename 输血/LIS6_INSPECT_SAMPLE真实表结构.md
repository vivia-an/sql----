# LIS6_INSPECT_SAMPLE 真实表结构

## 表基本信息
- **表名**: LIS6_INSPECT_SAMPLE
- **中文名称**: 检验样本表
- **数据源**: LIS系统
- **库名**: hid0101_orcl_lis_xhdata

## 字段结构详情

| 序号 | 字段名 | 数据类型 | 是否为空 | 中文注释 | 说明 |
|------|--------|----------|----------|----------|------|
| 1 | SAMPLING_TIME | DATE | 是 | 采集时间 | 样本采集时间 |
| 2 | INCEPT_TIME | DATE | 是 | 接收时间 | 样本接收时间 |
| 3 | PREREPORT_TIME | DATE | 是 | 预报告时间 | 预报告时间 |
| 4 | INPUT_TIME | DATE | 是 | 编号时间 | 样本编号时间 |
| 5 | MACHINE_TIME | DATE | 是 | 上机时间 | 样本上机时间 |
| 6 | PREFINISH_TIME | DATE | 是 | 结果预完成时间 | 结果预完成时间 |
| 7 | FINISH_RESULT_TIME | DATE | 是 | 结果完成时间 | 结果完成时间 |
| 8 | AI_CHECK_TIME | DATE | 是 | 智能审核时间 | 智能审核时间 |
| 9 | RERUN_TIME | DATE | 是 | 复查时间 | 样本复查时间 |
| 10 | PRE_REPORT_TIME | DATE | 是 | 初步报告时间 | 初步报告时间 |
| 11 | TADUIT_TIME | DATE | 是 | 检验审核时间 | 检验审核时间 |
| 12 | CHECK_TIME | DATE | 是 | 审核时间 | 最终审核时间 |
| 13 | SAMPLING_PERSON | VARCHAR2 | 是 | 采集人员 | 样本采集人员 |
| 14 | INCEPT_PERSON | VARCHAR2 | 是 | 接收人员 | 样本接收人员 |
| 15 | INSPECTION_PERSON | VARCHAR2 | 是 | 检验人员 | 检验操作人员 |
| 16 | RERUN_PERSON | VARCHAR2 | 是 | 复查人员 | 复查操作人员 |
| 17 | PRE_REPORT_PERSON | VARCHAR2 | 是 | 初步报告人员 | 初步报告人员 |
| 18 | TADUIT_PERSON | VARCHAR2 | 是 | 检验审核人员 | 检验审核人员 |
| 19 | CHECK_PERSON | VARCHAR2 | 是 | 审核人员 | 最终审核人员 |
| 20 | CHECK_PERSON_ID | VARCHAR2 | 是 | 审核人员ID | 审核人员标识 |

## 重要发现

### 1. 时间字段类型
- **所有时间字段都是DATE类型**，不是VARCHAR类型
- 这与之前假设的"日期都是string类型"不符
- 在Presto查询中需要正确处理DATE类型字段

### 2. 时间字段分类
- **采集相关**: SAMPLING_TIME (采集时间)
- **接收相关**: INCEPT_TIME (接收时间)  
- **检验流程**: MACHINE_TIME (上机时间), PREFINISH_TIME (预完成), FINISH_RESULT_TIME (完成时间)
- **审核流程**: AI_CHECK_TIME (智能审核), TADUIT_TIME (检验审核), CHECK_TIME (最终审核)
- **报告流程**: PREREPORT_TIME (预报告), PRE_REPORT_TIME (初步报告)

### 3. 人员字段分类
- **操作人员**: SAMPLING_PERSON, INCEPT_PERSON, INSPECTION_PERSON, RERUN_PERSON
- **审核人员**: PRE_REPORT_PERSON, TADUIT_PERSON, CHECK_PERSON, CHECK_PERSON_ID

## Presto查询适配建议

### 1. DATE类型处理
```sql
-- 正确的DATE类型处理
CAST(ls.SAMPLING_TIME AS VARCHAR) AS "采集时间",
CAST(ls.INCEPT_TIME AS VARCHAR) AS "接收时间",
CAST(ls.CHECK_TIME AS VARCHAR) AS "审核时间"
```

### 2. 时间比较
```sql
-- DATE类型的时间比较
WHERE ls.SAMPLING_TIME >= DATE '2024-01-01'
  AND ls.CHECK_TIME <= DATE '2024-12-31'
```

### 3. 时间格式化
```sql
-- 如果需要特定格式
date_format(ls.SAMPLING_TIME, '%Y-%m-%d %H:%i:%s') AS "采集时间格式化"
```

## 与现有SQL的差异

### 当前SQL中的问题
```sql
-- 当前SQL（错误）
TRY_CAST(ls.COLLECT_TIME AS timestamp) AS BTS_Blood_Detail_SampleCollectDtTm,
TRY_CAST(ls.RECEIVE_TIME AS timestamp) AS BTS_Blood_Detail_SampleReceiveDtTm,
```

### 修正后的SQL
```sql
-- 修正后（正确）
CAST(ls.SAMPLING_TIME AS VARCHAR) AS BTS_Blood_Detail_SampleCollectDtTm,
CAST(ls.INCEPT_TIME AS VARCHAR) AS BTS_Blood_Detail_SampleReceiveDtTm,
```

## 字段映射关系

| 业务字段 | 数据库字段 | 数据类型 | 说明 |
|----------|------------|----------|------|
| 样本采集时间 | SAMPLING_TIME | DATE | 样本采集时间 |
| 样本接收时间 | INCEPT_TIME | DATE | 样本接收时间 |
| 样本审核时间 | CHECK_TIME | DATE | 最终审核时间 |
| 采集人员 | SAMPLING_PERSON | VARCHAR2 | 样本采集人员 |
| 接收人员 | INCEPT_PERSON | VARCHAR2 | 样本接收人员 |
| 审核人员 | CHECK_PERSON | VARCHAR2 | 最终审核人员 |

## 注意事项

1. **字段名差异**: 实际表结构中没有`COLLECT_TIME`和`RECEIVE_TIME`字段，应该使用`SAMPLING_TIME`和`INCEPT_TIME`
2. **数据类型**: 时间字段是DATE类型，不是VARCHAR类型
3. **Presto适配**: 需要正确处理DATE类型的转换和比较
4. **字段完整性**: 表中有20个字段，包含完整的时间流程和人员信息 