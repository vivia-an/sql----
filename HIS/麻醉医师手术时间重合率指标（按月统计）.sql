-- 麻醉医师手术时间重合率指标（按月统计）
-- 计算公式：同一时间内手术麻醉医师为同一人的手术例数/同期住院患者手术总例数×100%
-- 分子：手术开始到手术结束，手术麻醉医师重叠的手术例数
-- 分母：同期住院患者手术总例数
-- 按月统计每个月数据

WITH
-- 基础住院患者手术数据（分母）
base_inpatient_surgeries AS (
    SELECT
        SUBSTRING("OPS_EventMainRecord_OPSBeginDtTm", 1, 7) AS "统计月份",
        ops."OPS_EventMainRecord_VisitID",
        ops."OPS_EventMainRecord_OPSEventID",
        ops."OPS_EventMainRecord_NarcosisDoctCode" AS "麻醉医师代码",
        ops."OPS_EventMainRecord_NarcosisDoctName" AS "麻醉医师姓名", 
        ops."OPS_EventMainRecord_OPSBeginDtTm" AS "手术开始时间",
        ops."OPS_EventMainRecord_OPSEndDtTm" AS "手术结束时间",
        ops."OPS_EventMainRecord_PlanOPSName" AS "手术名称"
    FROM datacenter_db.OPS_EventMainRecord ops
    INNER JOIN datacenter_db.Visit_IPReg ip ON ops."OPS_EventMainRecord_VisitID" = ip."Visit_IPReg_VisitID"
    WHERE ops."OPS_EventMainRecord_OPSBeginDtTm" IS NOT NULL  -- 手术开始时间不为空
        AND ops."OPS_EventMainRecord_OPSBeginDtTm" != ''      -- 手术开始时间不为空字符串
        AND ops."OPS_EventMainRecord_OPSEndDtTm" IS NOT NULL  -- 手术结束时间不为空
        AND ops."OPS_EventMainRecord_OPSEndDtTm" != ''        -- 手术结束时间不为空字符串
        AND ops."OPS_EventMainRecord_NarcosisDoctCode" IS NOT NULL   -- 麻醉医师代码不为空
        AND ops."OPS_EventMainRecord_NarcosisDoctCode" != ''         -- 麻醉医师代码不为空字符串
        AND ops."OPS_EventMainRecord_IsDeleted" = '0'         -- 逻辑删除筛选 
        AND ip."Visit_IPReg_IsDeleted" = '0'                  -- 住院登记逻辑删除筛选
),

-- 找出同一麻醉医师时间重合的手术（分子）
overlapping_surgeries AS (
    SELECT DISTINCT
        b1."统计月份",
        b1."OPS_EventMainRecord_VisitID",
        b1."OPS_EventMainRecord_OPSEventID"
    FROM base_inpatient_surgeries b1
    INNER JOIN base_inpatient_surgeries b2 ON (
        b1."麻醉医师代码" = b2."麻醉医师代码"                                -- 同一麻醉医师（使用医师代码）
        AND b1."OPS_EventMainRecord_OPSEventID" != b2."OPS_EventMainRecord_OPSEventID"  -- 不同手术
        AND b1."统计月份" = b2."统计月份"                                     -- 同一统计月份
        -- 时间重合判断：手术A未结束时间 > 手术B开始时间 且 手术A开始时间 < 手术B结束时间
        AND b1."手术开始时间" < b2."手术结束时间"
        AND b1."手术结束时间" > b2."手术开始时间"
    )
),

-- 按月统计数据
monthly_stats AS (
    SELECT
        base."统计月份",
        COUNT(DISTINCT base."OPS_EventMainRecord_OPSEventID") AS "住院患者手术总例数",
        COUNT(DISTINCT overlap."OPS_EventMainRecord_OPSEventID") AS "麻醉医师时间重合例数"
    FROM base_inpatient_surgeries base
    LEFT JOIN overlapping_surgeries overlap ON (
        base."统计月份" = overlap."统计月份"
        AND base."OPS_EventMainRecord_OPSEventID" = overlap."OPS_EventMainRecord_OPSEventID"
    )
    GROUP BY base."统计月份"
)

-- 最终结果输出
SELECT
    "统计月份",
    "住院患者手术总例数" AS "分母_住院患者手术总例数",
    "麻醉医师时间重合例数" AS "分子_麻醉医师时间重合例数",
    CASE 
        WHEN "住院患者手术总例数" > 0 THEN 
            ROUND(
                CAST("麻醉医师时间重合例数" AS DOUBLE) / CAST("住院患者手术总例数" AS DOUBLE) * 100, 
                2
            )
        ELSE 0 
    END AS "麻醉医师手术时间重合率(%)",
    CONCAT(
        '分子：同一时间内手术麻醉医师为同一人的手术例数 ', 
        CAST("麻醉医师时间重合例数" AS VARCHAR), 
        ' 例；分母：住院患者手术总例数 ', 
        CAST("住院患者手术总例数" AS VARCHAR), 
        ' 例'
    ) AS "计算说明"
FROM monthly_stats
WHERE "统计月份" IS NOT NULL
ORDER BY "统计月份" DESC;

-- 数据来源说明：
-- 1. 分母：OPS_EventMainRecord 手术事件主记录表 关联 Visit_IPReg 住院登记表
-- 2. 分子：基于手术开始时间和结束时间判断同一麻醉医师的时间重合情况
-- 3. 关键字段：OPS_EventMainRecord_NarcosisDoctCode（麻醉医师代码）、OPS_EventMainRecord_OPSBeginDtTm（开始时间）、OPS_EventMainRecord_OPSEndDtTm（结束时间）
-- 
-- 字段血缘关系：
-- - 麻醉医师代码：OPS_EventMainRecord.OPS_EventMainRecord_NarcosisDoctCode（VARCHAR）
-- - 麻醉医师姓名：OPS_EventMainRecord.OPS_EventMainRecord_NarcosisDoctName（VARCHAR） 
-- - 手术开始时间：OPS_EventMainRecord.OPS_EventMainRecord_OPSBeginDtTm（VARCHAR）
-- - 手术结束时间：OPS_EventMainRecord.OPS_EventMainRecord_OPSEndDtTm（VARCHAR）
-- - 就诊ID关联：OPS_EventMainRecord.OPS_EventMainRecord_VisitID = Visit_IPReg.Visit_IPReg_VisitID
-- 
-- 关键技术要点：
-- - 使用SUBSTRING(手术开始时间, 1, 7)进行月份分组统计（日期字段为VARCHAR类型）
-- - 中文字段名使用双引号包围适配Presto语法
-- - 时间重合判断：手术A开始时间 < 手术B结束时间 AND 手术A结束时间 > 手术B开始时间
-- - 通过Visit_IPReg关联确保统计的是住院患者手术
-- - 使用CTE分步构建逻辑，提高可读性
-- - 结果按统计月份降序排列，最新月份在前
-- - 适配Presto环境：日期时间字段为VARCHAR类型，无需类型转换
-- 
-- 意义：反映麻醉医师参与手术安全核查情况，确保麻醉医师不会同时进行多台手术 