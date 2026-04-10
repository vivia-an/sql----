SET @stat_month = '2025-10';

-- 从历史表中获取当月、上月、去年同期数据并计算同比环比
SELECT
  @stat_month AS `统计月`,
  cur.`单位`,
  cur.`项目`,
  COALESCE(cur.`本月`, 0) AS `本月`,
  COALESCE(last_m.`本月`, 0) AS `上月`,
  COALESCE(last_y.`本月`, 0) AS `去年同期`,
  CASE 
    WHEN COALESCE(last_m.`本月`, 0) = 0 THEN 0
    ELSE ROUND((COALESCE(cur.`本月`, 0) - COALESCE(last_m.`本月`, 0)) / last_m.`本月` * 100, 2) 
  END AS `与上月差异%`,
  CASE 
    WHEN COALESCE(last_y.`本月`, 0) = 0 THEN 0
    ELSE ROUND((COALESCE(cur.`本月`, 0) - COALESCE(last_y.`本月`, 0)) / last_y.`本月` * 100, 2) 
  END AS `与同期差异%`,
  CASE cur.`单位`
    WHEN '主院区' THEN 1
    WHEN '上锦院区' THEN 2
    WHEN '天府院区' THEN 3
    WHEN '合计' THEN 4
    ELSE 5
  END AS unit_order,
  CASE cur.`项目`
    WHEN '检查治疗人次/项次' THEN 1
    WHEN '检查治疗收入(元)' THEN 2
    WHEN '穿刺中心细胞病理收入(元)' THEN 3
    WHEN '本部温江第三方体检病理收入(元)' THEN 4
    WHEN '其他收入(元)' THEN 5
    WHEN '本部收入合计' THEN 6
    WHEN '领用材料试剂费(元)' THEN 7
    WHEN '领用材料试剂费占收入比例(%)' THEN 8
    WHEN '上锦检查治疗收入(元)' THEN 2
    WHEN '上锦体检病理收入(元)' THEN 3
    WHEN '上锦收入合计' THEN 6
    WHEN '天府检查治疗收入(元)' THEN 2
    WHEN '天府体检病理收入(元)' THEN 3
    WHEN '天府收入合计' THEN 6
    WHEN '检查治疗人次/项次合计' THEN 9
    WHEN '总收入合计(元)' THEN 10
    ELSE 11
  END AS item_order
FROM 
  -- 当月数据
  (SELECT `单位`, `项目`, `本月` 
   FROM m1.om_bl_report_with_total 
   WHERE `统计月` = @stat_month) AS cur
LEFT JOIN 
  -- 上月数据
  (SELECT `单位`, `项目`, `本月`
   FROM m1.om_bl_report_with_total 
   WHERE `统计月` = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -1 MONTH), '%Y-%m')) AS last_m
  ON cur.`单位` = last_m.`单位` AND cur.`项目` = last_m.`项目`
LEFT JOIN 
  -- 去年同期数据
  (SELECT `单位`, `项目`, `本月`
   FROM m1.om_bl_report_with_total 
   WHERE `统计月` = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(@stat_month, '-01'), '%Y-%m-%d'), INTERVAL -12 MONTH), '%Y-%m')) AS last_y
  ON cur.`单位` = last_y.`单位` AND cur.`项目` = last_y.`项目`
ORDER BY unit_order, item_order;