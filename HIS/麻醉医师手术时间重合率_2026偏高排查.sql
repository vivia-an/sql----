-- 麻醉医师手术时间重合率 — 2026 偏高单条探测（对比 2025-07~12）
-- 与主 SQL 同源 CTE；一次跑出分母/分子/时长/团队/脏数据疑点

WITH
base_surgeries_raw AS (
    SELECT
        CASE
            WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
             AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2026-01-01'
             AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        ops."OPS_EventMainRecord_OPSEventID"        AS "手术事件ID",
        ops."OPS_EventMainRecord_NarcosisBeginDtTm" AS "麻醉开始时间",
        ops."OPS_EventMainRecord_NarcosisEndDtTm"   AS "麻醉结束时间"
    FROM datacenter_db."OPS_EventMainRecord" ops
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON ops."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
    WHERE ops."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
      AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
      AND coalesce(ops."OPS_EventMainRecord_IsDeleted", '0') = '0'
      AND coalesce(ip."Visit_IPReg_IsDeleted", '0') = '0'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" IS NOT NULL
      AND trim(ops."OPS_EventMainRecord_NarcosisBeginDtTm") <> ''
      AND ops."OPS_EventMainRecord_NarcosisEndDtTm" IS NOT NULL
      AND trim(ops."OPS_EventMainRecord_NarcosisEndDtTm") <> ''
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" >= '2025-07-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm" < '2026-07-01'
      AND ops."OPS_EventMainRecord_NarcosisBeginDtTm"
          < ops."OPS_EventMainRecord_NarcosisEndDtTm"
),

base_surgeries AS (
    SELECT "统计区间", "手术事件ID", "麻醉开始时间", "麻醉结束时间"
    FROM (
        SELECT
            r.*,
            row_number() OVER (
                PARTITION BY r."统计区间", r."手术事件ID"
                ORDER BY r."麻醉开始时间", r."麻醉结束时间"
            ) AS rn
        FROM base_surgeries_raw r
        WHERE r."统计区间" IS NOT NULL
    ) d
    WHERE d.rn = 1
),

dup_event_check AS (
    SELECT
        "统计区间",
        count(*) AS "去重前行数",
        count(DISTINCT "手术事件ID") AS "去重后事件数"
    FROM base_surgeries_raw
    WHERE "统计区间" IS NOT NULL
    GROUP BY "统计区间"
),

base_with_duration AS (
    SELECT
        b.*,
        date_diff(
            'minute',
            cast(b."麻醉开始时间" AS timestamp),
            cast(b."麻醉结束时间" AS timestamp)
        ) AS "麻醉时长分钟"
    FROM base_surgeries b
    WHERE b."统计区间" IS NOT NULL
),

anesthesiologist_slots AS (
    SELECT
        s."统计区间",
        s."手术事件ID",
        s."麻醉开始时间",
        s."麻醉结束时间",
        coalesce(
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctID"), '')
        ) AS "麻醉医师键"
    FROM base_surgeries s
    INNER JOIN datacenter_db."OPS_EventMainRecord" ops
        ON s."手术事件ID" = ops."OPS_EventMainRecord_OPSEventID"
    WHERE coalesce(
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctID"), '')
          ) IS NOT NULL
    UNION ALL
    SELECT s."统计区间", s."手术事件ID", s."麻醉开始时间", s."麻醉结束时间",
        coalesce(nullif(trim(ops."OPS_EventMainRecord_SecondNarcosisDoctCode"), ''),
                 nullif(trim(ops."OPS_EventMainRecord_SecondNarcosisDoctID"), ''))
    FROM base_surgeries s
    INNER JOIN datacenter_db."OPS_EventMainRecord" ops
        ON s."手术事件ID" = ops."OPS_EventMainRecord_OPSEventID"
    WHERE coalesce(nullif(trim(ops."OPS_EventMainRecord_SecondNarcosisDoctCode"), ''),
                   nullif(trim(ops."OPS_EventMainRecord_SecondNarcosisDoctID"), '')) IS NOT NULL
    UNION ALL
    SELECT s."统计区间", s."手术事件ID", s."麻醉开始时间", s."麻醉结束时间",
        coalesce(nullif(trim(ops."OPS_EventMainRecord_ThirdNarcosisDoctCode"), ''),
                 nullif(trim(ops."OPS_EventMainRecord_ThirdNarcosisDoctID"), ''))
    FROM base_surgeries s
    INNER JOIN datacenter_db."OPS_EventMainRecord" ops
        ON s."手术事件ID" = ops."OPS_EventMainRecord_OPSEventID"
    WHERE coalesce(nullif(trim(ops."OPS_EventMainRecord_ThirdNarcosisDoctCode"), ''),
                   nullif(trim(ops."OPS_EventMainRecord_ThirdNarcosisDoctID"), '')) IS NOT NULL
),

