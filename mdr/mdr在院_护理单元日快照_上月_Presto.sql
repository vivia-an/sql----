-- 在院人数日快照（按 REPHOUR 取一天中最大小时行）— Presto 可执行版
-- 原报错：?[_LAST_YEAR_MONTH_] 为报表占位符，Presto/JDBC 将 ? 视为绑定参数 → Incorrect number of parameters: expected 1 but found 0
-- 处理：用 Presto 日期表达式替代「上月月初」与 repdate 所在月对齐
--
-- 若业务要「去年同月」而非「上一自然月」，改用注释 B 行

WITH params AS (
    SELECT
        -- 上一自然月（与 repdate 同月对齐用 timestamp 比较，避免字符串 ? 占位）
        date_trunc('month', date_add('month', -1, current_timestamp)) AS target_month,
        'HID0101' AS med_org
)
SELECT
    CURRENTWARDCODE AS "护理单元代码",
    CURRENTWARDNAME AS "护理单元名称",
    CURRENTMEDELEMENTNAME AS "主管科室",
    CURRENTSTAFFGROUPNAME AS "主管医生",
    CURRENTSTAFFGROUPCODE AS "主管医生代码",
    stat_date AS "在院日期",
    total_count AS "在院人数"
FROM (
    SELECT
        CURRENTWARDCODE,
        CURRENTWARDNAME,
        CURRENTMEDELEMENTNAME,
        CURRENTSTAFFGROUPNAME,
        CURRENTSTAFFGROUPCODE,
        date_format(CAST(repdate AS TIMESTAMP), '%Y-%m-%d') AS stat_date,
        sum(BEINHOSPPERSCOUNT) AS total_count,
        row_number() OVER (
            PARTITION BY
                CURRENTWARDCODE,
                CURRENTSTAFFGROUPCODE,
                date_format(CAST(repdate AS TIMESTAMP), '%Y-%m-%d')
            ORDER BY CAST(REPHOUR AS INTEGER) DESC
        ) AS rn
    FROM m1.mdr_beinhosp
    CROSS JOIN params p
    WHERE date_trunc('month', CAST(repdate AS TIMESTAMP)) = p.target_month
      AND iswait = '0'
      AND medorgcode = p.med_org
    GROUP BY
        CURRENTWARDCODE,
        CURRENTWARDNAME,
        CURRENTMEDELEMENTNAME,
        CURRENTSTAFFGROUPNAME,
        CURRENTSTAFFGROUPCODE,
        date_format(CAST(repdate AS TIMESTAMP), '%Y-%m-%d'),
        REPHOUR
) t
WHERE rn = 1
  AND total_count > 0;
