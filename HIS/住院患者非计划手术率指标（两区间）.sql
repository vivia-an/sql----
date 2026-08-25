-- 住院患者非计划手术率指标（两个固定区间各一行）
-- 计算公式：行非计划手术的住院患者人次数 / 同期住院患者总人次数 × 100%
-- 区间1：2025-07-01 ~ 2025-12-31
-- 区间2：2026-01-01 ~ 2026-06-30
--
-- 口径：出院月分母 + Apply_OPS 分子（原按月版逻辑，现固定两区间输出）
--   分母 = 同期已出院住院患者人次（按出院时间归入区间，VisitID 去重）
--   分子 = 同期出院患者中“行非计划手术”的人次（VisitID 去重）
-- 日期字段为 VARCHAR（格式 YYYY-MM-DD HH:MM:SS），用字符串半开区间比较，
-- 上界用次日/次区间起点（< '2026-01-01'、< '2026-07-01'）以完整包含末日全天。
--
-- ★关键修正（相对原版/按月版）：
--   A) 机构收口：数仓为多机构汇聚，分母/分子均加 MedOrgCode='HID0101'，否则被其它院区撑大。
--   B) 非计划手术判定换源：原 Plan_OPSSchedule.IsPlanFlag 实测整列 NULL，会把全部手术误判为非计划；
--      改用 Apply_OPS.PlanAgainOPSFlag = '非计划再次手术'。
--
-- ⚠️ 待确认口径（建议输出明细复核）：
--   1) 分子语义为“非计划【再次】手术”；编码值 1/2/3 含义未知未纳入，需查值域字典确认是否补充。
--   2) 分母按“出院时间”归区间（=出院患者口径）；若需改为按“入院时间”或“在院时间段”请告知。

WITH
-- 基础住院患者数据（分母）：同期已出院、且入院/出院时间齐全
base_inpatients AS (
    SELECT
        CASE
            WHEN "Visit_IPReg_OutHospDtTm" >= '2025-07-01' AND "Visit_IPReg_OutHospDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN "Visit_IPReg_OutHospDtTm" >= '2026-01-01' AND "Visit_IPReg_OutHospDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        "Visit_IPReg_VisitID"
    FROM datacenter_db.Visit_IPReg
    WHERE "Visit_IPReg_MedOrgCode" = 'HID0101'           -- ★本院区(数仓多机构汇聚，必须收口，否则分母被其它院区撑大)
        AND "Visit_IPReg_OutHospDtTm" IS NOT NULL        -- 已出院患者
        AND "Visit_IPReg_OutHospDtTm" != ''              -- 出院时间非空串
        AND "Visit_IPReg_IsDeleted" = '0'                -- 逻辑删除筛选
        AND "Visit_IPReg_InHospDtTm" IS NOT NULL         -- 入院时间非空
        AND "Visit_IPReg_InHospDtTm" != ''               -- 入院时间非空串
        AND "Visit_IPReg_OutHospDtTm" >= '2025-07-01'    -- 两区间总下界
        AND "Visit_IPReg_OutHospDtTm" < '2026-07-01'     -- 两区间总上界
),

-- 非计划手术患者数据（分子）
-- ★口径修正：原 Plan_OPSSchedule.IsPlanFlag 整列全是 NULL（实测），用 "!='1' 或空" 会把全部手术都判成非计划，分子作废。
--   改用 Apply_OPS.PlanAgainOPSFlag = '非计划再次手术'（实测唯一带业务含义的非计划信号，614 条）。
--   注意：该字段语义是"非计划【再次】手术"；另有编码值 1/2/3 含义未知，未纳入，待查值域字典确认是否补充。
unplanned_surgery_patients AS (
    SELECT DISTINCT
        CASE
            WHEN v."Visit_IPReg_OutHospDtTm" >= '2025-07-01' AND v."Visit_IPReg_OutHospDtTm" < '2026-01-01'
                THEN '2025-07-01~2025-12-31'
            WHEN v."Visit_IPReg_OutHospDtTm" >= '2026-01-01' AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01'
                THEN '2026-01-01~2026-06-30'
        END AS "统计区间",
        v."Visit_IPReg_VisitID"
    FROM datacenter_db.Visit_IPReg v
    INNER JOIN datacenter_db.Apply_OPS p
        ON v."Visit_IPReg_VisitID" = p."Apply_OPS_VisitID"
    WHERE v."Visit_IPReg_MedOrgCode" = 'HID0101'         -- ★本院区
        AND p."Apply_OPS_MedOrgCode" = 'HID0101'         -- ★本院区
        AND v."Visit_IPReg_OutHospDtTm" IS NOT NULL
        AND v."Visit_IPReg_OutHospDtTm" != ''
        AND v."Visit_IPReg_IsDeleted" = '0'
        AND p."Apply_OPS_IsDeleted" = '0'                -- 手术申请逻辑删除筛选
        AND v."Visit_IPReg_InHospDtTm" IS NOT NULL
        AND v."Visit_IPReg_InHospDtTm" != ''
        AND v."Visit_IPReg_OutHospDtTm" >= '2025-07-01'
        AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01'
        -- 非计划（再次）手术：计划再次手术标识 = '非计划再次手术'
        AND p."Apply_OPS_PlanAgainOPSFlag" = '非计划再次手术'
),

-- 按区间汇总
interval_stats AS (
    SELECT
        b."统计区间",
        COUNT(DISTINCT b."Visit_IPReg_VisitID") AS "同期出院患者总人次数",
        COUNT(DISTINCT u."Visit_IPReg_VisitID") AS "非计划手术患者人次数"
    FROM base_inpatients b
    LEFT JOIN unplanned_surgery_patients u
        ON b."统计区间" = u."统计区间"
        AND b."Visit_IPReg_VisitID" = u."Visit_IPReg_VisitID"
    WHERE b."统计区间" IS NOT NULL
    GROUP BY b."统计区间"
)

-- 最终结果（每个区间一行）
SELECT
    "统计区间",
    "非计划手术患者人次数" AS "分子",
    "同期出院患者总人次数" AS "分母",
    CASE
        WHEN "同期出院患者总人次数" > 0 THEN
            ROUND(
                CAST("非计划手术患者人次数" AS DOUBLE) /
                CAST("同期出院患者总人次数" AS DOUBLE) * 100,
                2
            )
        ELSE 0
    END AS "住院患者非计划手术率(%)"
FROM interval_stats
ORDER BY "统计区间";

-- 字段血缘：
-- 统计区间       <- datacenter_db.Visit_IPReg.Visit_IPReg_OutHospDtTm（出院时间，归区间）
-- 机构收口       <- Visit_IPReg.Visit_IPReg_MedOrgCode = 'HID0101' / Apply_OPS.Apply_OPS_MedOrgCode = 'HID0101'
-- 分母           <- datacenter_db.Visit_IPReg（同期出院患者，Visit_IPReg_VisitID 去重）
-- 分子           <- datacenter_db.Apply_OPS.Apply_OPS_PlanAgainOPSFlag = '非计划再次手术'
-- 关联键         <- Visit_IPReg.Visit_IPReg_VisitID = Apply_OPS.Apply_OPS_VisitID
