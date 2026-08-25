-- StarRocks indicators 库：_v3 上线为生产名，旧生产名归档为 _v4
-- 血缘：currentcyxz / currentryxz / currentzyxz / currtime_income / mzssxz_indicators
--
-- 执行前提（缺一不可）：
--   1) 存在无后缀生产名：currentcyxz、currentryxz、currentzyxz、currtime_income、mzssxz_indicators
--   2) 存在待上线 _v3：currentcyxz_v3 … mzssxz_indicators_v3
--   3) 不存在 _v4 同名物化视图（否则会 RENAME 冲突）
--   4) 下游报表/接口查的是无后缀名（本脚本不改下游）
--
-- 原理：两步腾名 —— 先把旧生产挪到 _v4 占位，再把 _v3 升为无后缀生产名
-- 与历史 v1→_v_de、_v_de→_v3 同属 ALTER RENAME 换版，非重建

USE indicators;

-- ========== 第一步：旧生产 → _v4 归档（必须先执行）==========
ALTER MATERIALIZED VIEW currentcyxz RENAME currentcyxz_v4;
ALTER MATERIALIZED VIEW currentryxz RENAME currentryxz_v4;
ALTER MATERIALIZED VIEW currentzyxz RENAME currentzyxz_v4;
ALTER MATERIALIZED VIEW currtime_income RENAME currtime_income_v4;
ALTER MATERIALIZED VIEW mzssxz_indicators RENAME mzssxz_indicators_v4;

-- ========== 第二步：_v3 → 无后缀生产名（第一步全部成功后再执行）==========
ALTER MATERIALIZED VIEW currentcyxz_v3 RENAME currentcyxz;
ALTER MATERIALIZED VIEW currentryxz_v3 RENAME currentryxz;
ALTER MATERIALIZED VIEW currentzyxz_v3 RENAME currentzyxz;
ALTER MATERIALIZED VIEW currtime_income_v3 RENAME currtime_income;
ALTER MATERIALIZED VIEW mzssxz_indicators_v3 RENAME mzssxz_indicators;

-- ========== 校验 ==========
SHOW MATERIALIZED VIEWS FROM indicators
WHERE NAME IN (
    'currentcyxz', 'currentryxz', 'currentzyxz', 'currtime_income', 'mzssxz_indicators',
    'currentcyxz_v4', 'currentryxz_v4', 'currentzyxz_v4', 'currtime_income_v4', 'mzssxz_indicators_v4'
)
ORDER BY NAME;

SELECT TABLE_NAME, LAST_REFRESH_STATE, ROWS
FROM information_schema.materialized_views
WHERE TABLE_SCHEMA = 'indicators'
  AND TABLE_NAME IN (
      'currentcyxz', 'currentryxz', 'currentzyxz', 'currtime_income', 'mzssxz_indicators',
      'currentcyxz_v4', 'currentryxz_v4', 'currentzyxz_v4', 'currtime_income_v4', 'mzssxz_indicators_v4'
  )
ORDER BY TABLE_NAME;

-- 确认 _v3 已不存在（应全部升为无后缀）
SHOW MATERIALIZED VIEWS FROM indicators WHERE NAME LIKE '%_v3';
