-- 四级手术与三级手术并发症发生率比指标（按月统计）
-- 定义：四级手术并发症发生率与三级手术并发症发生率的比
-- 计算公式：四级手术与三级手术并发症发生率比 = 四级手术并发症发生率 : 三级手术并发症发生率
-- 四级手术并发症发生率 = 四级手术并发症发生例数 / 四级手术总例数 × 100%
-- 三级手术并发症发生率 = 三级手术并发症发生例数 / 三级手术总例数 × 100%
-- 按月统计每个月数据

WITH
-- 基础住院患者手术数据
base_inpatient_surgeries AS (
    SELECT
        SUBSTRING(ip."Visit_IPReg_OutHospDtTm", 1, 7) AS "统计月份",
        ops."MR_FPOPS_VisitID",
        ops."MR_FPOPS_MROPSID",
        ops."MR_FPOPS_OPSLevelCode" AS "手术级别代码",
        ops."MR_FPOPS_OPSLevelName" AS "手术级别名称",
        ops."MR_FPOPS_PlanOPSName" AS "手术名称",
        -- 根据并发症描述判断是否有并发症（描述不为空且不是"无"、"否"等表示）
        CASE 
            WHEN fp."MR_FP_OPSComplicationDesc" IS NOT NULL 
                AND fp."MR_FP_OPSComplicationDesc" != '' 
                AND fp."MR_FP_OPSComplicationDesc" NOT IN ('无', '否', '未发现', '无并发症', '/') 
            THEN '1' 
            ELSE '0' 
        END AS "手术并发症标识",
        fp."MR_FP_OPSComplicationDesc" AS "手术并发症描述"
    FROM datacenter_db.MR_FPOPS ops
    INNER JOIN datacenter_db.Visit_IPReg ip ON ops."MR_FPOPS_VisitID" = ip."Visit_IPReg_VisitID"
    INNER JOIN datacenter_db.MR_FP fp ON ops."MR_FPOPS_VisitID" = fp."MR_FP_VisitID"
    WHERE ip."Visit_IPReg_OutHospDtTm" IS NOT NULL      -- 已出院患者
        AND ip."Visit_IPReg_OutHospDtTm" != ''          -- 出院时间不为空字符串
        AND ops."MR_FPOPS_OPSLevelCode" IS NOT NULL     -- 手术级别不为空
        AND ops."MR_FPOPS_OPSLevelCode" != ''           -- 手术级别不为空字符串
        AND ops."MR_FPOPS_OPSLevelCode" IN ('3', '4')   -- 只统计三级和四级手术
        AND ops."MR_FPOPS_IsDeleted" = '0'              -- 逻辑删除筛选
        AND ip."Visit_IPReg_IsDeleted" = '0'            -- 住院登记逻辑删除筛选
        AND fp."MR_FP_IsDeleted" = '0'                  -- 病案首页逻辑删除筛选
),

-- 按月按手术级别统计数据
monthly_surgery_stats AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        COUNT(DISTINCT "MR_FPOPS_MROPSID") AS "手术总例数",
        COUNT(DISTINCT 
            CASE WHEN "手术并发症标识" = '1' THEN "MR_FPOPS_MROPSID" END
        ) AS "并发症发生例数"
    FROM base_inpatient_surgeries
    GROUP BY "统计月份", "手术级别代码", "手术级别名称"
),

-- 计算各级别手术并发症发生率
monthly_complication_rates AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        "手术总例数",
        "并发症发生例数",
        CASE 
            WHEN "手术总例数" > 0 THEN 
                ROUND(
                    CAST("并发症发生例数" AS DOUBLE) / CAST("手术总例数" AS DOUBLE) * 100, 
                    2
                )
            ELSE 0 
        END AS "并发症发生率(%)"
    FROM monthly_surgery_stats
),

-- 汇总三级和四级手术数据
monthly_summary AS (
    SELECT
        "统计月份",
        -- 三级手术数据
        MAX(CASE WHEN "手术级别代码" = '3' THEN "手术总例数" END) AS "三级手术总例数",
        MAX(CASE WHEN "手术级别代码" = '3' THEN "并发症发生例数" END) AS "三级手术并发症发生例数",
        MAX(CASE WHEN "手术级别代码" = '3' THEN "并发症发生率(%)" END) AS "三级手术并发症发生率(%)",
        -- 四级手术数据
        MAX(CASE WHEN "手术级别代码" = '4' THEN "手术总例数" END) AS "四级手术总例数",
        MAX(CASE WHEN "手术级别代码" = '4' THEN "并发症发生例数" END) AS "四级手术并发症发生例数",
        MAX(CASE WHEN "手术级别代码" = '4' THEN "并发症发生率(%)" END) AS "四级手术并发症发生率(%)"
    FROM monthly_complication_rates
    GROUP BY "统计月份"
)

