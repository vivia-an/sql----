-- 术前讨论计划手术一致率指标（按月统计）
-- 计算公式：实际开展手术与术前讨论计划手术一致的手术例数/同期手术总例数×100%
-- 分子：手术名称与排程手术名称相同的手术例数
-- 分母：手术总例数
-- 按月统计每个月数据

WITH
-- 基础手术数据（分母）
base_surgeries AS (
    SELECT
        SUBSTRING("OPS_Reg_OPSDtTm", 1, 7) AS "统计月份",
        "OPS_Reg_VisitID",
        "OPS_Reg_OPSName" AS "实际手术名称",
        "OPS_Reg_OPSDtTm" AS "手术时间",
        "OPS_Reg_OPSCode" AS "实际手术代码"
    FROM datacenter_db.OPS_Reg
    WHERE "OPS_Reg_OPSDtTm" IS NOT NULL  -- 已完成手术
        AND "OPS_Reg_OPSDtTm" != ''      -- 手术时间不为空字符串
        AND "OPS_Reg_IsDeleted" = '0'    -- 逻辑删除筛选
        AND "OPS_Reg_OPSName" IS NOT NULL -- 手术名称不为空
        AND "OPS_Reg_OPSName" != ''      -- 手术名称不为空字符串
),

-- 手术名称一致的数据（分子）
consistent_surgeries AS (
    SELECT DISTINCT
        SUBSTRING(ops."OPS_Reg_OPSDtTm", 1, 7) AS "统计月份",
        ops."OPS_Reg_VisitID"
    FROM datacenter_db.OPS_Reg ops
    INNER JOIN datacenter_db.Plan_OPSSchedule plan ON ops."OPS_Reg_VisitID" = plan."Plan_OPSSchedule_VisitID"
    WHERE ops."OPS_Reg_OPSDtTm" IS NOT NULL  -- 已完成手术
        AND ops."OPS_Reg_OPSDtTm" != ''      -- 手术时间不为空字符串
        AND ops."OPS_Reg_IsDeleted" = '0'    -- 手术登记表逻辑删除筛选
        AND plan."Plan_OPSSchedule_IsDeleted" = '0'  -- 手术排程表逻辑删除筛选
        AND ops."OPS_Reg_OPSName" IS NOT NULL -- 实际手术名称不为空
        AND ops."OPS_Reg_OPSName" != ''      -- 实际手术名称不为空字符串
        AND plan."Plan_OPSSchedule_OPSName" IS NOT NULL -- 计划手术名称不为空
        AND plan."Plan_OPSSchedule_OPSName" != ''      -- 计划手术名称不为空字符串
        -- 手术名称一致性判断
        AND TRIM(ops."OPS_Reg_OPSName") = TRIM(plan."Plan_OPSSchedule_OPSName")
),

-- 按月统计
monthly_stats AS (
    SELECT
        b."统计月份",
        COUNT(DISTINCT b."OPS_Reg_VisitID") AS "同期手术总例数",
        COUNT(DISTINCT c."OPS_Reg_VisitID") AS "计划手术一致例数"
    FROM base_surgeries b
    LEFT JOIN consistent_surgeries c ON b."统计月份" = c."统计月份"
                                     AND b."OPS_Reg_VisitID" = c."OPS_Reg_VisitID"
    GROUP BY b."统计月份"
)

-- 最终结果
SELECT
    "统计月份",
    "计划手术一致例数" AS "分子",
    "同期手术总例数" AS "分母",
    CASE
        WHEN "同期手术总例数" > 0 THEN
            ROUND(
                CAST("计划手术一致例数" AS DOUBLE) /
                CAST("同期手术总例数" AS DOUBLE) * 100,
                2
            )
        ELSE 0
    END AS "术前讨论计划手术一致率(%)"
FROM monthly_stats
WHERE "统计月份" IS NOT NULL
ORDER BY "统计月份" DESC;

-- SQL说明：
-- 
-- 核心逻辑：
-- 1. 分母计算：统计每月所有实际开展的手术总例数（OPS_Reg表）
-- 2. 分子计算：统计每月实际手术名称与计划手术名称一致的例数
--    - 通过比较OPS_Reg_OPSName（实际手术名称）与Plan_OPSSchedule_OPSName（计划手术名称）
--    - 使用TRIM函数去除首尾空格，确保比较准确性
-- 
-- 关键技术要点：
-- - 使用SUBSTRING(手术时间, 1, 7)进行月份分组统计（日期字段为VARCHAR类型）
-- - 中文字段名使用双引号包围适配Presto语法
-- - 使用CTE分步构建逻辑，提高可读性
-- - 结果按统计月份降序排列，最新月份在前
-- - 适配Presto环境：日期时间字段为VARCHAR类型，无需类型转换
-- 
-- 数据血缘来源：
-- - OPS_Reg: 手术时间、实际手术名称、就诊ID（分母数据和比较基准）
-- - Plan_OPSSchedule: 计划手术名称、就诊ID（分子数据比较对象）
-- - 过滤条件: IsDeleted = '0' 确保数据有效性
-- 
-- 字段血缘说明：
-- - 统计月份：来源于OPS_Reg_OPSDtTm（手术时间）
-- - 分母：OPS_Reg表中已完成手术的总例数
-- - 分子：OPS_Reg_OPSName与Plan_OPSSchedule_OPSName名称一致的手术例数
-- - 关联字段：OPS_Reg_VisitID = Plan_OPSSchedule_VisitID
-- - 一致性判断：TRIM(OPS_Reg_OPSName) = TRIM(Plan_OPSSchedule_OPSName) 