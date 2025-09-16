-- 四级手术与三级手术患者死亡率比指标（按月统计）
-- 定义：四级手术患者死亡率与三级手术患者死亡率的比
-- 计算公式：四级手术与三级手术患者死亡率比 = 四级手术患者死亡率 ÷ 三级手术患者死亡率
-- 四级手术患者死亡率 = 四级手术患者死亡人数 / 四级手术患者总人数 × 100%
-- 三级手术患者死亡率 = 三级手术患者死亡人数 / 三级手术患者总人数 × 100%
-- 按月统计每个月数据，给出分子分母

WITH
-- 基础手术患者数据
base_surgery_data AS (
    SELECT
        SUBSTRING(CAST(ops."MR_FPOPS_OPSDtTm" AS VARCHAR), 1, 7) AS "统计月份",
        ops."MR_FPOPS_VisitID",
        ops."MR_FPOPS_MROPSID",
        ops."MR_FPOPS_OPSLevelCode" AS "手术级别代码",
        ops."MR_FPOPS_OPSLevelName" AS "手术级别名称",
        ops."MR_FPOPS_PlanOPSName" AS "手术名称",

        -- 死亡标识：参照死亡率文件中的LIKE模糊匹配方式
        CASE
            WHEN (fp."MR_FP_OutHospModeName" LIKE '%死亡%'
                  OR fp."MR_FP_OutHospModeCode" LIKE '%死亡%'
                  OR fp."MR_FP_OutHospModeName" LIKE '%亡%')
            THEN 1
            ELSE 0
        END AS "死亡标识",

        fp."MR_FP_OutHospModeName" AS "离院方式名称",
        fp."MR_FP_OutHospModeCode" AS "离院方式代码"

    FROM datacenter_db.MR_FPOPS ops
    INNER JOIN datacenter_db.MR_FP fp ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"

    WHERE ops."MR_FPOPS_OPSDtTm" IS NOT NULL                    -- 手术时间不为空
        AND ops."MR_FPOPS_OPSLevelCode" IN ('3', '4')          -- 只统计三级和四级手术
        AND ops."MR_FPOPS_IsDeleted" = '0'                     -- 逻辑删除筛选
        AND fp."MR_FP_IsDeleted" = '0'                         -- 病案首页逻辑删除筛选
),

-- 按月按手术级别统计数据
monthly_surgery_stats AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        COUNT(DISTINCT "MR_FPOPS_MROPSID") AS "手术患者总人数",
        SUM("死亡标识") AS "死亡患者人数"
    FROM base_surgery_data
    GROUP BY "统计月份", "手术级别代码", "手术级别名称"
),

-- 计算各级别手术患者死亡率
monthly_death_rates AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        "手术患者总人数",
        "死亡患者人数",
        CASE
            WHEN "手术患者总人数" > 0 THEN
                ROUND(
                    CAST("死亡患者人数" AS DOUBLE) / CAST("手术患者总人数" AS DOUBLE) * 100,
                    4
                )
            ELSE 0
        END AS "患者死亡率(%)"
    FROM monthly_surgery_stats
),

-- 汇总三级和四级手术数据
monthly_summary AS (
    SELECT
        "统计月份",
        -- 三级手术数据
        MAX(CASE WHEN "手术级别代码" = '3' THEN "手术患者总人数" END) AS "三级手术患者总人数",
        MAX(CASE WHEN "手术级别代码" = '3' THEN "死亡患者人数" END) AS "三级手术死亡患者人数",
        MAX(CASE WHEN "手术级别代码" = '3' THEN "患者死亡率(%)" END) AS "三级手术患者死亡率(%)",
        -- 四级手术数据
        MAX(CASE WHEN "手术级别代码" = '4' THEN "手术患者总人数" END) AS "四级手术患者总人数",
        MAX(CASE WHEN "手术级别代码" = '4' THEN "死亡患者人数" END) AS "四级手术死亡患者人数",
        MAX(CASE WHEN "手术级别代码" = '4' THEN "患者死亡率(%)" END) AS "四级手术患者死亡率(%)"
    FROM monthly_death_rates
    GROUP BY "统计月份"
)