event_team AS (
    SELECT
        s."统计区间",
        s."手术事件ID",
        min(s."麻醉开始时间") AS "麻醉开始时间",
        max(s."麻醉结束时间") AS "麻醉结束时间",
        array_join(array_sort(array_distinct(array_agg(s."麻醉医师键"))), '|') AS "麻醉团队签名",
        count(DISTINCT s."麻醉医师键") AS "麻醉医师人数"
    FROM anesthesiologist_slots s
    GROUP BY s."统计区间", s."手术事件ID"
),

overlapping_surgeries AS (
    SELECT DISTINCT
        a."统计区间",
        a."手术事件ID"
    FROM event_team a
    INNER JOIN event_team b
        ON a."统计区间" = b."统计区间"
       AND a."手术事件ID" <> b."手术事件ID"
       AND a."麻醉团队签名" = b."麻醉团队签名"
       AND a."麻醉开始时间" < b."麻醉结束时间"
       AND a."麻醉结束时间" > b."麻醉开始时间"
),

interval_core AS (
    SELECT
        b."统计区间",
        count(DISTINCT b."手术事件ID") AS "分母",
        count(DISTINCT o."手术事件ID") AS "分子"
    FROM base_surgeries b
    LEFT JOIN overlapping_surgeries o
        ON b."统计区间" = o."统计区间"
       AND b."手术事件ID" = o."手术事件ID"
    WHERE b."统计区间" IS NOT NULL
    GROUP BY b."统计区间"
),

team_size AS (
    SELECT
        "统计区间",
        max("团队台数") AS "最大团队签名台数"
    FROM (
        SELECT "统计区间", "麻醉团队签名", count(*) AS "团队台数"
        FROM event_team
        GROUP BY "统计区间", "麻醉团队签名"
    ) t
    GROUP BY "统计区间"
),

dup_time_bucket AS (
    SELECT
        "统计区间",
        count(*) AS "重复起止组合组数_>=10台"
    FROM (
        SELECT
            "统计区间",
            concat(
                cast("麻醉开始时间" AS varchar), '#',
                cast("麻醉结束时间" AS varchar)
            ) AS time_pair,
            count(DISTINCT "手术事件ID") AS cnt
        FROM base_surgeries
        WHERE "统计区间" IS NOT NULL
        GROUP BY 1, 2
        HAVING count(DISTINCT "手术事件ID") >= 10
    ) x
    GROUP BY "统计区间"
),

top_team AS (
    SELECT
        "统计区间",
        "麻醉团队签名",
        "团队台数",
        row_number() OVER (PARTITION BY "统计区间" ORDER BY "团队台数" DESC) AS rn
    FROM (
        SELECT "统计区间", "麻醉团队签名", count(*) AS "团队台数"
        FROM event_team
        GROUP BY "统计区间", "麻醉团队签名"
    ) t
)

