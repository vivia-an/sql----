-- Presto LIS数据质量检测SQL
WITH date_conversion AS (
  -- 业务数据表检查（预期更新频率高）
  SELECT 
    'hid0117_orcl_lis_dbo.lis_inspection_sample' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0117_orcl_lis_dbo.lis_inspection_sample
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0117_orcl_lis_dbo.lis_inspection_sample_charge' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0117_orcl_lis_dbo.lis_inspection_sample_charge
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0117_orcl_lis_dbo.lis_requisition_item' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0117_orcl_lis_dbo.lis_requisition_item
  WHERE "isdeleted" = '0'
),

table_quality_check AS (
  SELECT 
    "表名",
    "表类型",
    MAX("lastupdatedttm") as "最新更新时间",
    date_diff('day', MAX("parsed_date"), current_date) as "距今天数"
  FROM date_conversion
  GROUP BY "表名", "表类型"
)

SELECT 
  "表名",
  "表类型",
  "最新更新时间",
  "距今天数",
  CASE 
    WHEN "表类型" = '字典表' AND "距今天数" > 90 THEN '⚠️ 告警'
    WHEN "表类型" = '接口表' AND "距今天数" > 7 THEN '⚠️ 告警'
    WHEN "表类型" = '业务表' AND "距今天数" > 1 THEN '🚨 严重告警'
    WHEN "距今天数" = 0 THEN '✅ 正常'
    WHEN "距今天数" = 1 AND "表类型" != '业务表' THEN '✅ 正常'
    ELSE '⚠️ 注意'
  END as "质量状态",
  CASE 
    WHEN "表名" LIKE '%lis_dbo%' THEN 'LIS检验'
    ELSE '其他'
  END as "业务域"
FROM table_quality_check
ORDER BY 
  CASE 
    WHEN "质量状态" = '🚨 严重告警' THEN 1
    WHEN "质量状态" = '⚠️ 告警' THEN 2
    WHEN "质量状态" = '⚠️ 注意' THEN 3
    ELSE 4
  END,
  "距今天数" DESC, 
  "业务域", 
  "表名"












