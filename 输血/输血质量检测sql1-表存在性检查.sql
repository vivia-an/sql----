-- Presto数据质量检测SQL - 表存在性检查（安全版本，不会报错）
-- 说明：本SQL仅检查表是否存在及是否有更新字段，不查询实际数据，保证不会因表不存在而报错

WITH 
-- 定义需要检查的表清单
table_config AS (
  SELECT 'hid0101_orcl_lis_xhsystem1' as schema_name, 'lis_charge_item' as table_name, '字典表' as table_type
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_match_blood_type', '字典表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_blood_component', '字典表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_match_method', '字典表'
  
  UNION ALL SELECT 'hid0101_orcl_lis_dbo', 'lis_inspection_sample', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_dbo', 'lis_inspection_sample_charge', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_dbo', 'lis_inspection_result', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhdata', 'lis6_inspect_sample', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_bloodbag_input', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_req_info', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_req_blood', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_charged_info', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_bloodbag_match', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_pat_special_list', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_xhbis', 'bis6_blood_inventory', '业务表'
  UNION ALL SELECT 'hid0101_orcl_lis_bis', 'his_requisition', '业务表'
  
  UNION ALL SELECT 'hid0101_orcl_lis_xhinterface', 'xinghe_charged_list', '接口表'
  
  UNION ALL SELECT 'hid0101_orcl_operaanesthisa_emrhis', 'sam_apply', '业务表'
  UNION ALL SELECT 'hid0101_orcl_operaanesthisa_emrhis', 'sam_reg', '业务表'
  UNION ALL SELECT 'hid0101_orcl_operaanesthisa_emrhis', 'sam_anar_enent', '业务表'
  
  -- 天府院区表
  UNION ALL SELECT 'hid0117_orcl_lis_xhsystem1', 'lis_charge_item', '字典表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_match_blood_type', '字典表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_blood_component', '字典表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_match_method', '字典表'
  
  UNION ALL SELECT 'hid0117_orcl_lis_dbo', 'lis_inspection_sample', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_dbo', 'lis_inspection_sample_charge', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_dbo', 'lis_inspection_result', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhdata', 'lis6_inspect_sample', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_bloodbag_input', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_req_info', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_req_blood', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_charged_info', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_bloodbag_match', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_pat_special_list', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_xhbis', 'bis6_blood_inventory', '业务表'
  UNION ALL SELECT 'hid0117_orcl_lis_bis', 'his_requisition', '业务表'
  
  UNION ALL SELECT 'hid0117_orcl_lis_xhinterface', 'xinghe_charged_list', '接口表'
),

-- 从系统表获取实际存在的表
existing_tables AS (
  SELECT 
    lower(table_schema) as schema_name,
    lower(table_name) as table_name,
    table_schema || '.' || table_name as full_table_name
  FROM information_schema.tables
  WHERE lower(table_schema) IN (
    'hid0101_orcl_lis_xhsystem1', 'hid0101_orcl_lis_xhbis', 'hid0101_orcl_lis_dbo', 
    'hid0101_orcl_lis_xhdata', 'hid0101_orcl_lis_bis', 'hid0101_orcl_lis_xhinterface',
    'hid0101_orcl_operaanesthisa_emrhis',
    'hid0117_orcl_lis_xhsystem1', 'hid0117_orcl_lis_xhbis', 'hid0117_orcl_lis_dbo',
    'hid0117_orcl_lis_xhdata', 'hid0117_orcl_lis_bis', 'hid0117_orcl_lis_xhinterface'
  )
),

-- 检查表中是否存在lastupdatedttm字段
table_columns AS (
  SELECT 
    lower(table_schema) as schema_name,
    lower(table_name) as table_name,
    lower(column_name) as column_name
  FROM information_schema.columns
  WHERE lower(column_name) = 'lastupdatedttm'
    AND lower(table_schema) IN (
      'hid0101_orcl_lis_xhsystem1', 'hid0101_orcl_lis_xhbis', 'hid0101_orcl_lis_dbo', 
      'hid0101_orcl_lis_xhdata', 'hid0101_orcl_lis_bis', 'hid0101_orcl_lis_xhinterface',
      'hid0101_orcl_operaanesthisa_emrhis',
      'hid0117_orcl_lis_xhsystem1', 'hid0117_orcl_lis_xhbis', 'hid0117_orcl_lis_dbo',
      'hid0117_orcl_lis_xhdata', 'hid0117_orcl_lis_bis', 'hid0117_orcl_lis_xhinterface'
    )
),

-- 合并配置、存在性和字段信息
table_status AS (
  SELECT 
    tc.schema_name,
    tc.table_name,
    tc.schema_name || '.' || tc.table_name as full_table_name,
    tc.table_type,
    CASE 
      WHEN et.schema_name IS NULL THEN false
      ELSE true
    END as table_exists,
    CASE 
      WHEN col.schema_name IS NULL THEN false
      ELSE true
    END as has_lastupdatedttm
  FROM table_config tc
  LEFT JOIN existing_tables et
    ON lower(tc.schema_name) = et.schema_name 
    AND lower(tc.table_name) = et.table_name
  LEFT JOIN table_columns col
    ON lower(tc.schema_name) = col.schema_name 
    AND lower(tc.table_name) = col.table_name
)

-- 最终输出
SELECT 
  full_table_name as "表名",
  table_type as "表类型",
  CASE 
    WHEN NOT table_exists THEN '❌ 表不存在'
    WHEN NOT has_lastupdatedttm THEN '⚠️ 表存在但无更新时间字段'
    ELSE '✅ 表存在且有更新时间字段'
  END as "表状态",
  CASE 
    WHEN NOT table_exists THEN '无法检测'
    WHEN NOT has_lastupdatedttm THEN '需要手动检查'
    ELSE '可自动监控'
  END as "监控能力",
  CASE 
    WHEN full_table_name LIKE '%lis_xhbis%' THEN 'LIS血库'
    WHEN full_table_name LIKE '%lis_dbo%' THEN 'LIS检验'
    WHEN full_table_name LIKE '%lis_xhdata%' THEN 'LIS数据'
    WHEN full_table_name LIKE '%lis_xhsystem%' THEN 'LIS系统'
    WHEN full_table_name LIKE '%lis_xhinterface%' THEN 'LIS接口'
    WHEN full_table_name LIKE '%lis_bis%' THEN 'LIS业务'
    WHEN full_table_name LIKE '%operaanesthisa%' THEN '手术麻醉'
    WHEN full_table_name LIKE '%datacenter%' THEN '数据中心'
    ELSE '其他'
  END as "业务域",
  CASE 
    WHEN full_table_name LIKE 'hid0117_%' THEN '天府院区'
    WHEN full_table_name LIKE 'hid0101_%' THEN '本部院区'
    ELSE '未知院区'
  END as "院区",
  '先运行此查询确认表存在，然后使用输血质量检测sql1.sql查询详细数据' as "使用说明"
FROM table_status
ORDER BY 
  CASE 
    WHEN NOT table_exists THEN 0  -- 不存在的表最优先显示
    WHEN NOT has_lastupdatedttm THEN 1  -- 无更新字段的表其次
    ELSE 2
  END,
  CASE 
    WHEN full_table_name LIKE 'hid0101_%' THEN 1  -- 本部院区优先
    WHEN full_table_name LIKE 'hid0117_%' THEN 2  -- 天府院区其次
    ELSE 3
  END,
  "业务域",
  full_table_name


