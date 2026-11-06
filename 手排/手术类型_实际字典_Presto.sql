-- 手排手术类型原文（Presto）
-- 血缘：OPMSApply.OpType = OPMSDictionaryManage.opms_rowid，名称取 SubDicName
-- 近 7 天每一种类型一行，看实际库里有哪些名字

WITH p_range AS (
    SELECT
        date_format(date_add('day', -7, current_date), '%Y-%m-%d') AS dt_start,
        date_format(date_add('day', 1, current_date), '%Y-%m-%d') AS dt_end
)

SELECT
    coalesce(nullif(trim(cast(d.SubDicName AS varchar)), ''), '空') AS "手术类型",
    cast(a.OpType AS varchar) AS "类型编码",
    count(DISTINCT a.OPMS_RowId) AS "单量"
FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSDictionaryManage d
    ON cast(a.OpType AS varchar) = cast(d.opms_rowid AS varchar)
   AND coalesce(cast(d.isdeleted AS varchar), '0') = '0'
WHERE coalesce(cast(a.isdeleted AS varchar), '0') = '0'
  AND substr(cast(a.opdate AS varchar), 1, 10) >= (SELECT dt_start FROM p_range)
  AND substr(cast(a.opdate AS varchar), 1, 10) <  (SELECT dt_end FROM p_range)
GROUP BY
    coalesce(nullif(trim(cast(d.SubDicName AS varchar)), ''), '空'),
    cast(a.OpType AS varchar)
ORDER BY
    "单量" DESC,
    "手术类型";
