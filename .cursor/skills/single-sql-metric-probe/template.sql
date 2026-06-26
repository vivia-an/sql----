-- {指标名} — 单条 SQL 量探测（Presto）
-- 窗口A：{起点} ~ {终点} | 窗口B：{可选第二窗口}
-- 主表：{schema}.{table} | 主键：{id_field} | 时间：{time_field}

SELECT
    "时间窗口",
    "口径",
    "数据源",
    "行数",
    "distinct_计数"
FROM (
    SELECT
        'A_{窗口标签}' AS "时间窗口",
        '01_全表无过滤' AS "口径",
        '{主表}' AS "数据源",
        count(*) AS "行数",
        count(DISTINCT t."{主键}") AS "distinct_计数"
    FROM {schema}."{主表}" t

    UNION ALL
    SELECT 'A_{窗口标签}', '02_仅时间落窗', '{主表}',
        count(*), count(DISTINCT t."{主键}")
    FROM {schema}."{主表}" t
    WHERE t."{时间字段}" >= '{起点}'
      AND t."{时间字段}" < '{终点}'

    UNION ALL
    SELECT 'A_{窗口标签}', '04_{院区}+时间落窗', '{主表}',
        count(*), count(DISTINCT t."{主键}")
    FROM {schema}."{主表}" t
    WHERE t."{院区字段}" = 'HID0101'
      AND t."{时间字段}" >= '{起点}'
      AND t."{时间字段}" < '{终点}'

    UNION ALL
    SELECT 'A_{窗口标签}', '05_{院区}+IsDeleted+时间', '{主表}',
        count(*), count(DISTINCT t."{主键}")
    FROM {schema}."{主表}" t
    WHERE t."{院区字段}" = 'HID0101'
      AND coalesce(cast(t."{删除字段}" AS varchar), '0') = '0'
      AND t."{时间字段}" >= '{起点}'
      AND t."{时间字段}" < '{终点}'

    UNION ALL
    SELECT 'A_{窗口标签}', '06_主SQL分母完整条件', '{主表}',
        count(*), count(DISTINCT t."{主键}")
    FROM {schema}."{主表}" t
    -- 粘贴主指标分母 WHERE/JOIN，与主 SQL 完全一致

    UNION ALL
    SELECT 'A_{窗口标签}', '12_对照表同窗口', '{对照表}',
        count(*), count(DISTINCT c."{对照主键}")
    FROM {schema}."{对照表}" c
    WHERE c."{院区字段}" = 'HID0101'
      AND coalesce(cast(c."{删除字段}" AS varchar), '0') = '0'
      AND c."{对照时间}" >= '{起点}'
      AND c."{对照时间}" < '{终点}'
) x
ORDER BY "时间窗口", "口径";
