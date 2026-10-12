-- 手排：昨日择期手术量 + 口径阶梯（一条 SQL）
-- 主表：hid0101_cache_his_dhcapp_userssgl.OPMSApply
-- 择期：OPMSDictionaryManage.SubDicName = '择期'（a.OpType = opms_rowid）
-- 日期：OPDate varchar 昨日（current_date-1）
-- 状态：用户 SQL  prostatus E/H/J/SZ，或 C 且 OpType in (616,562)
-- 主键：OPMS_RowId；量用 distinct_计数
--
-- 对照：手排/手术申请主题-Plan_OPSSchedule.sql 状态是 H/J/K/I/L，与用户 SQL 不同 → 05
-- 日间/介入在字典里是独立类型，不算择期 → 06/07，确认后才能并入口径
-- 616/562 字典名未知 → 00 段带出 SubDicName
-- 申请科室：用户 a.ctlocid，仓库 ApplyDptID，量不 JOIN 科室
-- 用户 room01 与 room 重复 LEFT JOIN，已去掉（不改变行数）
-- 手麻 is_emergency 与手排 OpType 不是同一口径，勿混报

SELECT
    "时间窗口",
    "口径",
    "数据源",
    "行数",
    "distinct_计数"
FROM (
    SELECT
        concat('昨日_', p.dt_yes) AS "时间窗口",
        '00_字典616与562的SubDicName' AS "口径",
        'OPMSDictionaryManage' AS "数据源",
        count(*) AS "行数",
        count(DISTINCT d.opms_rowid) AS "distinct_计数"
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage d
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(d.isdeleted AS varchar), '0') = '0'
      AND cast(d.opms_rowid AS varchar) IN ('616', '562')

    UNION ALL

    SELECT
        concat('昨日_', p.dt_yes),
        concat('00b_616_562名称=', coalesce(max(cast(d.SubDicName AS varchar)), '空')),
        'OPMSDictionaryManage',
        count(*),
        count(DISTINCT d.opms_rowid)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage d
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(d.isdeleted AS varchar), '0') = '0'
      AND cast(d.opms_rowid AS varchar) IN ('616', '562')

    UNION ALL

    SELECT
        concat('昨日_', p.dt_yes),
        '01_昨日未删',
        'OPMSApply',
        count(*),
        count(DISTINCT a.OPMS_RowId)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes

    UNION ALL

    SELECT
        concat('昨日_', p.dt_yes),
        '02_昨日未删+非测试',
        'OPMSApply',
        count(*),
        count(DISTINCT a.OPMS_RowId)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes
      AND a.patName NOT LIKE '%测试%'

    UNION ALL

    SELECT
        concat('昨日_', p.dt_yes),
        '03_昨日+用户状态(E/H/J/SZ或C+616/562)',
        'OPMSApply',
        count(*),
        count(DISTINCT a.OPMS_RowId)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes
      AND a.patName NOT LIKE '%测试%'
      AND (
            upper(trim(cast(a.prostatus AS varchar))) IN ('E', 'H', 'J', 'SZ')
         OR (
              upper(trim(cast(a.prostatus AS varchar))) IN ('C', 'E', 'H', 'J', 'SZ')
              AND cast(a.OpType AS varchar) IN ('616', '562')
            )
          )

    UNION ALL

    -- 06 主口径 = 昨日择期手术量
    SELECT
        concat('昨日_', p.dt_yes),
        '06_主口径_昨日择期量(用户状态+SubDicName=择期)',
        'OPMSApply+OPMSDictionaryManage',
        count(*),
        count(DISTINCT a.OPMS_RowId)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opstype
        ON cast(a.OpType AS varchar) = cast(opstype.opms_rowid AS varchar)
       AND coalesce(cast(opstype.isdeleted AS varchar), '0') = '0'
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes
      AND a.patName NOT LIKE '%测试%'
      AND (
            upper(trim(cast(a.prostatus AS varchar))) IN ('E', 'H', 'J', 'SZ')
         OR (
              upper(trim(cast(a.prostatus AS varchar))) IN ('C', 'E', 'H', 'J', 'SZ')
              AND cast(a.OpType AS varchar) IN ('616', '562')
            )
          )
      AND trim(cast(opstype.SubDicName AS varchar)) = '择期'

    UNION ALL

    SELECT
        concat('昨日_', p.dt_yes),
        '05_对照_仓库状态H/J/K/I/L+择期',
        'OPMSApply+OPMSDictionaryManage',
        count(*),
        count(DISTINCT a.OPMS_RowId)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opstype
        ON cast(a.OpType AS varchar) = cast(opstype.opms_rowid AS varchar)
       AND coalesce(cast(opstype.isdeleted AS varchar), '0') = '0'
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes
      AND a.patName NOT LIKE '%测试%'
      AND upper(trim(cast(a.prostatus AS varchar))) IN ('H', 'J', 'K', 'I', 'L')
      AND trim(cast(opstype.SubDicName AS varchar)) = '择期'

    UNION ALL

    SELECT
        concat('昨日_', p.dt_yes),
        '07_昨日用户状态+日间(病房日间/中心日间)',
        'OPMSApply+OPMSDictionaryManage',
        count(*),
        count(DISTINCT a.OPMS_RowId)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opstype
        ON cast(a.OpType AS varchar) = cast(opstype.opms_rowid AS varchar)
       AND coalesce(cast(opstype.isdeleted AS varchar), '0') = '0'
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes
      AND a.patName NOT LIKE '%测试%'
      AND (
            upper(trim(cast(a.prostatus AS varchar))) IN ('E', 'H', 'J', 'SZ')
         OR (
              upper(trim(cast(a.prostatus AS varchar))) IN ('C', 'E', 'H', 'J', 'SZ')
              AND cast(a.OpType AS varchar) IN ('616', '562')
            )
          )
      AND trim(cast(opstype.SubDicName AS varchar)) IN ('病房日间', '中心日间')

    UNION ALL

    SELECT
        concat('昨日_', p.dt_yes),
        '08_昨日用户状态+介入(外周/心脏/超声)',
        'OPMSApply+OPMSDictionaryManage',
        count(*),
        count(DISTINCT a.OPMS_RowId)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opstype
        ON cast(a.OpType AS varchar) = cast(opstype.opms_rowid AS varchar)
       AND coalesce(cast(opstype.isdeleted AS varchar), '0') = '0'
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes
      AND a.patName NOT LIKE '%测试%'
      AND (
            upper(trim(cast(a.prostatus AS varchar))) IN ('E', 'H', 'J', 'SZ')
         OR (
              upper(trim(cast(a.prostatus AS varchar))) IN ('C', 'E', 'H', 'J', 'SZ')
              AND cast(a.OpType AS varchar) IN ('616', '562')
            )
          )
      AND trim(cast(opstype.SubDicName AS varchar)) IN ('外周介入', '心脏介入', '超声介入')

    UNION ALL

    SELECT
        concat('昨日_', p.dt_yes),
        concat('12_昨日用户状态_类型=', coalesce(nullif(trim(cast(opstype.SubDicName AS varchar)), ''), '空')),
        'OPMSApply+OPMSDictionaryManage',
        count(*),
        count(DISTINCT a.OPMS_RowId)
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opstype
        ON cast(a.OpType AS varchar) = cast(opstype.opms_rowid AS varchar)
       AND coalesce(cast(opstype.isdeleted AS varchar), '0') = '0'
    CROSS JOIN (
        SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
    ) p
    WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
      AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes
      AND a.patName NOT LIKE '%测试%'
      AND (
            upper(trim(cast(a.prostatus AS varchar))) IN ('E', 'H', 'J', 'SZ')
         OR (
              upper(trim(cast(a.prostatus AS varchar))) IN ('C', 'E', 'H', 'J', 'SZ')
              AND cast(a.OpType AS varchar) IN ('616', '562')
            )
          )
    GROUP BY p.dt_yes, trim(cast(opstype.SubDicName AS varchar))
) t
ORDER BY "时间窗口", "口径";

-- ========== 只要量：把上面 06 单独跑 ==========
-- WITH p AS (
--   SELECT date_format(date_add('day', -1, current_date), '%Y-%m-%d') AS dt_yes
-- )
-- SELECT
--   p.dt_yes AS "统计日",
--   count(DISTINCT a.OPMS_RowId) AS "昨日择期手术量"
-- FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
-- LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage opstype
--   ON cast(a.OpType AS varchar) = cast(opstype.opms_rowid AS varchar)
--  AND coalesce(cast(opstype.isdeleted AS varchar), '0') = '0'
-- CROSS JOIN p
-- WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
--   AND a.patName NOT LIKE '%测试%'
--   AND substr(cast(a.OPDate AS varchar), 1, 10) = p.dt_yes
--   AND (
--         upper(trim(cast(a.prostatus AS varchar))) IN ('E', 'H', 'J', 'SZ')
--      OR (
--           upper(trim(cast(a.prostatus AS varchar))) IN ('C', 'E', 'H', 'J', 'SZ')
--           AND cast(a.OpType AS varchar) IN ('616', '562')
--         )
--       )
--   AND trim(cast(opstype.SubDicName AS varchar)) = '择期'
-- GROUP BY p.dt_yes;
