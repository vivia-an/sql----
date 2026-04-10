-- StarRocks LIS运管报表 - 同比环比统计
-- 数据来源：m1.transport_is_experimental（由DolphinScheduler单月任务写入）
-- 使用说明：修改 date_params 中的 stat_month 为需要统计的月份（格式：yyyy-MM，如 2025-10）
--
-- ==================== 血缘依赖说明 ====================
-- 数据来源表：m1.transport_is_experimental
-- 上游依赖：运管科lis报表整体_单月_dolphinscheduler.sql -> DataX -> m1.transport_is_experimental
-- 
-- 表字段结构：
--   统计月 (格式：2025年-10月)
--   运管科室 (实验医学科(检验科))
--   运管院区 (主院区/温江院区/锦江院区/天府医院/本部实际量/合计)
--   亚专业组 (临床免疫实验室/临床生化实验室/临床微生物实验室/...)
--   标本数, 项目数, 总收入
--   上月标本数, 上月项目数, 上月总收入 (单月版本为0)
--   去年同期标本数, 去年同期项目数, 去年同期总收入 (单月版本为0)
--   总收入占比%, 上月总收入占比%, 去年同期总收入占比%
--   标本数环比增长率%, 项目数环比增长率%, 收入环比增长率%
--   标本数同比增长率%, 项目数同比增长率%, 收入同比增长率%

WITH 
-- 日期参数（修改这里的 stat_month 即可）
date_params AS (
    SELECT 
        '2025-10' AS stat_month
),

-- 转换为表中存储的格式
date_labels AS (
    SELECT 
        CONCAT(SUBSTRING(stat_month, 1, 4), '年-', SUBSTRING(stat_month, 6, 2), '月') AS stat_month_label,
        DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(stat_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y年-%m月') AS last_month_label,
        DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(stat_month, '-01'), '%Y-%m-%d'), INTERVAL 12 MONTH), '%Y年-%m月') AS last_year_label
    FROM date_params
),

-- 当月数据
current_month AS (
    SELECT 
        t.`运管科室`,
        t.`运管院区`,
        t.`亚专业组`,
        t.`标本数` AS `本月标本数`,
        t.`项目数` AS `本月项目数`,
        t.`总收入` AS `本月总收入`
    FROM m1.transport_is_experimental t
    INNER JOIN date_labels d ON t.`统计月` = d.stat_month_label
),

-- 上月数据
last_month AS (
    SELECT 
        t.`运管科室`,
        t.`运管院区`,
        t.`亚专业组`,
        t.`标本数` AS `上月标本数`,
        t.`项目数` AS `上月项目数`,
        t.`总收入` AS `上月总收入`
    FROM m1.transport_is_experimental t
    INNER JOIN date_labels d ON t.`统计月` = d.last_month_label
),

-- 去年同期数据
last_year AS (
    SELECT 
        t.`运管科室`,
        t.`运管院区`,
        t.`亚专业组`,
        t.`标本数` AS `去年同期标本数`,
        t.`项目数` AS `去年同期项目数`,
        t.`总收入` AS `去年同期总收入`
    FROM m1.transport_is_experimental t
    INNER JOIN date_labels d ON t.`统计月` = d.last_year_label
),

-- 合并三期数据
merged_data AS (
    SELECT 
        COALESCE(c.`运管科室`, l.`运管科室`, y.`运管科室`) AS `运管科室`,
        COALESCE(c.`运管院区`, l.`运管院区`, y.`运管院区`) AS `运管院区`,
        COALESCE(c.`亚专业组`, l.`亚专业组`, y.`亚专业组`) AS `亚专业组`,
        COALESCE(c.`本月标本数`, 0) AS `本月标本数`,
        COALESCE(l.`上月标本数`, 0) AS `上月标本数`,
        COALESCE(y.`去年同期标本数`, 0) AS `去年同期标本数`,
        COALESCE(c.`本月项目数`, 0) AS `本月项目数`,
        COALESCE(l.`上月项目数`, 0) AS `上月项目数`,
        COALESCE(y.`去年同期项目数`, 0) AS `去年同期项目数`,
        COALESCE(c.`本月总收入`, 0) AS `本月总收入`,
        COALESCE(l.`上月总收入`, 0) AS `上月总收入`,
        COALESCE(y.`去年同期总收入`, 0) AS `去年同期总收入`
    FROM current_month c
    LEFT JOIN last_month l 
        ON c.`运管科室` = l.`运管科室` 
        AND c.`运管院区` = l.`运管院区` 
        AND c.`亚专业组` = l.`亚专业组`
    LEFT JOIN last_year y 
        ON c.`运管科室` = y.`运管科室` 
        AND c.`运管院区` = y.`运管院区` 
        AND c.`亚专业组` = y.`亚专业组`
),

