SET @stat_month = '2025-10';

SELECT
    '当月' as `统计月`,
    结果.`运管科室`,
    结果.`运管院区`,
    结果.`亚专业组`,
    结果.`本月标本数`,
    结果.`上月标本数`,
    结果.`去年同期标本数`,
    结果.`标本数环比%`,
    结果.`标本数同比%`,
    结果.`本月项目数`,
    结果.`上月项目数`,
    结果.`去年同期项目数`,
    结果.`项目数环比%`,
    结果.`项目数同比%`,
    结果.`本月总收入`,
    结果.`上月总收入`,
    结果.`去年同期总收入`,
    结果.`总收入环比%`,
    结果.`总收入同比%`,
    CASE WHEN 结果.`本月总收入_合计` = 0 OR 结果.`本月总收入_合计` IS NULL THEN NULL
         ELSE 结果.`本月总收入` / 结果.`本月总收入_合计` * 100 END AS `本月总收入占比%`,
    CASE WHEN 结果.`上月总收入_合计` = 0 OR 结果.`上月总收入_合计` IS NULL THEN NULL
         ELSE 结果.`上月总收入` / 结果.`上月总收入_合计` * 100 END AS `上月总收入占比%`,
    CASE WHEN 结果.`去年同期总收入_合计` = 0 OR 结果.`去年同期总收入_合计` IS NULL THEN NULL
         ELSE 结果.`去年同期总收入` / 结果.`去年同期总收入_合计` * 100 END AS `去年同期总收入占比%`
