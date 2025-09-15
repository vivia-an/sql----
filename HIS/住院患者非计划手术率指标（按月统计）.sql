-- 住院患者非计划手术率指标（按月统计）
-- 计算公式：行非计划手术的住院患者人次数/同期住院患者总人次数×100%
-- 分子：手术记录中"是否为计划内手术"记录为否的患者人次数
-- 分母：所有出院患者
-- 按月统计每个月数据

WITH
-- 基础住院患者数据（分母）
base_inpatients AS (
    SELECT
        SUBSTRING("Visit_IPReg_OutHospDtTm", 1, 7) AS "统计月份",
        "Visit_IPReg_VisitID",
        "Visit_IPReg_OutHospDtTm" AS "出院时间",
        "Visit_IPReg_InHospDtTm" AS "入院时间",
        "Visit_IPReg_OutHospDeptName" AS "出院科室名称"
    FROM datacenter_db.Visit_IPReg
    WHERE "Visit_IPReg_OutHospDtTm" IS NOT NULL  -- 已出院患者
        AND "Visit_IPReg_OutHospDtTm" != ''      -- 出院时间不为空字符串
        AND "Visit_IPReg_IsDeleted" = '0'        -- 逻辑删除筛选
        AND "Visit_IPReg_InHospDtTm" IS NOT NULL -- 入院时间不为空
        AND "Visit_IPReg_InHospDtTm" != ''       -- 入院时间不为空字符串
),

-- 非计划手术患者数据（分子）
unplanned_surgery_patients AS (
    SELECT DISTINCT
        SUBSTRING(v."Visit_IPReg_OutHospDtTm", 1, 7) AS "统计月份",
        v."Visit_IPReg_VisitID"
    FROM datacenter_db.Visit_IPReg v
    INNER JOIN datacenter_db.Plan_OPSSchedule p ON v."Visit_IPReg_VisitID" = p."Plan_OPSSchedule_VisitID"
    WHERE v."Visit_IPReg_OutHospDtTm" IS NOT NULL  -- 已出院患者
        AND v."Visit_IPReg_OutHospDtTm" != ''      -- 出院时间不为空字符串
        AND v."Visit_IPReg_IsDeleted" = '0'        -- 逻辑删除筛选
        AND p."Plan_OPSSchedule_IsDeleted" = '0'   -- 手术记录逻辑删除筛选
        AND v."Visit_IPReg_InHospDtTm" IS NOT NULL -- 入院时间不为空
        AND v."Visit_IPReg_InHospDtTm" != ''       -- 入院时间不为空字符串
        -- 非计划手术：是否计划标识不等于'1'或为空
        AND (p."Plan_OPSSchedule_IsPlanFlag" != '1' OR p."Plan_OPSSchedule_IsPlanFlag" IS NULL)
),

-- 按月统计
monthly_stats AS (
    SELECT
        b."统计月份",
        COUNT(DISTINCT b."Visit_IPReg_VisitID") AS "同期出院患者总人次数",
        COUNT(DISTINCT u."Visit_IPReg_VisitID") AS "非计划手术患者人次数"
    FROM base_inpatients b
    LEFT JOIN unplanned_surgery_patients u ON b."统计月份" = u."统计月份"
                                           AND b."Visit_IPReg_VisitID" = u."Visit_IPReg_VisitID"
    GROUP BY b."统计月份"
)

-- 最终结果
SELECT
    "统计月份",
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
FROM monthly_stats
WHERE "统计月份" IS NOT NULL
ORDER BY "统计月份" DESC;

-- SQL说明：
-- 
-- 核心逻辑：
-- 1. 分母计算：统计每月所有出院患者总人次数
-- 2. 分子计算：统计每月行非计划手术的住院患者人次数
--    - 通过Plan_OPSSchedule表的Plan_OPSSchedule_IsPlanFlag字段判断
--    - 当该字段不等于'1'或为空时，视为非计划手术
-- 
-- 关键技术要点：
-- - 使用SUBSTRING(出院时间, 1, 7)进行月份分组统计（日期字段为VARCHAR类型）
-- - 中文字段名使用双引号包围适配Presto语法
-- - 使用CTE分步构建逻辑，提高可读性
-- - 结果按统计月份降序排列，最新月份在前
-- - 适配Presto环境：日期时间字段为VARCHAR类型，无需类型转换
-- 
-- 数据血缘来源：
-- - Visit_IPReg: 出院时间、入院时间、就诊ID（分母数据）
-- - Plan_OPSSchedule: 是否计划标识、就诊ID（分子数据）
-- - 过滤条件: IsDeleted = '0' 确保数据有效性
-- 
-- 字段血缘说明：
-- - 统计月份：来源于Visit_IPReg_OutHospDtTm（出院时间）
-- - 分母：Visit_IPReg表中已出院患者总数
-- - 分子：Plan_OPSSchedule表中IsPlanFlag非计划手术的患者数
-- - 关联字段：Visit_IPReg_VisitID = Plan_OPSSchedule_VisitID 