-- 最终结果输出
SELECT
    "统计月份",
    -- 三级手术数据（分母部分）
    COALESCE("三级手术患者总人数", 0) AS "分母_三级手术患者总人数",
    COALESCE("三级手术死亡患者人数", 0) AS "分子_三级手术死亡患者人数",
    COALESCE("三级手术患者死亡率(%)", 0) AS "三级手术患者死亡率(%)",
    -- 四级手术数据（分子部分）
    COALESCE("四级手术患者总人数", 0) AS "分母_四级手术患者总人数",
    COALESCE("四级手术死亡患者人数", 0) AS "分子_四级手术死亡患者人数",
    COALESCE("四级手术患者死亡率(%)", 0) AS "四级手术患者死亡率(%)",
    -- 死亡率比值
    CASE
        WHEN COALESCE("三级手术患者死亡率(%)", 0) > 0 THEN
            ROUND(
                COALESCE("四级手术患者死亡率(%)", 0) / "三级手术患者死亡率(%)",
                4
            )
        ELSE NULL
    END AS "四级与三级手术患者死亡率比",
    CONCAT(
        '四级手术患者死亡率：',
        CAST(COALESCE("四级手术患者死亡率(%)", 0) AS VARCHAR),
        '%；三级手术患者死亡率：',
        CAST(COALESCE("三级手术患者死亡率(%)", 0) AS VARCHAR),
        '%'
    ) AS "计算说明"
FROM monthly_summary
WHERE "统计月份" IS NOT NULL
    AND ("三级手术患者总人数" > 0 OR "四级手术患者总人数" > 0)  -- 至少有一种级别的手术
ORDER BY "统计月份" DESC

-- 数据来源说明：
-- 1. 手术数据：MR_FPOPS 病案首页手术表
-- 2. 死亡数据：MR_FP 病案首页表的离院方式字段（参照死亡率文件中的判断逻辑）
-- 3. 月份统计：基于MR_FPOPS_OPSDtTm手术时间进行分组
--
-- 字段血缘关系：
-- - 手术级别：MR_FPOPS.MR_FPOPS_OPSLevelCode（VARCHAR，3=三级，4=四级）
-- - 手术级别名称：MR_FPOPS.MR_FPOPS_OPSLevelName（VARCHAR）
-- - 死亡标识：通过MR_FP.MR_FP_OutHospModeName/MR_FP_OutHospModeCode LIKE '%死亡%' OR LIKE '%亡%' 计算得出
-- - 离院方式：MR_FP.MR_FP_OutHospModeName（VARCHAR）、MR_FP.MR_FP_OutHospModeCode（VARCHAR）
-- - 手术时间：MR_FPOPS.MR_FPOPS_OPSDtTm（VARCHAR，用于月份统计）
-- - 关联字段：MR_FPOPS.MR_FPOPS_VisitID = MR_FP.MR_FP_VisitID
--
-- 关键技术要点：
-- - 使用SUBSTRING(手术时间, 1, 7)进行月份分组统计（日期字段为VARCHAR类型）
-- - 中文字段名使用双引号包围适配Presto语法
-- - 死亡判断使用LIKE模糊匹配，参照已验证的死亡率文件逻辑
-- - 使用CASE WHEN进行条件统计，分别计算三级和四级手术数据
-- - 通过MAX聚合函数将三级四级手术数据合并到同一行
-- - 使用COALESCE处理空值，确保数据完整性
-- - 结果按统计月份降序排列，最新月份在前
-- - 适配Presto环境：日期时间字段为VARCHAR类型，无需类型转换
--
-- 死亡患者定义：
-- 根据病案首页离院方式判断，包含"死亡"或"亡"字样的患者
-- 死亡率 = 死亡患者人数 / 手术患者总人数 × 100%
--
-- 意义：反映手术分级管理的合理性，评估不同级别手术的死亡风险差异
-- 四级手术与三级手术患者死亡率比 = 四级手术患者死亡率 ÷ 三级手术患者死亡率