FROM
    (
    SELECT
        子.`运管科室`,
        子.`运管院区`,
        子.`亚专业组`,
        子.`本月标本数`,
        子.`上月标本数`,
        子.`去年同期标本数`,
        CASE WHEN 子.`上月标本数` = 0 OR 子.`上月标本数` IS NULL THEN NULL
             ELSE (子.`本月标本数` - 子.`上月标本数`) / 子.`上月标本数` * 100 END AS `标本数环比%`,
        CASE WHEN 子.`去年同期标本数` = 0 OR 子.`去年同期标本数` IS NULL THEN NULL
             ELSE (子.`本月标本数` - 子.`去年同期标本数`) / 子.`去年同期标本数` * 100 END AS `标本数同比%`,
        子.`本月项目数`,
        子.`上月项目数`,
        子.`去年同期项目数`,
        CASE WHEN 子.`上月项目数` = 0 OR 子.`上月项目数` IS NULL THEN NULL
             ELSE (子.`本月项目数` - 子.`上月项目数`) / 子.`上月项目数` * 100 END AS `项目数环比%`,
        CASE WHEN 子.`去年同期项目数` = 0 OR 子.`去年同期项目数` IS NULL THEN NULL
             ELSE (子.`本月项目数` - 子.`去年同期项目数`) / 子.`去年同期项目数` * 100 END AS `项目数同比%`,
        子.`本月总收入`,
        子.`上月总收入`,
        子.`去年同期总收入`,
        CASE WHEN 子.`上月总收入` = 0 OR 子.`上月总收入` IS NULL THEN NULL
             ELSE (子.`本月总收入` - 子.`上月总收入`) / 子.`上月总收入` * 100 END AS `总收入环比%`,
        CASE WHEN 子.`去年同期总收入` = 0 OR 子.`去年同期总收入` IS NULL THEN NULL
             ELSE (子.`本月总收入` - 子.`去年同期总收入`) / 子.`去年同期总收入` * 100 END AS `总收入同比%`,
        MAX(CASE WHEN 子.`运管院区` = '合计' THEN 子.`本月总收入` END) OVER(PARTITION BY 子.`运管科室`) AS `本月总收入_合计`,
        MAX(CASE WHEN 子.`运管院区` = '合计' THEN 子.`上月总收入` END) OVER(PARTITION BY 子.`运管科室`) AS `上月总收入_合计`,
        MAX(CASE WHEN 子.`运管院区` = '合计' THEN 子.`去年同期总收入` END) OVER(PARTITION BY 子.`运管科室`) AS `去年同期总收入_合计`
    FROM
        (
        SELECT
            t.`运管科室`,
            t.`运管院区`,
            t.`亚专业组`,
            MAX(CASE WHEN t.`月份` = @stat_month AND t.`指标名称` = '标本数' THEN t.`数值` END) AS `本月标本数`,
            MAX(CASE WHEN t.`月份` = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -1 MONTH), '%Y-%m') AND t.`指标名称` = '标本数' THEN t.`数值` END) AS `上月标本数`,
            MAX(CASE WHEN t.`月份` = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -12 MONTH), '%Y-%m') AND t.`指标名称` = '标本数' THEN t.`数值` END) AS `去年同期标本数`,
            MAX(CASE WHEN t.`月份` = @stat_month AND t.`指标名称` = '项目数' THEN t.`数值` END) AS `本月项目数`,
            MAX(CASE WHEN t.`月份` = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -1 MONTH), '%Y-%m') AND t.`指标名称` = '项目数' THEN t.`数值` END) AS `上月项目数`,
            MAX(CASE WHEN t.`月份` = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -12 MONTH), '%Y-%m') AND t.`指标名称` = '项目数' THEN t.`数值` END) AS `去年同期项目数`,
            MAX(CASE WHEN t.`月份` = @stat_month AND t.`指标名称` = '总收入' THEN t.`数值` END) AS `本月总收入`,
            MAX(CASE WHEN t.`月份` = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -1 MONTH), '%Y-%m') AND t.`指标名称` = '总收入' THEN t.`数值` END) AS `上月总收入`,
            MAX(CASE WHEN t.`月份` = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -12 MONTH), '%Y-%m') AND t.`指标名称` = '总收入' THEN t.`数值` END) AS `去年同期总收入`
        FROM
            (
            SELECT *
            FROM
                (
                SELECT
                    t.`统计月`,
                    t.`运管科室`,
                    t.`运管院区`,
                    t.`亚专业组`,
                    t.`指标名称`,
                    t.`月份`,
                    t.`数值`,
                    ROW_NUMBER() OVER (PARTITION BY t.`运管科室`, t.`运管院区`, t.`亚专业组`, t.`指标名称`, t.`月份` 
                                       ORDER BY t.`统计月` DESC) AS `row_num`
                FROM
                    (
                    SELECT
                        t.`统计月`,
                        t.`运管科室`,
                        t.`运管院区`,
                        t.`亚专业组`,
                        CASE WHEN p.seq = 1 THEN '标本数'
                             WHEN p.seq = 2 THEN '项目数'
                             WHEN p.seq = 3 THEN '总收入' END AS `指标名称`,
                        CASE WHEN p.time_seq = 1 THEN t.`统计月`
                             WHEN p.time_seq = 2 THEN DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(t.`统计月`, '-01'), '%Y-%m-%d'), INTERVAL -1 MONTH), '%Y-%m')
                             WHEN p.time_seq = 3 THEN DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(t.`统计月`, '-01'), '%Y-%m-%d'), INTERVAL -12 MONTH), '%Y-%m') END AS `月份`,
                        CASE WHEN p.seq = 1 AND p.time_seq = 1 THEN t.`标本数`
                             WHEN p.seq = 1 AND p.time_seq = 2 THEN t.`上月标本数`
                             WHEN p.seq = 1 AND p.time_seq = 3 THEN t.`去年同期标本数`
                             WHEN p.seq = 2 AND p.time_seq = 1 THEN t.`项目数`
                             WHEN p.seq = 2 AND p.time_seq = 2 THEN t.`上月项目数`
                             WHEN p.seq = 2 AND p.time_seq = 3 THEN t.`去年同期项目数`
                             WHEN p.seq = 3 AND p.time_seq = 1 THEN t.`总收入`
                             WHEN p.seq = 3 AND p.time_seq = 2 THEN t.`上月总收入`
                             WHEN p.seq = 3 AND p.time_seq = 3 THEN t.`去年同期总收入` END AS `数值`
                    FROM
                        m1.transport_is_experimental AS t
                    CROSS JOIN (
                        SELECT 1 AS seq, 1 AS time_seq
                        UNION ALL SELECT 1, 2
                        UNION ALL SELECT 1, 3
                        UNION ALL SELECT 2, 1
                        UNION ALL SELECT 2, 2
                        UNION ALL SELECT 2, 3
                        UNION ALL SELECT 3, 1
                        UNION ALL SELECT 3, 2
                        UNION ALL SELECT 3, 3
                    ) AS p
                    ) t
                ) b
            WHERE row_num = 1
            ) t
        GROUP BY
            t.`运管科室`,
            t.`运管院区`,
            t.`亚专业组`
        ) AS 子
    ) AS 结果
ORDER BY
    结果.`运管科室`,
    结果.`运管院区`,
    结果.`亚专业组`;