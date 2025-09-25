-- 三级手术并发症发生率和四级手术并发症发生率指标（按月统计）
-- 定义：分别计算三级手术并发症发生率和四级手术并发症发生率
-- 计算公式：
-- 四级手术并发症发生率 = 四级手术并发症发生人数 / 四级手术患者总人数 × 100%
-- 三级手术并发症发生率 = 三级手术并发症发生人数 / 三级手术患者总人数 × 100%
-- 按月统计每个月数据，给出分子分母
-- 数据范围：2024年和2025年

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
        fp."MR_FP_PersName" AS "患者姓名"

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

-- 并发症诊断数据（从Visit_Diag表获取）
complication_diagnosis_data AS (
    SELECT
        diag."Visit_Diag_VisitID",
        diag."Visit_Diag_DiagICDCode" AS "诊断ICD代码",
        diag."Visit_Diag_HospDiagDesc" AS "诊断描述",
        diag."Visit_Diag_DiagTypeName" AS "诊断类型名称",
        1 AS "并发症标识"

    FROM datacenter_db.Visit_Diag diag
    
    WHERE diag."Visit_Diag_IsDeleted" = '0'                     -- 逻辑删除筛选
        AND (
            diag."Visit_Diag_DiagICDCode" IN (
                'I26', 'I80.1', 'I80.2', 'I82.8', 'A40', 'A41', 'T81.411', 'B37.7', 'B49.x00x019', 
                'T81.0', 'T81.3', 'R96.0', 'R96.1', 'I46.1', 'J95.800x004', 'E89', 'T81.4', 'T81.5', 
                'T81.6', 'T88.2', 'T88.3', 'T88.4', 'T88.5', 'J95.1', 'J95.2', 'J95.3', 'J95.4', 
                'J95.8', 'J95.9', 'J98.4', 'J15', 'J16', 'J18', 'T81.2', 'N17', 'N99.0', 'K91', 
                'I97.0', 'I97.1', 'I97.8', 'I97.9', 'G97.0', 'G97.1', 'G97.2', 'G97.8', 'G97.9', 
                'I60', 'I61', 'I62', 'I63', 'I64', 'H59.0', 'H59.8', 'H59.9', 'H95.0', 'H95.1', 
                'H95.8', 'H95.9', 'M96', 'N98', 'N99', 'K11.4', 'T86', 'T87.0', 'T87.1', 'T87.2', 
                'T87.3', 'T87.4', 'T87.5', 'T87.6', 'T81.1', 'T81.7', 'T81.8', 'T81.9'
            )
          
        )
),

-- 手术患者并发症统计
surgery_complication_data AS (
    SELECT
        surg."统计月份",
        surg."MR_FPOPS_VisitID",
        surg."MR_FPOPS_MROPSID",
        surg."手术级别代码",
        surg."手术级别名称",
        surg."手术名称",
        surg."患者姓名",
        COALESCE(MAX(comp."并发症标识"), 0) AS "并发症标识"  -- 患者是否有并发症（一个患者可能有多个诊断）

    FROM base_surgery_data surg
    LEFT JOIN complication_diagnosis_data comp ON surg."MR_FPOPS_VisitID" = comp."Visit_Diag_VisitID"
    
    GROUP BY surg."统计月份", surg."MR_FPOPS_VisitID", surg."MR_FPOPS_MROPSID", 
             surg."手术级别代码", surg."手术级别名称", surg."手术名称", surg."患者姓名"
),

-- 按月按手术级别统计数据
monthly_surgery_stats AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        COUNT(DISTINCT "MR_FPOPS_MROPSID") AS "手术患者总人数",
        SUM("并发症标识") AS "并发症发生人数"
    FROM surgery_complication_data
    GROUP BY "统计月份", "手术级别代码", "手术级别名称"
),

-- 计算各级别手术并发症发生率
monthly_complication_rates AS (
    SELECT
        "统计月份",
        "手术级别代码",
        "手术级别名称",
        "手术患者总人数",
        "并发症发生人数",
        CASE
            WHEN "手术患者总人数" > 0 THEN
                ROUND(
                    CAST("并发症发生人数" AS DOUBLE) / CAST("手术患者总人数" AS DOUBLE) * 100,
                    4
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
        MAX(CASE WHEN "手术级别代码" = '3' THEN "手术患者总人数" END) AS "三级手术患者总人数",
        MAX(CASE WHEN "手术级别代码" = '3' THEN "并发症发生人数" END) AS "三级手术并发症发生人数",
        MAX(CASE WHEN "手术级别代码" = '3' THEN "并发症发生率(%)" END) AS "三级手术并发症发生率(%)",
        -- 四级手术数据
        MAX(CASE WHEN "手术级别代码" = '4' THEN "手术患者总人数" END) AS "四级手术患者总人数",
        MAX(CASE WHEN "手术级别代码" = '4' THEN "并发症发生人数" END) AS "四级手术并发症发生人数",
        MAX(CASE WHEN "手术级别代码" = '4' THEN "并发症发生率(%)" END) AS "四级手术并发症发生率(%)"
    FROM monthly_complication_rates
    GROUP BY "统计月份"
)

-- 最终结果输出
SELECT
    "统计月份",
    -- 三级手术数据
    COALESCE("三级手术患者总人数", 0) AS "三级手术患者总人数",
    COALESCE("三级手术并发症发生人数", 0) AS "三级手术并发症发生人数",
    COALESCE("三级手术并发症发生率(%)", 0) AS "三级手术并发症发生率(%)",
    -- 四级手术数据  
    COALESCE("四级手术患者总人数", 0) AS "四级手术患者总人数",
    COALESCE("四级手术并发症发生人数", 0) AS "四级手术并发症发生人数",
    COALESCE("四级手术并发症发生率(%)", 0) AS "四级手术并发症发生率(%)",
    -- 修正后的比例计算 - 四级手术并发症发生率 ÷ 三级手术并发症发生率
    CASE
        WHEN COALESCE("三级手术并发症发生率(%)", 0) > 0 THEN
            ROUND(
                CAST(COALESCE("四级手术并发症发生率(%)", 0) AS DOUBLE) / 
                CAST("三级手术并发症发生率(%)" AS DOUBLE),
                4
            )
        ELSE NULL
    END AS "四级与三级手术并发症发生率比",
    -- 分子分母说明
    CONCAT(
        '四级手术并发症发生率：',
        CAST(COALESCE("四级手术并发症发生率(%)", 0) AS VARCHAR),
        '% (', CAST(COALESCE("四级手术并发症发生人数", 0) AS VARCHAR), '/', 
        CAST(COALESCE("四级手术患者总人数", 0) AS VARCHAR), ')',
        '；三级手术并发症发生率：',
        CAST(COALESCE("三级手术并发症发生率(%)", 0) AS VARCHAR),
        '% (', CAST(COALESCE("三级手术并发症发生人数", 0) AS VARCHAR), '/', 
        CAST(COALESCE("三级手术患者总人数", 0) AS VARCHAR), ')'
    ) AS "计算说明"
FROM monthly_summary
WHERE "统计月份" IS NOT NULL
    AND ("三级手术患者总人数" > 0 OR "四级手术患者总人数" > 0)  -- 至少有一种级别的手术
ORDER BY "统计月份" DESC;