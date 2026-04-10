wb_bufe_current AS (
    SELECT 
        COUNT(A."inspection_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_inspection_sample_charge B 
        ON A."inspection_id" = B."inspection_id"
        AND B."isdeleted" = '0'
    LEFT JOIN HID0101_ORCL_LIS_XHSYSTEM1.lis_charge_item C 
        ON B."charge_item_id" = C."charge_item_id"
        AND C."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE STRPOS(B."his_id", '||') > 0 
        AND A."patient_type" IN ('1','2','3','4','5','8','12')
        AND A."GROUP_ID" IN ('G999','G998')
        AND A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end
        AND A."isdeleted" = '0'
),

-- 按科室统计（当月）
keshi_stat_current AS (
    SELECT 
        COUNT(DISTINCT A."requisition_id") as "样本数"
    FROM hid0101_orcl_lis_dbo.lis_inspection_sample A
    INNER JOIN hid0101_orcl_lis_dbo.lis_requisition_item B 
        ON A."requisition_id" = B."requisition_id"
        AND B."isdeleted" = '0'
    CROSS JOIN date_ranges d
    WHERE A."patient_type" IN ('1','2','3','4','5','8','12')
        AND A."GROUP_ID" IN ('G999','G998','G014','G022')
        AND A."inspection_date" BETWEEN d.current_month_start AND d.current_month_end
        AND A."isdeleted" = '0'
),
select
  COALESCE((SELECT "样本数" FROM wb_bufe_current), 0) + 
    COALESCE((SELECT "样本数" FROM keshi_stat_current), 0) as "当月标本数"