-- 计算合计行的总收入（用于计算占比）
totals AS (
    SELECT 
        MAX(CASE WHEN `运管院区` = '合计' THEN `本月总收入` END) AS `本月总收入_合计`,
        MAX(CASE WHEN `运管院区` = '合计' THEN `上月总收入` END) AS `上月总收入_合计`,
        MAX(CASE WHEN `运管院区` = '合计' THEN `去年同期总收入` END) AS `去年同期总收入_合计`
    FROM merged_data
)

-- 最终结果
SELECT
    d.stat_month_label AS `统计月份`,
    m.`运管科室`,
    m.`运管院区`,
    m.`亚专业组`,
    
    -- 标本数
    m.`本月标本数` AS `标本数`,
    m.`上月标本数`,
    m.`去年同期标本数`,
    CASE WHEN m.`上月标本数` = 0 OR m.`上月标本数` IS NULL THEN NULL
         ELSE ROUND((m.`本月标本数` - m.`上月标本数`) / m.`上月标本数` * 100, 2) 
    END AS `标本数环比增长率%`,
    CASE WHEN m.`去年同期标本数` = 0 OR m.`去年同期标本数` IS NULL THEN NULL
         ELSE ROUND((m.`本月标本数` - m.`去年同期标本数`) / m.`去年同期标本数` * 100, 2) 
    END AS `标本数同比增长率%`,
    
    -- 项目数
    m.`本月项目数` AS `项目数`,
    m.`上月项目数`,
    m.`去年同期项目数`,
    CASE WHEN m.`上月项目数` = 0 OR m.`上月项目数` IS NULL THEN NULL
         ELSE ROUND((m.`本月项目数` - m.`上月项目数`) / m.`上月项目数` * 100, 2) 
    END AS `项目数环比增长率%`,
    CASE WHEN m.`去年同期项目数` = 0 OR m.`去年同期项目数` IS NULL THEN NULL
         ELSE ROUND((m.`本月项目数` - m.`去年同期项目数`) / m.`去年同期项目数` * 100, 2) 
    END AS `项目数同比增长率%`,
    
    -- 总收入
    m.`本月总收入` AS `总收入`,
    m.`上月总收入`,
    m.`去年同期总收入`,
    CASE WHEN m.`上月总收入` = 0 OR m.`上月总收入` IS NULL THEN NULL
         ELSE ROUND((m.`本月总收入` - m.`上月总收入`) / m.`上月总收入` * 100, 2) 
    END AS `收入环比增长率%`,
    CASE WHEN m.`去年同期总收入` = 0 OR m.`去年同期总收入` IS NULL THEN NULL
         ELSE ROUND((m.`本月总收入` - m.`去年同期总收入`) / m.`去年同期总收入` * 100, 2) 
    END AS `收入同比增长率%`,
    
    -- 收入占比
    CASE WHEN t.`本月总收入_合计` = 0 OR t.`本月总收入_合计` IS NULL THEN NULL
         ELSE ROUND(m.`本月总收入` / t.`本月总收入_合计` * 100, 2) 
    END AS `总收入占比%`,
    CASE WHEN t.`上月总收入_合计` = 0 OR t.`上月总收入_合计` IS NULL THEN NULL
         ELSE ROUND(m.`上月总收入` / t.`上月总收入_合计` * 100, 2) 
    END AS `上月总收入占比%`,
    CASE WHEN t.`去年同期总收入_合计` = 0 OR t.`去年同期总收入_合计` IS NULL THEN NULL
         ELSE ROUND(m.`去年同期总收入` / t.`去年同期总收入_合计` * 100, 2) 
    END AS `去年同期总收入占比%`

FROM merged_data m
CROSS JOIN totals t
CROSS JOIN date_labels d
ORDER BY
    CASE 
        WHEN m.`亚专业组` = '合计' THEN 1
        WHEN m.`亚专业组` = '本部实际量' THEN 2
        WHEN m.`亚专业组` = '天府医院' THEN 3
        ELSE 4
    END,
    m.`本月标本数` DESC;
