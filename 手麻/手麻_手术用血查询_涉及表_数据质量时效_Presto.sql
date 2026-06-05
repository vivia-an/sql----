-- 手麻「手术用血」宽表涉及表 — 数据质量时效检测（Presto/Trino）
-- 血缘：与用户提供的手术用血查询一致，覆盖其 FROM/JOIN 全部基表；指标=全表有效行最大 lastupdatedttm 距今天数（对齐《病理数据质量检测sql_简化版》）
-- 异常血缘：
--   1) lastupdatedttm 缺失或长度<10 → 距今天数=999 → 「❓ 数据异常」（需 information_schema 核对列名或同步字段）
--   2) 字典/国标表（pub_jldw、gb_t_2261_1_2003 等）长期无变更时距今天数可能偏大 → 属「伪告警」，请结合变更频率人工判读
--   3) 仅 isdeleted='0' 口径；若需与业务报表一致可在外层对 sam_apply 等增加 health_service_org_id='HXSSMZK'（见文件末注释块）

WITH date_conversion AS (
  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.sam_apply' AS "表名",
    '手麻业务表' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.sam_reg' AS "表名",
    '手麻业务表' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_reg
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.sam_reg_op' AS "表名",
    '手麻业务表' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_reg_op
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.sam_anar' AS "表名",
    '手麻业务表' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_anar
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent' AS "表名",
    '手麻业务表' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_anar_enent
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec' AS "表名",
    '手麻业务表' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec_nv' AS "表名",
    '手麻业务表' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_emr_rec_nv
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.sam_room' AS "表名",
    '手麻主数据' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.sam_room
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.ipi_registration' AS "表名",
    '患者登记' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.ipi_registration
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.opc_registration' AS "表名",
    '患者登记' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.opc_registration
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.hrm_employee' AS "表名",
    '手麻主数据' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.hrm_employee
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.hra00_department' AS "表名",
    '手麻主数据' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.hra00_department
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.gb_t_2261_1_2003' AS "表名",
    '字典/国标' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.gb_t_2261_1_2003
  WHERE isdeleted = '0'

  UNION ALL

  SELECT
    'hid0101_orcl_operaanesthisa_emrhis.pub_jldw' AS "表名",
    '字典/国标' AS "表类型",
    MAX(lastupdatedttm) AS "最新更新时间",
    CASE
      WHEN MAX(lastupdatedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(lastupdatedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(lastupdatedttm), 1, 10), '%Y-%m-%d'), current_date)
    END AS "距今天数"
  FROM hid0101_orcl_operaanesthisa_emrhis.pub_jldw
  WHERE isdeleted = '0'
)

SELECT
  "表名",
  "表类型",
  "最新更新时间",
  "距今天数",
  CASE
    WHEN "距今天数" = 0 THEN '✅ 正常'
    WHEN "距今天数" = 1 THEN '✅ 正常'
    WHEN "距今天数" <= 3 THEN '⚠️ 注意'
    WHEN "距今天数" <= 7 THEN '⚠️ 告警'
    WHEN "距今天数" > 7 THEN '🚨 严重告警'
    ELSE '❓ 数据异常'
  END AS "质量状态",
  '手麻-手术用血' AS "业务域"
FROM date_conversion
ORDER BY
  CASE
    WHEN "质量状态" = '🚨 严重告警' THEN 1
    WHEN "质量状态" = '⚠️ 告警' THEN 2
    WHEN "质量状态" = '⚠️ 注意' THEN 3
    WHEN "质量状态" = '✅ 正常' THEN 4
    ELSE 5
  END,
  "距今天数" DESC,
  "表类型",
  "表名";

-- 口径说明（与病理简化版一致）：
-- ✅ 正常：0～1 天未更新
-- ⚠️ 注意：2～3 天
-- ⚠️ 告警：4～7 天
-- 🚨 严重告警：>7 天
-- ❓ 数据异常：无可用更新时间（999）
--
-- 列名：默认 lastupdatedttm（varchar）；若环境中为 LASTUPDATEDTTM 或其它，请全局替换。
--
-- 可选：仅监控与报表同机构手术数据新鲜度时，将 sam_apply 一段改为：
--   FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply
--   WHERE isdeleted = '0' AND health_service_org_id = 'HXSSMZK'
