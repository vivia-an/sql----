SET
@stat_month = '2025-10';

SELECT
    '当月' as `统计月`,
  子.`单位`,
  子.`项目`,
  子.`本月` AS `本月`,
  子.`上月` AS `上月`,
  子.`去年同期` AS `去年同期`,
  CASE WHEN 子.`上月` = 0
  OR 子.`上月` IS NULL THEN NULL
  ELSE (子.`本月` - 子.`上月`) / 子.`上月` * 100 END AS `与上月差异%`,
  CASE WHEN 子.`去年同期` = 0
  OR 子.`去年同期` IS NULL THEN NULL
  ELSE (子.`本月` - 子.`去年同期`) / 子.`去年同期` * 100 END AS `与同期差异%`
FROM
  (
  select
    t.`单位`,
    t.`项目`,
    MAX(CASE WHEN t.`月份` = @stat_month THEN t.`数值` END) AS `本月`,
    MAX(CASE WHEN t.`月份` = DATE_FORMAT( DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -1 MONTH), '%Y-%m' ) THEN t.`数值` END) AS `上月`,
    MAX(CASE WHEN t.`月份` = DATE_FORMAT( DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -12 MONTH), '%Y-%m' ) THEN t.`数值` END) AS `去年同期`
  from
    (
    select
      *
    from
      (
      select
        t.`统计月`,
        t.`单位`,
        t.`项目`,
        t.`月份`,
        t.`数值`,
        ROW_NUMBER() OVER ( PARTITION BY t.`单位`,
        t.`项目`,
        t.`月份`
      ORDER BY
        t.`统计月` ) AS `row_num`
      from
        (
        SELECT
          t.`统计月`,
          t.`单位`,
          t.`项目`,
          CASE WHEN p.seq = 1 THEN t.`统计月`
          WHEN p.seq = 2 THEN DATE_FORMAT( DATE_ADD( STR_TO_DATE(CONCAT(t.`统计月`, '-01'), '%Y-%m-%d'), INTERVAL -1 MONTH ), '%Y-%m')
          WHEN p.seq = 3 THEN DATE_FORMAT( DATE_ADD( STR_TO_DATE(CONCAT(t.`统计月`, '-01'), '%Y-%m-%d'), INTERVAL -12 MONTH ), '%Y-%m') END AS `月份`,
          CASE WHEN p.seq = 1 THEN t.`本月`
          WHEN p.seq = 2 THEN t.`上月`
          WHEN p.seq = 3 THEN t.`去年同期` END AS `数值`
        FROM
          m1.om_bl_report_with_total AS t
        CROSS JOIN (
          SELECT
            1 AS seq
        UNION ALL
          SELECT
            2
        UNION ALL
          SELECT
            3 ) AS p
        ORDER BY
          t.`单位`,
          t.`项目`,
          p.seq ) t ) b
    where
      row_num = 1 ) t
  GROUP BY
    t.`单位`,
    t.`项目` ) AS 子
ORDER BY
  子.`单位`,
  子.`项目`;