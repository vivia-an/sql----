-- 三、四级手术实际开展率指标（按月统计）
-- 定义：实际开展的三、四级手术术种数占同期备案的三、四级手术术种数的比例
-- 计算公式：三、四级手术实际开展率 = 实际开展的三、四级手术术种数 ÷ 同期备案的三、四级手术术种数 × 100%
-- 按月统计每个月数据，给出分子分母

WITH
-- 实际开展的三、四级手术术种统计（按月）
actual_surgery_types AS (
    SELECT
        SUBSTRING(CAST(ops."MR_FPOPS_OPSDtTm" AS VARCHAR), 1, 7) AS "统计月份",
        ops."MR_FPOPS_OPSLevelCode" AS "手术级别代码",
        ops."MR_FPOPS_OPSLevelName" AS "手术级别名称",
        -- 按手术名称统计术种数（去重）
        ops."MR_FPOPS_PlanOPSName" AS "手术术种名称",
        -- 也可以按手术编码统计（如果有的话）
        ops."MR_FPOPS_OPSCode" AS "手术术种代码",
        COUNT(DISTINCT ops."MR_FPOPS_MROPSID") AS "该术种手术例数"

    FROM datacenter_db.MR_FPOPS ops
    INNER JOIN datacenter_db.MR_FP fp ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"

    WHERE ops."MR_FPOPS_OPSDtTm" IS NOT NULL                    -- 手术时间不为空
        AND ops."MR_FPOPS_OPSLevelCode" IN ('3', '4')          -- 只统计三级和四级手术
        AND ops."MR_FPOPS_PlanOPSName" IS NOT NULL             -- 手术名称不为空
        AND ops."MR_FPOPS_PlanOPSName" != ''                   -- 手术名称不为空字符串
        AND ops."MR_FPOPS_IsDeleted" = '0'                     -- 逻辑删除筛选
        AND fp."MR_FP_IsDeleted" = '0'                         -- 病案首页逻辑删除筛选

    GROUP BY
        SUBSTRING(CAST(ops."MR_FPOPS_OPSDtTm" AS VARCHAR), 1, 7),
        ops."MR_FPOPS_OPSLevelCode",
        ops."MR_FPOPS_OPSLevelName",
        ops."MR_FPOPS_PlanOPSName",
        ops."MR_FPOPS_OPSCode"
),

-- 按月按手术级别汇总实际开展术种数
monthly_actual_stats AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        COUNT(DISTINCT "手术术种名称") AS "实际开展术种数",
        SUM("该术种手术例数") AS "手术总例数"
    FROM actual_surgery_types
    GROUP BY "统计月份", "手术级别代码", "手术级别名称"
),

-- *** 重要提示：备案术种数据需要补充 ***
-- 备案的三、四级手术术种数据（需要从手术管理目录表中获取）
-- 这部分数据可能存储在以下可能的表中：
-- 1. 手术权限管理表
-- 2. 医疗机构手术目录表
-- 3. 科室手术授权表
-- 4. 手术分级管理表
registered_surgery_types AS (
    -- 临时方案：假设所有在数据库中出现过的术种都是备案的
    -- 实际应用中需要替换为真实的备案数据表
    SELECT
        "手术级别代码",
        "手术级别名称",
        COUNT(DISTINCT "手术术种名称") AS "备案术种数"
    FROM (
        SELECT DISTINCT
            ops."MR_FPOPS_OPSLevelCode" AS "手术级别代码",
            ops."MR_FPOPS_OPSLevelName" AS "手术级别名称",
            ops."MR_FPOPS_PlanOPSName" AS "手术术种名称"
        FROM datacenter_db.MR_FPOPS ops
        WHERE ops."MR_FPOPS_OPSLevelCode" IN ('3', '4')
            AND ops."MR_FPOPS_PlanOPSName" IS NOT NULL
            AND ops."MR_FPOPS_PlanOPSName" != ''
            AND ops."MR_FPOPS_IsDeleted" = '0'
    ) all_surgery_types
    GROUP BY "手术级别代码", "手术级别名称"
),

-- 汇总三级和四级手术数据
monthly_summary AS (
    SELECT
        mas."统计月份",
        -- 三级手术数据
        MAX(CASE WHEN mas."手术级别代码" = '3' THEN mas."实际开展术种数" END) AS "三级手术实际开展术种数",
        MAX(CASE WHEN mas."手术级别代码" = '3' THEN mas."手术总例数" END) AS "三级手术总例数",
        MAX(CASE WHEN rst."手术级别代码" = '3' THEN rst."备案术种数" END) AS "三级手术备案术种数",
        -- 四级手术数据
        MAX(CASE WHEN mas."手术级别代码" = '4' THEN mas."实际开展术种数" END) AS "四级手术实际开展术种数",
        MAX(CASE WHEN mas."手术级别代码" = '4' THEN mas."手术总例数" END) AS "四级手术总例数",
        MAX(CASE WHEN rst."手术级别代码" = '4' THEN rst."备案术种数" END) AS "四级手术备案术种数"
    FROM monthly_actual_stats mas
    CROSS JOIN registered_surgery_types rst
    GROUP BY mas."统计月份"
)

