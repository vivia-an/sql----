-- 四级手术与三级手术患者死亡率比指标（按月统计）
-- 定义：分别计算三级手术死亡率和四级手术死亡率，并计算比值
-- 计算公式：
-- 四级手术死亡率 = 四级手术死亡人数 / 四级手术患者总人数 × 100%
-- 三级手术死亡率 = 三级手术死亡人数 / 三级手术患者总人数 × 100%
-- 四级与三级手术死亡率比 = 四级手术死亡率 ÷ 三级手术死亡率
-- 按月统计每个月数据，给出分子分母
-- 数据范围：2024年和2025年
-- 死亡判断逻辑：使用LIKE模糊匹配离院方式中包含"死亡"或"亡"的情况

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
        fp."MR_FP_PersName" AS "患者姓名",

        -- 死亡标识：使用LIKE模糊匹配（参考验证过的逻辑）
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
        AND (
            SUBSTRING(CAST(ops."MR_FPOPS_OPSDtTm" AS VARCHAR), 1, 4) = '2024'  -- 2024年
            OR SUBSTRING(CAST(ops."MR_FPOPS_OPSDtTm" AS VARCHAR), 1, 4) = '2025'  -- 2025年
        )
),

-- 手术患者死亡统计（按月按级别统计）
monthly_surgery_stats AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        COUNT(DISTINCT "MR_FPOPS_MROPSID") AS "手术患者总人数",
        SUM("死亡标识") AS "死亡人数"
    FROM base_surgery_data
    GROUP BY "统计月份", "手术级别代码", "手术级别名称"
),

-- 计算各级别手术死亡率
monthly_mortality_rates AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        "手术患者总人数",
        "死亡人数",
        CASE
            WHEN "手术患者总人数" > 0 THEN
                ROUND(
                    CAST("死亡人数" AS DOUBLE) / CAST("手术患者总人数" AS DOUBLE) * 100,
                    4
                )
            ELSE 0
        END AS "死亡率(%)"
    FROM monthly_surgery_stats
),

-- 汇总三级和四级手术数据
monthly_summary AS (
    SELECT
        "统计月份",
        -- 三级手术数据
        MAX(CASE WHEN "手术级别代码" = '3' THEN "手术患者总人数" END) AS "三级手术患者总人数",
        MAX(CASE WHEN "手术级别代码" = '3' THEN "死亡人数" END) AS "三级手术死亡人数",
        MAX(CASE WHEN "手术级别代码" = '3' THEN "死亡率(%)" END) AS "三级手术死亡率(%)",
        -- 四级手术数据
        MAX(CASE WHEN "手术级别代码" = '4' THEN "手术患者总人数" END) AS "四级手术患者总人数",
        MAX(CASE WHEN "手术级别代码" = '4' THEN "死亡人数" END) AS "四级手术死亡人数",
        MAX(CASE WHEN "手术级别代码" = '4' THEN "死亡率(%)" END) AS "四级手术死亡率(%)"
    FROM monthly_mortality_rates
    GROUP BY "统计月份"
)

-- 最终结果输出
SELECT
    "统计月份",
    -- 三级手术数据（分子分母）
    COALESCE("三级手术患者总人数", 0) AS "三级手术患者总人数（分母）",
    COALESCE("三级手术死亡人数", 0) AS "三级手术死亡人数（分子）",
    COALESCE("三级手术死亡率(%)", 0.00) AS "三级手术死亡率(%)",
    -- 四级手术数据（分子分母）
    COALESCE("四级手术患者总人数", 0) AS "四级手术患者总人数（分母）",
    COALESCE("四级手术死亡人数", 0) AS "四级手术死亡人数（分子）",
    COALESCE("四级手术死亡率(%)", 0.00) AS "四级手术死亡率(%)",
    -- 死亡率比值计算（用计算出的死亡率数值直接相除）
    CASE
        WHEN COALESCE("三级手术死亡率(%)", 0) > 0 THEN
            ROUND(
                COALESCE("四级手术死亡率(%)", 0.00) / COALESCE("三级手术死亡率(%)", 0.01),
                4
            )
        ELSE NULL
    END AS "四级与三级手术死亡率比",
    -- 计算公式说明
    CONCAT(
        '三级手术死亡率：', CAST(COALESCE("三级手术死亡人数", 0) AS VARCHAR), '/',
        CAST(COALESCE("三级手术患者总人数", 0) AS VARCHAR), ' = ',
        CAST(COALESCE("三级手术死亡率(%)", 0) AS VARCHAR), '%',
        '；四级手术死亡率：', CAST(COALESCE("四级手术死亡人数", 0) AS VARCHAR), '/',
        CAST(COALESCE("四级手术患者总人数", 0) AS VARCHAR), ' = ',
        CAST(COALESCE("四级手术死亡率(%)", 0) AS VARCHAR), '%'
    ) AS "计算公式说明"
FROM monthly_summary
WHERE "统计月份" IS NOT NULL
    AND ("三级手术患者总人数" > 0 OR "四级手术患者总人数" > 0)  -- 至少有一种级别的手术
ORDER BY "统计月份" DESC;

-- 字段来源说明：
-- 1. 手术时间：MR_FPOPS.MR_FPOPS_OPSDtTm (用于月份统计)
-- 2. 手术级别：MR_FPOPS.MR_FPOPS_OPSLevelCode ('3'=三级, '4'=四级)
-- 3. 死亡标识：MR_FP.MR_FP_OutHospModeName/MR_FP_OutHospModeCode LIKE '%死亡%' OR LIKE '%亡%'
-- 4. 关联关系：MR_FPOPS.MR_FPOPS_VisitID = MR_FP.MR_FP_VisitID
-- 5. 所有字段均来源于datacenter_db库中的MR_FPOPS和MR_FP表