-- StarRocks indicators 库：5 个实时指标物化视图 _v_de → _v3
-- 血缘：currentcyxz / currentryxz / currentzyxz / currtime_income / mzssxz_indicators
-- 执行前确认：下游报表/接口已同步改表名引用

USE indicators;

ALTER MATERIALIZED VIEW currentcyxz_v_de RENAME currentcyxz_v3;
ALTER MATERIALIZED VIEW currentryxz_v_de RENAME currentryxz_v3;
ALTER MATERIALIZED VIEW currentzyxz_v_de RENAME currentzyxz_v3;
ALTER MATERIALIZED VIEW currtime_income_v_de RENAME currtime_income_v3;
ALTER MATERIALIZED VIEW mzssxz_indicators_v_de RENAME mzssxz_indicators_v3;

-- 校验
SHOW MATERIALIZED VIEWS FROM indicators
WHERE NAME LIKE '%_v3';

SELECT TABLE_NAME, LAST_REFRESH_STATE, ROWS
FROM information_schema.materialized_views
WHERE TABLE_SCHEMA = 'indicators'
  AND TABLE_NAME IN (
      'currentcyxz_v3',
      'currentryxz_v3',
      'currentzyxz_v3',
      'currtime_income_v3',
      'mzssxz_indicators_v3'
  )
ORDER BY TABLE_NAME;
