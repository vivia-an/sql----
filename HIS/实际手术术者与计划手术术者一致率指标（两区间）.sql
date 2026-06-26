-- 实际手术术者与计划手术术者一致率（两个固定区间各一行）
-- 计算公式：实际开展手术术者与计划手术术者一致的手术例数 / 同期手术总例数 × 100%
-- 区间1：2025-07-01 ~ 2025-12-31
-- 区间2：2026-01-01 ~ 2026-06-30
--
-- 口径说明：
--   分母 = 同期实际开展手术总例数（OPS_EventMainRecord，按手术开始时间归区间，OPSEventID 计例）
--   分子 = 实际术者代码与排程计划术者代码一致的手术例数
--   关联 = VisitID + 手术名称（PlanOPSName = Plan_OPSSchedule_OPSName）
--   术者比较优先用医师代码（ID 字段在 DC 层常为空，沿用手术医师时间重合率口径）
--   院区筛选：MedOrgCode = 'HID0101'（华西主院区，数仓多机构汇聚必须收口）
--
-- 日期字段为 VARCHAR，半开区间：>= 区间起点 AND < 次区间起点/总上界

WITH
base_surgeries AS (
    SELECT
        CASE
            WHEN evt."OPS_EventMainRecord_OPSBeginDtTm" >= '2025-07-01'
             AND evt."OPS_EventMainRecord_OPSBeginDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN evt."OPS_EventMainRecord_OPSBeginDtTm" >= '2026-01-01'
             AND evt."OPS_EventMainRecord_OPSBeginDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        evt."OPS_EventMainRecord_OPSEventID"        AS "手术事件ID",
        evt."OPS_EventMainRecord_VisitID"           AS "就诊ID",
        trim(evt."OPS_EventMainRecord_PlanOPSName") AS "手术名称",
        trim(evt."OPS_EventMainRecord_OPSDoctCode") AS "实际术者代码",
        trim(evt."OPS_EventMainRecord_OPSDoctName") AS "实际术者姓名"
    FROM datacenter_db."OPS_EventMainRecord" evt
    INNER JOIN datacenter_db."Visit_IPReg" ip
        ON evt."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
    WHERE evt."OPS_EventMainRecord_MedOrgCode" = 'HID0101'
      AND ip."Visit_IPReg_MedOrgCode" = 'HID0101'
      AND coalesce(evt."OPS_EventMainRecord_IsDeleted", '0') = '0'
      AND coalesce(ip."Visit_IPReg_IsDeleted", '0') = '0'
      AND evt."OPS_EventMainRecord_OPSBeginDtTm" IS NOT NULL
      AND trim(evt."OPS_EventMainRecord_OPSBeginDtTm") <> ''
      AND evt."OPS_EventMainRecord_OPSDoctCode" IS NOT NULL
      AND trim(evt."OPS_EventMainRecord_OPSDoctCode") <> ''
      AND evt."OPS_EventMainRecord_OPSBeginDtTm" >= '2025-07-01'
      AND evt."OPS_EventMainRecord_OPSBeginDtTm" < '2026-07-01'
),

plan_match AS (
    SELECT
        b."统计区间",
        b."手术事件ID",
        b."实际术者代码",
        trim(p."Plan_OPSSchedule_OperateDoctCode") AS "计划术者代码",
        row_number() OVER (
            PARTITION BY b."手术事件ID"
            ORDER BY p."Plan_OPSSchedule_OPSPlanBeginDtTm" DESC
        ) AS plan_rn
    FROM base_surgeries b
    INNER JOIN datacenter_db."Plan_OPSSchedule" p
        ON b."就诊ID" = p."Plan_OPSSchedule_VisitID"
       AND b."手术名称" = trim(p."Plan_OPSSchedule_OPSName")
    WHERE p."Plan_OPSSchedule_MedOrgCode" = 'HID0101'
      AND coalesce(p."Plan_OPSSchedule_IsDeleted", '0') = '0'
      AND p."Plan_OPSSchedule_OperateDoctCode" IS NOT NULL
      AND trim(p."Plan_OPSSchedule_OperateDoctCode") <> ''
),

consistent_surgeries AS (
    SELECT DISTINCT
        "统计区间",
        "手术事件ID"
    FROM plan_match
    WHERE plan_rn = 1
      AND "实际术者代码" = "计划术者代码"
),

interval_stats AS (
    SELECT
        b."统计区间",
        count(DISTINCT b."手术事件ID") AS "同期手术总例数",
        count(DISTINCT c."手术事件ID") AS "术者一致例数"
    FROM base_surgeries b
    LEFT JOIN consistent_surgeries c
        ON b."统计区间" = c."统计区间"
       AND b."手术事件ID" = c."手术事件ID"
    WHERE b."统计区间" IS NOT NULL
    GROUP BY b."统计区间"
)

SELECT
    "统计区间",
    "术者一致例数" AS "分子",
    "同期手术总例数" AS "分母",
    CASE
        WHEN "同期手术总例数" > 0 THEN
            round(
                cast("术者一致例数" AS double)
                / cast("同期手术总例数" AS double) * 100,
                2
            )
        ELSE 0
    END AS "实际手术术者与计划手术术者一致率(%)"
FROM interval_stats
ORDER BY "统计区间";

-- 字段血缘：
-- 统计区间   <- OPS_EventMainRecord.OPSBeginDtTm（手术开始时间，归区间）
-- 分母       <- OPS_EventMainRecord + Visit_IPReg（住院实际手术，OPSEventID 计例）
-- 分子       <- OPSDoctCode = Plan_OPSSchedule_OperateDoctCode
-- 计划术者   <- Plan_OPSSchedule.OperateDoctCode / OperateDoctName
-- 实际术者   <- OPS_EventMainRecord.OPSDoctCode / OPSDoctName
-- 关联键     <- VisitID + PlanOPSName = OPSName
-- 院区筛选   <- OPS_EventMainRecord / Visit_IPReg / Plan_OPSSchedule .MedOrgCode = HID0101
