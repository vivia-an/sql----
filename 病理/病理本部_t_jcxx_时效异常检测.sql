-- 病理本部：t_jcxx 表 lastupdatedttm 与当前时间滞后检测（Presto）
-- 血缘：hid0101_mssql_bl_rep.t_jcxx.lastupdatedttm → MAX 后与 current_timestamp 比较
-- 阈值 x：修改下方 threshold_days 或调度参数替换

WITH threshold AS (
  SELECT 3 AS threshold_days -- x 天，超时判异阈值
),
base AS (
  SELECT
    MAX(try(cast(lastupdatedttm AS timestamp))) AS max_lastupdatedttm,
    current_timestamp AS now_ts,
    date_diff('second', MAX(try(cast(lastupdatedttm AS timestamp))), current_timestamp) AS lag_seconds,
    date_diff('day', MAX(try(cast(lastupdatedttm AS timestamp))), current_timestamp) AS lag_days
  FROM hid0101_mssql_bl_rep.t_jcxx
  WHERE "isdeleted" = '0'
)
SELECT
  '病理' AS "异常系统",
  CASE
    WHEN b.lag_days > t.threshold_days THEN
      '病理本部异常 超时超过 ' || cast(t.threshold_days AS varchar) || ' 天'
    ELSE NULL
  END AS "异常描述",
  b.lag_seconds AS "原因_lag_seconds",
  b.lag_days AS "原因_lag_days",
  b.max_lastupdatedttm,
  b.now_ts,
  t.threshold_days AS "阈值天数x"
FROM base b
CROSS JOIN threshold t;
