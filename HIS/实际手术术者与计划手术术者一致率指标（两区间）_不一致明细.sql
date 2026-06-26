-- 实际手术术者与计划手术术者一致率 — 不一致明细（两区间）
-- 口径与主指标一致；输出分母中未计入分子的手术行
--   ① 无排程匹配：VisitID+手术名称 未关联到 Plan_OPSSchedule
--   ② 术者代码不一致：有排程但 实际术者代码 ≠ 计划术者代码（取最近一条排程）

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
        trim(ip."Visit_IPReg_VisitNo")              AS "住院号",
        trim(ip."Visit_IPReg_PersName")             AS "患者姓名",
        trim(evt."OPS_EventMainRecord_PlanOPSName") AS "手术名称",
        evt."OPS_EventMainRecord_OPSBeginDtTm"      AS "手术开始时间",
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
      AND trim(cast(evt."OPS_EventMainRecord_OPSBeginDtTm" AS varchar)) <> ''
      AND evt."OPS_EventMainRecord_OPSDoctCode" IS NOT NULL
      AND trim(cast(evt."OPS_EventMainRecord_OPSDoctCode" AS varchar)) <> ''
      AND evt."OPS_EventMainRecord_OPSBeginDtTm" >= '2025-07-01'
      AND evt."OPS_EventMainRecord_OPSBeginDtTm" < '2026-07-01'
),

plan_match AS (
    SELECT
        b."统计区间",
        b."手术事件ID",
        b."就诊ID",
        b."住院号",
        b."患者姓名",
        b."手术名称",
        b."手术开始时间",
        b."实际术者代码",
        b."实际术者姓名",
        trim(p."Plan_OPSSchedule_OperateDoctCode") AS "计划术者代码",
        trim(p."Plan_OPSSchedule_OperateDoctName") AS "计划术者姓名",
        p."Plan_OPSSchedule_OPSPlanBeginDtTm"      AS "计划手术开始时间",
        row_number() OVER (
            PARTITION BY b."手术事件ID"
            ORDER BY p."Plan_OPSSchedule_OPSPlanBeginDtTm" DESC
        ) AS plan_rn
    FROM base_surgeries b
    LEFT JOIN datacenter_db."Plan_OPSSchedule" p
        ON b."就诊ID" = p."Plan_OPSSchedule_VisitID"
       AND b."手术名称" = trim(p."Plan_OPSSchedule_OPSName")
       AND p."Plan_OPSSchedule_MedOrgCode" = 'HID0101'
       AND coalesce(p."Plan_OPSSchedule_IsDeleted", '0') = '0'
       AND p."Plan_OPSSchedule_OperateDoctCode" IS NOT NULL
       AND trim(p."Plan_OPSSchedule_OperateDoctCode") <> ''
)

SELECT
    "统计区间",
    "手术事件ID",
    "就诊ID",
    "住院号",
    "患者姓名",
    "手术名称",
    "手术开始时间",
    "实际术者代码",
    "实际术者姓名",
    "计划术者代码",
    "计划术者姓名",
    "计划手术开始时间",
    CASE
        WHEN "计划术者代码" IS NULL OR trim("计划术者代码") = '' THEN '无排程匹配'
        WHEN "实际术者代码" <> "计划术者代码" THEN '术者代码不一致'
        ELSE '一致'
    END AS "不一致原因"
FROM plan_match
WHERE plan_rn = 1
  AND "统计区间" IS NOT NULL
  AND (
        "计划术者代码" IS NULL
        OR trim("计划术者代码") = ''
        OR "实际术者代码" <> "计划术者代码"
      )
ORDER BY "统计区间", "不一致原因", "手术开始时间", "手术事件ID";

-- 校验：各区间 count(*) 应 = 分母 - 分子（与主指标、分子明细对照）
-- 血缘：主指标 ← 本表明细；分子明细 = 本表 WHERE 不一致原因 过滤掉后的补集
