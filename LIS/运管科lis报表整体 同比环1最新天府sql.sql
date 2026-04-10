-- 转换后的Presto SQL
SELECT 
    COUNT(DISTINCT T."inspection_id") as "检验样本数",
    SUM(COALESCE(CAST(B."workload" AS DOUBLE), 0)) as "工作量",
    SUM(COALESCE(CAST(B."charge" AS DOUBLE), 0)) as "收费金额"
FROM hid0117_orcl_lis_dbo.lis_inspection_sample T
INNER JOIN hid0117_orcl_lis_dbo.lis_inspection_sample_charge B
    ON T."inspection_id" = B."inspection_id"
    AND B."isdeleted" = '0'
WHERE T."inspection_date" BETWEEN '20240801' AND '20240831'
    AND T."GROUP_ID" <> 'G050'
    AND T."isdeleted" = '0'
    AND NOT EXISTS (
        SELECT 1
        FROM hid0117_orcl_lis_dbo.lis_requisition_item Q
        WHERE Q."requisition_id" = T."requisition_id"
            AND Q."charge_item_id" IN ('LIS0301', 'LIS027534', 'LIS024805',
                'LIS01566', 'LIS01414', 'LIS027420')
            AND Q."isdeleted" = '0'
    )
    T.GROUP_ID IN ('G003','G004','G006','G009','G010','G011','G014','G017','G022','G068' ,'G999')