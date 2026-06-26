-- 麻醉医师手术时间重合率（两个固定区间各一行）
-- 计算公式：同一时间内手术麻醉医师为同一人的手术例数 / 同期住院患者手术总例数 × 100%
-- 区间1：2025-07-01 ~ 2025-12-31
-- 区间2：2026-01-01 ~ 2026-06-30
--
-- 分母（国考06口径）：HID0101 + Visit_IPReg + 麻醉起止合法，OPSEventID 计例
-- 分子：与另一台手术比较时，第一/二/三麻醉团队完全一致 + 麻醉时间段相交 → 该台计入
--       （所有麻醉医师都一样，且同一时间重合，才算重合）
-- 分子：count(DISTINCT OPSEventID)，每台手术最多计 1 次（与多台相交不重复累加）
-- 重合：team_sig 相同 AND 麻醉时间段相交（不同 OPSEventID）

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
        ops."OPS_EventMainRecord_VisitID"           AS "就诊ID",
        ops."OPS_EventMainRecord_NarcosisBeginDtTm" AS "麻醉开始时间",
        ops."OPS_EventMainRecord_NarcosisEndDtTm"   AS "麻醉结束时间",
        ops."OPS_EventMainRecord_PlanOPSName"       AS "手术名称"
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
    SELECT
        "统计区间",
        "手术事件ID",
        "就诊ID",
        "麻醉开始时间",
        "麻醉结束时间",
        "手术名称"
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

anesthesiologist_slots AS (
    SELECT
        s."统计区间",
        s."手术事件ID",
        s."麻醉开始时间",
        s."麻醉结束时间",
        coalesce(
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctID"), '')
        ) AS "麻醉医师键",
        '1' AS "麻醉医师序号"
    FROM base_surgeries s
    INNER JOIN datacenter_db."OPS_EventMainRecord" ops
        ON s."手术事件ID" = ops."OPS_EventMainRecord_OPSEventID"
    WHERE coalesce(
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_NarcosisDoctID"), '')
          ) IS NOT NULL

    UNION ALL

    SELECT
        s."统计区间",
        s."手术事件ID",
        s."麻醉开始时间",
        s."麻醉结束时间",
        coalesce(
            nullif(trim(ops."OPS_EventMainRecord_SecondNarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_SecondNarcosisDoctID"), '')
        ),
        '2'
    FROM base_surgeries s
    INNER JOIN datacenter_db."OPS_EventMainRecord" ops
        ON s."手术事件ID" = ops."OPS_EventMainRecord_OPSEventID"
    WHERE coalesce(
            nullif(trim(ops."OPS_EventMainRecord_SecondNarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_SecondNarcosisDoctID"), '')
          ) IS NOT NULL

    UNION ALL

    SELECT
        s."统计区间",
        s."手术事件ID",
        s."麻醉开始时间",
        s."麻醉结束时间",
        coalesce(
            nullif(trim(ops."OPS_EventMainRecord_ThirdNarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_ThirdNarcosisDoctID"), '')
        ),
        '3'
    FROM base_surgeries s
    INNER JOIN datacenter_db."OPS_EventMainRecord" ops
        ON s."手术事件ID" = ops."OPS_EventMainRecord_OPSEventID"
    WHERE coalesce(
            nullif(trim(ops."OPS_EventMainRecord_ThirdNarcosisDoctCode"), ''),
            nullif(trim(ops."OPS_EventMainRecord_ThirdNarcosisDoctID"), '')
          ) IS NOT NULL
),

event_team AS (
    SELECT
        s."统计区间",
        s."手术事件ID",
        min(s."麻醉开始时间") AS "麻醉开始时间",
        max(s."麻醉结束时间") AS "麻醉结束时间",
        array_join(array_sort(array_distinct(array_agg(s."麻醉医师键"))), '|') AS "麻醉团队签名"
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

interval_stats AS (
    SELECT
        base."统计区间",
        count(DISTINCT base."手术事件ID") AS "住院患者手术总例数",
        count(DISTINCT overlap."手术事件ID") AS "麻醉医师时间重合例数"
    FROM base_surgeries base
    LEFT JOIN overlapping_surgeries overlap
        ON base."统计区间" = overlap."统计区间"
       AND base."手术事件ID" = overlap."手术事件ID"
    WHERE base."统计区间" IS NOT NULL
    GROUP BY base."统计区间"
)

SELECT
    "统计区间",
    "麻醉医师时间重合例数" AS "分子",
    "住院患者手术总例数" AS "分母",
    CASE
        WHEN "住院患者手术总例数" > 0 THEN
            round(
                cast("麻醉医师时间重合例数" AS double)
                / cast("住院患者手术总例数" AS double) * 100,
                2
            )
        ELSE 0
    END AS "麻醉医师手术时间重合率(%)"
FROM interval_stats
ORDER BY "统计区间";

-- 去重：base OPSEventID 唯一；overlapping DISTINCT；分子 count(DISTINCT OPSEventID)
