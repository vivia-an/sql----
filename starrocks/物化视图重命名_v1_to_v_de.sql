-- StarRocks indicators 库：5 个实时指标物化视图 _v1 → _v_de
-- 血缘：currentcyxz / currentryxz / currentzyxz / currtime_income / mzssxz_indicators
-- 执行前确认：下游报表/接口已同步改表名引用

USE indicators;

ALTER MATERIALIZED VIEW currentcyxz_v1 RENAME currentcyxz_v_de;
ALTER MATERIALIZED VIEW currentryxz_v1 RENAME currentryxz_v_de;
ALTER MATERIALIZED VIEW currentzyxz_v1 RENAME currentzyxz_v_de;
ALTER MATERIALIZED VIEW currtime_income_v1 RENAME currtime_income_v_de;
ALTER MATERIALIZED VIEW mzssxz_indicators_v1 RENAME mzssxz_indicators_v_de;

-- 校验
SHOW MATERIALIZED VIEWS FROM indicators
WHERE NAME LIKE '%_v_de';

SELECT TABLE_NAME, LAST_REFRESH_STATE, ROWS
FROM information_schema.materialized_views
WHERE TABLE_SCHEMA = 'indicators'
  AND TABLE_NAME IN (
      'currentcyxz_v_de',
      'currentryxz_v_de',
      'currentzyxz_v_de',
      'currtime_income_v_de',
      'mzssxz_indicators_v_de'
  )
ORDER BY TABLE_NAME;