-- 最终结果输出
SELECT
    "统计月份",
    -- 三级手术数据
    COALESCE("三级手术实际开展术种数", 0) AS "分子_三级手术实际开展术种数",
    COALESCE("三级手术备案术种数", 0) AS "分母_三级手术备案术种数",
    COALESCE("三级手术总例数", 0) AS "三级手术总例数",
    CASE
        WHEN COALESCE("三级手术备案术种数", 0) > 0 THEN
            ROUND(
                CAST(COALESCE("三级手术实际开展术种数", 0) AS DOUBLE) / CAST("三级手术备案术种数" AS DOUBLE) * 100,
                2
            )
        ELSE 0
    END AS "三级手术实际开展率(%)",

    -- 四级手术数据
    COALESCE("四级手术实际开展术种数", 0) AS "分子_四级手术实际开展术种数",
    COALESCE("四级手术备案术种数", 0) AS "分母_四级手术备案术种数",
    COALESCE("四级手术总例数", 0) AS "四级手术总例数",
    CASE
        WHEN COALESCE("四级手术备案术种数", 0) > 0 THEN
            ROUND(
                CAST(COALESCE("四级手术实际开展术种数", 0) AS DOUBLE) / CAST("四级手术备案术种数" AS DOUBLE) * 100,
                2
            )
        ELSE 0
    END AS "四级手术实际开展率(%)",

    -- 整体三、四级手术开展率
    CASE
        WHEN (COALESCE("三级手术备案术种数", 0) + COALESCE("四级手术备案术种数", 0)) > 0 THEN
            ROUND(
                CAST(COALESCE("三级手术实际开展术种数", 0) + COALESCE("四级手术实际开展术种数", 0) AS DOUBLE)
                / CAST(COALESCE("三级手术备案术种数", 0) + COALESCE("四级手术备案术种数", 0) AS DOUBLE) * 100,
                2
            )
        ELSE 0
    END AS "三四级手术整体实际开展率(%)",

    CONCAT(
        '三级：实际', CAST(COALESCE("三级手术实际开展术种数", 0) AS VARCHAR),
        '/备案', CAST(COALESCE("三级手术备案术种数", 0) AS VARCHAR),
        '；四级：实际', CAST(COALESCE("四级手术实际开展术种数", 0) AS VARCHAR),
        '/备案', CAST(COALESCE("四级手术备案术种数", 0) AS VARCHAR)
    ) AS "计算说明"

FROM monthly_summary
WHERE "统计月份" IS NOT NULL
    AND ("三级手术实际开展术种数" > 0 OR "四级手术实际开展术种数" > 0)  -- 至少有一种级别的手术
ORDER BY "统计月份" DESC

-- *** 重要说明：备案数据源需要确认 ***
--
-- 当前SQL中的备案术种数使用的是临时方案，实际应用中需要替换为真实的备案数据源。
--
-- 可能的备案数据表包括：
-- 1. 医疗机构手术分级管理目录表
-- 2. 科室手术权限表
-- 3. 医师手术授权表
-- 4. 手术准入管理表
--
-- 请提供备案数据的具体表名和字段结构，以便完善此查询。
--
-- 数据来源说明：
-- 1. 实际开展手术数据：MR_FPOPS 病案首页手术表
-- 2. 备案手术数据：【待补充 - 需要确认备案数据表】
-- 3. 月份统计：基于MR_FPOPS_OPSDtTm手术时间进行分组
--
-- 字段血缘关系：
-- - 手术级别：MR_FPOPS.MR_FPOPS_OPSLevelCode（VARCHAR，3=三级，4=四级）
-- - 手术级别名称：MR_FPOPS.MR_FPOPS_OPSLevelName（VARCHAR）
-- - 手术术种名称：MR_FPOPS.MR_FPOPS_PlanOPSName（VARCHAR，用于术种去重统计）
-- - 手术术种代码：MR_FPOPS.MR_FPOPS_OPSCode（VARCHAR，备用标识）
-- - 手术时间：MR_FPOPS.MR_FPOPS_OPSDtTm（VARCHAR，用于月份统计）
-- - 关联字段：MR_FPOPS.MR_FPOPS_VisitID = MR_FP.MR_FP_VisitID
--
-- 关键技术要点：
-- - 使用SUBSTRING(手术时间, 1, 7)进行月份分组统计（日期字段为VARCHAR类型）
-- - 中文字段名使用双引号包围适配Presto语法
-- - 使用DISTINCT按手术名称去重统计术种数，而非手术例数
-- - 使用CASE WHEN分别计算三级和四级手术数据
-- - 通过MAX聚合函数将三级四级手术数据合并到同一行
-- - 使用COALESCE处理空值，确保数据完整性
-- - 结果按统计月份降序排列，最新月份在前
--
-- 术种统计说明：
-- - 实际开展术种数：按手术名称（MR_FPOPS_PlanOPSName）去重统计
-- - 备案术种数：需要从手术管理目录或权限表中获取
-- - 开展率 = 实际开展术种数 ÷ 备案术种数 × 100%
--
-- 意义：反映手术分级管理的合理性，评估医疗机构手术能力与备案资质的匹配程度

-- *** 待解决问题 ***
-- 1. 备案手术术种数据的具体来源表和字段
-- 2. 确认术种的唯一标识方式（手术名称 vs 手术代码）
-- 3. 确认备案数据的时间范围和更新频率
-- 4. 是否需要按科室或医师维度进行更细粒度的统计