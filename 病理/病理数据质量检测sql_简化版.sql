-- 病理数据质量检测SQL - 简化版
-- 仅根据距离最新更新时间到当前日期的天数进行质量判定

WITH date_conversion AS (
  -- 病理核心业务表检查
  SELECT
    'hid0101_mssql_bl_rep.t_jcxx' as "表名",
    '病理业务表' as "表类型",
    MAX(f_sdrq) as "最新更新时间",
    CASE
      WHEN MAX(f_sdrq) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(f_sdrq))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(f_sdrq), 1, 10), '%Y-%m-%d'), current_date)
    END as "距今天数"
  FROM hid0101_mssql_bl_rep.t_jcxx
  WHERE "isdeleted" = '0'

  UNION ALL

  -- 病理收入数据表检查
  SELECT
    'm1.mdr_income' as "表名",
    '收入数据表' as "表类型",
    MAX(chargedttm) as "最新更新时间",
    CASE
      WHEN MAX(chargedttm) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(chargedttm))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(chargedttm), 1, 10), '%Y-%m-%d'), current_date)
    END as "距今天数"
  FROM m1.mdr_income
  WHERE IsDeleted = '0'
    AND RecDeptName IN ('病理科','锦江病理科','温江病理科','天府病理科','病理科(上锦)','病理科(天府)')

  UNION ALL

  -- 体检病理收入表检查
  SELECT
    'm1.mdr_peisincome' as "表名",
    '体检收入表' as "表类型",
    MAX(dateregister) as "最新更新时间",
    CASE
      WHEN MAX(dateregister) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(dateregister))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(dateregister), 1, 10), '%Y-%m-%d'), current_date)
    END as "距今天数"
  FROM m1.mdr_peisincome
  WHERE ((f_feecharged = 'AQ==') OR f_feecharged = 'true')
    AND examfeeitem_name IN (
      '宫颈刮片病理细胞学检查','宫颈刮片病理细胞学检查【HPV】','液基薄层细胞学检查',
      '液基薄层细胞学检查【加HPV】','尿液基细胞学检测','液基薄层细胞制片术',
      '肠癌无创脱落细胞多靶点基因检测','液基薄层细胞学检查【加HPV，加白带常规】',
      '两癌筛查【HPV+白带】','两癌筛查液基薄层细胞制片术','两癌筛查组织病理学检查',
      '两癌筛查妇科','两癌筛查妇科【HPV+白带】','两癌筛查妇科【液基】',
      '两癌筛查组织病理学检查【需取组织检查才用条码】','液基薄层细胞学检查【加白带常规】',
      '体检液基薄层细胞制片术','液基薄层细胞制片术','液基薄层细胞学检查（HPV）（体检）'
    )

  UNION ALL

  -- 病理科材料领用表检查
  SELECT
    'datacenter_db.inventory_del_dets' as "表名",
    '物资领用表' as "表类型",
    MAX(del_date) as "最新更新时间",
    CASE
      WHEN MAX(del_date) IS NULL THEN 999
      WHEN LENGTH(TRIM(MAX(del_date))) < 10 THEN 999
      ELSE date_diff('day', date_parse(substr(MAX(del_date), 1, 10), '%Y-%m-%d'), current_date)
    END as "距今天数"
  FROM datacenter_db.inventory_del_dets
  WHERE "hosp_code" = 'HID0101'
    AND "dept_name" LIKE '%病理科%'
    AND "isdeleted" = '0'
)

-- 主查询：仅基于天数的病理数据质量报告
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
  END as "质量状态",
  CASE
    WHEN "表名" LIKE '%t_jcxx%' THEN '病理检查'
    WHEN "表名" LIKE '%mdr_income%' THEN '病理收入'
    WHEN "表名" LIKE '%mdr_peisincome%' THEN '体检病理'
    WHEN "表名" LIKE '%inventory%' THEN '物资管理'
    ELSE '其他'
  END as "业务域"

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
  "业务域",
  "表名"

-- 简化版数据质量检测说明：
--
-- 质量判定标准（仅基于距今天数）：
-- ✅ 正常：0-1天未更新
-- ⚠️ 注意：2-3天未更新
-- ⚠️ 告警：4-7天未更新
-- 🚨 严重告警：超过7天未更新
-- ❓ 数据异常：无法解析更新时间
--
-- 监控表：
-- 1. hid0101_mssql_bl_rep.t_jcxx - 病理检查信息表
-- 2. m1.mdr_income - 病理收入数据表
-- 3. m1.mdr_peisincome - 体检病理收入表
-- 4. datacenter_db.inventory_del_dets - 病理科物资领用表
--
-- 业务域分类：
-- - 病理检查：核心病理业务数据
-- - 病理收入：病理相关收入数据
-- - 体检病理：体检相关病理数据
-- - 物资管理：病理科物资领用数据
--
-- 使用说明：
-- 1. 定期执行监控各表数据更新时效
-- 2. 重点关注严重告警（>7天）的表
-- 3. 所有表统一按天数标准判定质量状态