SELECT "统计区间", "排查项", "数值", "备注"
FROM (
    SELECT "统计区间", '01_主SQL分母' AS "排查项",
        cast("分母" AS bigint) AS "数值", cast(null AS varchar) AS "备注"
    FROM interval_core

    UNION ALL
    SELECT "统计区间", '02_主SQL分子', "分子", null FROM interval_core

    UNION ALL
    SELECT "统计区间", '03_重合率(%)',
        "分子",
        cast(round(cast("分子" AS double) / cast("分母" AS double) * 100, 2) AS varchar)
    FROM interval_core
    WHERE "分母" > 0

    UNION ALL
    SELECT b."统计区间", '04_无麻醉医师键_仍在分母',
        count(DISTINCT b."手术事件ID"),
        cast(null AS varchar)
    FROM base_surgeries b
    LEFT JOIN event_team e
        ON b."统计区间" = e."统计区间"
       AND b."手术事件ID" = e."手术事件ID"
    WHERE b."统计区间" IS NOT NULL
      AND e."手术事件ID" IS NULL
    GROUP BY b."统计区间"

    UNION ALL
    SELECT "统计区间", '05_单人麻醉团队台数',
        count(*), null
    FROM event_team
    WHERE "麻醉医师人数" = 1
    GROUP BY "统计区间"

    UNION ALL
    SELECT "统计区间", '06_多人麻醉团队台数',
        count(*), null
    FROM event_team
    WHERE "麻醉医师人数" >= 2
    GROUP BY "统计区间"

    UNION ALL
    SELECT "统计区间", '07_麻醉时长>24h台数',
        count(DISTINCT "手术事件ID"), null
    FROM base_with_duration
    WHERE "麻醉时长分钟" > 1440
    GROUP BY "统计区间"

    UNION ALL
    SELECT "统计区间", '08_麻醉时长>12h台数',
        count(DISTINCT "手术事件ID"), null
    FROM base_with_duration
    WHERE "麻醉时长分钟" > 720
    GROUP BY "统计区间"

    UNION ALL
    SELECT "统计区间", '09_起止时间完全相同台数',
        count(DISTINCT "手术事件ID"), null
    FROM base_surgeries
    WHERE cast("麻醉开始时间" AS varchar) = cast("麻醉结束时间" AS varchar)
    GROUP BY "统计区间"

    UNION ALL
    SELECT "统计区间", '10_相同起止>=10台的时间组合数',
        coalesce("重复起止组合组数_>=10台", cast(0 AS bigint)), null
    FROM dup_time_bucket

    UNION ALL
    SELECT "统计区间", '11_团队签名distinct数',
        count(DISTINCT "麻醉团队签名"), null
    FROM event_team
    GROUP BY "统计区间"

    UNION ALL
    SELECT "统计区间", '12_最大团队签名台数',
        "最大团队签名台数", null
    FROM team_size

    UNION ALL
    SELECT "统计区间", '13_分子占分母比例(%)',
        "分子",
        concat(
            cast(round(cast("分子" AS double) / cast("分母" AS double) * 100, 2) AS varchar),
            '% 分母=', cast("分母" AS varchar)
        )
    FROM interval_core
    WHERE "分母" > 0

    UNION ALL
    SELECT "统计区间", '14_TOP1团队签名台数',
        "团队台数",
        substr("麻醉团队签名", 1, 80)
    FROM top_team
    WHERE rn = 1

    UNION ALL
    SELECT e."统计区间", '15_TOP1团队进入分子台数',
        count(DISTINCT o."手术事件ID"),
        substr(e."麻醉团队签名", 1, 80)
    FROM top_team e
    INNER JOIN event_team t
        ON e."统计区间" = t."统计区间"
       AND e."麻醉团队签名" = t."麻醉团队签名"
    INNER JOIN overlapping_surgeries o
        ON t."统计区间" = o."统计区间"
       AND t."手术事件ID" = o."手术事件ID"
    WHERE e.rn = 1
    GROUP BY e."统计区间", e."麻醉团队签名", e."团队台数"

    UNION ALL
    SELECT b."统计区间", '16_仅第一麻醉_任一重合分子(对照)',
        count(DISTINCT b."手术事件ID"),
        '不用团队签名,仅NarcosisDoct'
    FROM base_surgeries b
    INNER JOIN datacenter_db."OPS_EventMainRecord" ops
        ON b."手术事件ID" = ops."OPS_EventMainRecord_OPSEventID"
    WHERE coalesce(
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctID"), '')
          ) IS NOT NULL
      AND EXISTS (
          SELECT 1
          FROM base_surgeries b2
          INNER JOIN datacenter_db."OPS_EventMainRecord" ops2
              ON b2."手术事件ID" = ops2."OPS_EventMainRecord_OPSEventID"
          WHERE b2."统计区间" = b."统计区间"
            AND b2."手术事件ID" <> b."手术事件ID"
            AND coalesce(
                    nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctCode"), ''),
                    nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctID"), '')
                ) = coalesce(
                    nullif(trim(ops2."OPS_EventMainRecord_NarcosisDoctCode"), ''),
                    nullif(trim(ops2."OPS_EventMainRecord_NarcosisDoctID"), '')
                )
            AND b."麻醉开始时间" < b2."麻醉结束时间"
            AND b."麻醉结束时间" > b2."麻醉开始时间"
      )
    GROUP BY b."统计区间"

    UNION ALL
    SELECT "统计区间", '17_OPSEventID重复行数(去重前-去重后)',
        "去重前行数" - "去重后事件数",
        concat('前行=', cast("去重前行数" AS varchar), ' distinct=', cast("去重后事件数" AS varchar))
    FROM dup_event_check
) x
ORDER BY "统计区间", "排查项";