-- 最终结果输出
SELECT
    "统计月份",
    -- 三级手术数据
    COALESCE("三级手术总例数", 0) AS "分母_三级手术总例数",
    COALESCE("三级手术并发症发生例数", 0) AS "分子_三级手术并发症发生例数", 
    COALESCE("三级手术并发症发生率(%)", 0) AS "三级手术并发症发生率(%)",
    -- 四级手术数据
    COALESCE("四级手术总例数", 0) AS "分母_四级手术总例数",
    COALESCE("四级手术并发症发生例数", 0) AS "分子_四级手术并发症发生例数",
    COALESCE("四级手术并发症发生率(%)", 0) AS "四级手术并发症发生率(%)",
    -- 发生率比值
    CASE 
        WHEN COALESCE("三级手术并发症发生率(%)", 0) > 0 THEN 
            ROUND(
                COALESCE("四级手术并发症发生率(%)", 0) / "三级手术并发症发生率(%)", 
                2
            )
        ELSE NULL 
    END AS "四级与三级手术并发症发生率比",
    CONCAT(
        '四级手术并发症发生率：', 
        CAST(COALESCE("四级手术并发症发生率(%)", 0) AS VARCHAR), 
        '%；三级手术并发症发生率：', 
        CAST(COALESCE("三级手术并发症发生率(%)", 0) AS VARCHAR), 
        '%'
    ) AS "计算说明"
FROM monthly_summary
WHERE "统计月份" IS NOT NULL
    AND ("三级手术总例数" > 0 OR "四级手术总例数" > 0)  -- 至少有一种级别的手术
ORDER BY "统计月份" DESC

-- 数据来源说明：
-- 1. 手术数据：MR_FPOPS 病案首页手术表
-- 2. 并发症数据：MR_FP 病案首页表的手术并发症标识
-- 3. 住院患者：通过Visit_IPReg住院登记表关联筛选
-- 4. 月份统计：基于Visit_IPReg_OutHospDtTm出院时间进行分组
--
-- 字段血缘关系：
-- - 手术级别：MR_FPOPS.MR_FPOPS_OPSLevelCode（VARCHAR，3=三级，4=四级）
-- - 手术级别名称：MR_FPOPS.MR_FPOPS_OPSLevelName（VARCHAR）
-- - 并发症标识：通过MR_FP.MR_FP_OPSComplicationDesc字段计算得出（有效描述=1，无效或空=0）
-- - 并发症描述：MR_FP.MR_FP_OPSComplicationDesc（VARCHAR）
-- - 出院时间：Visit_IPReg.Visit_IPReg_OutHospDtTm（VARCHAR，用于月份统计）
-- - 关联字段：MR_FPOPS.MR_FPOPS_VisitID = MR_FP.MR_FP_VisitID = Visit_IPReg.Visit_IPReg_VisitID
--
-- 关键技术要点：
-- - 使用SUBSTRING(出院时间, 1, 7)进行月份分组统计（日期字段为VARCHAR类型）
-- - 中文字段名使用双引号包围适配Presto语法
-- - 使用CASE WHEN进行条件统计，分别计算三级和四级手术数据
-- - 通过MAX聚合函数将三级四级手术数据合并到同一行
-- - 使用COALESCE处理空值，确保数据完整性
-- - 结果按统计月份降序排列，最新月份在前
-- - 适配Presto环境：日期时间字段为VARCHAR类型，无需类型转换
--
-- 手术并发症定义：
-- 包括但不限于：手术后肺栓塞、深静脉血栓、脓毒症、出血或血肿、伤口裂开、
-- 呼吸衰竭、生理/代谢紊乱、与手术/操作相关感染、手术过程中异物遗留、
-- 手术患者麻醉并发症、肺部感染与肺机能不全、手术意外穿刺伤或撕裂伤、
-- 手术后急性肾衰竭等
--
-- 意义：反映手术分级管理的合理性，评估不同级别手术的风险差异 