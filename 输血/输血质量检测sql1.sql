-- Presto数据质量检测SQL - 最终修正版
WITH date_conversion AS (
  -- 字典表检查（预期更新频率低）
  SELECT 
    'hid0101_orcl_lis_xhsystem1.lis_charge_item' as "表名",
    '字典表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhsystem1.lis_charge_item
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.bis6_match_blood_type' as "表名",
    '字典表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.bis6_match_blood_type
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT' as "表名",
    '字典表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.bis6_match_method' as "表名",
    '字典表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.bis6_match_method
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  -- 业务数据表检查（预期更新频率高）
  SELECT 
    'hid0101_orcl_lis_dbo.lis_inspection_sample' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_dbo.lis_inspection_sample
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_dbo.lis_inspection_sample_charge' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_dbo.lis_inspection_sample_charge
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhdata.lis6_inspect_sample' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhdata.lis6_inspect_sample
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.bis6_req_info' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.bis6_req_info
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.bis6_req_blood' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.bis6_req_blood
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.bis6_charged_info' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.bis6_charged_info
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.bis6_bloodbag_match' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.bis6_bloodbag_match
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.BIS6_PAT_SPECIAL_LIST
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhbis.bis6_blood_inventory' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhbis.bis6_blood_inventory
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_bis.his_requisition' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_bis.his_requisition
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_lis_xhinterface.xinghe_charged_list' as "表名",
    '接口表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_lis_xhinterface.xinghe_charged_list
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_operaanesthisa_emrhis.sam_apply' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_operaanesthisa_emrhis.sam_reg' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_reg
  WHERE "isdeleted" = '0'
  
  UNION ALL
  
  SELECT 
    'hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent' as "表名",
    '业务表' as "表类型",
    "lastupdatedttm",
    CASE 
      WHEN "lastupdatedttm" IS NULL THEN current_date
      WHEN length(trim("lastupdatedttm")) < 10 THEN current_date
      ELSE date_parse(substr("lastupdatedttm", 1, 10), '%Y-%m-%d')
    END as "parsed_date"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent
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
    WHEN "表名" LIKE '%lis_xhbis%' THEN 'LIS血库'
    WHEN "表名" LIKE '%lis_dbo%' THEN 'LIS检验'
    WHEN "表名" LIKE '%lis_xhdata%' THEN 'LIS数据'
    WHEN "表名" LIKE '%operaanesthisa%' THEN '手术麻醉'
    WHEN "表名" LIKE '%datacenter%' THEN '数据中心'
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