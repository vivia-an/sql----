-- 上月治疗收入查询
SELECT 
    date_format(date_add('month', -1, current_date), '%Y-%m') as "周期",
    '上月' as "周期名称",
    1 as "排序",
    date_format(date_add('month', -1, current_date), '%Y年%m月') as "统计月",
    SUM(CAST(fee.fee_billdet_totalfee AS DOUBLE)) as "治疗收入"
FROM datacenter_db.Order_Main order_main
LEFT JOIN datacenter_db.fee_billdet fee
    ON order_main.order_main_dstablevalue = fee.fee_billdet_orderdetid 
    AND order_main.medorgcode = fee.medorgcode 
WHERE order_main."Order_Main_RecDeptName" IN ('输血科','锦江输血科')
    AND order_main."Order_Main_OrderItemCode" IN ('666600613','666000570','666000571','666600598','666000510')
    AND order_main."Order_Main_OrderBeginDtTm" BETWEEN
        CONCAT(date_format(date_trunc('month', date_add('month', -1, current_date)), '%Y-%m-%d'), ' 00:00:00')
        AND CONCAT(date_format(date_add('day', -1, date_trunc('month', current_date)), '%Y-%m-%d'), ' 23:59:59')





        -- 上上月治疗收入查询
SELECT 
    date_format(date_add('month', -2, current_date), '%Y-%m') as "周期",
    '上上月' as "周期名称",
    2 as "排序",
    date_format(date_add('month', -1, current_date), '%Y年%m月') as "统计月",
    SUM(CAST(fee.fee_billdet_totalfee AS DOUBLE)) as "治疗收入"
FROM datacenter_db.Order_Main order_main
LEFT JOIN datacenter_db.fee_billdet fee
    ON order_main.order_main_dstablevalue = fee.fee_billdet_orderdetid 
    AND order_main.medorgcode = fee.medorgcode 
WHERE order_main."Order_Main_RecDeptName" IN ('输血科','锦江输血科')
    AND order_main."Order_Main_OrderItemCode" IN ('666600613','666000570','666000571','666600598','666000510')
    AND order_main."Order_Main_OrderBeginDtTm" BETWEEN
        CONCAT(date_format(date_trunc('month', date_add('month', -2, current_date)), '%Y-%m-%d'), ' 00:00:00')
        AND CONCAT(date_format(date_add('day', -1, date_trunc('month', date_add('month', -1, current_date))), '%Y-%m-%d'), ' 23:59:59')


        -- 去年同期治疗收入查询
SELECT 
    date_format(date_add('month', -13, current_date), '%Y-%m') as "周期",
    '去年同期' as "周期名称",
    3 as "排序",
    date_format(date_add('month', -1, current_date), '%Y年%m月') as "统计月",
    SUM(CAST(fee.fee_billdet_totalfee AS DOUBLE)) as "治疗收入"
FROM datacenter_db.Order_Main order_main
LEFT JOIN datacenter_db.fee_billdet fee
    ON order_main.order_main_dstablevalue = fee.fee_billdet_orderdetid 
    AND order_main.medorgcode = fee.medorgcode 
WHERE order_main."Order_Main_RecDeptName" IN ('输血科','锦江输血科')
    AND order_main."Order_Main_OrderItemCode" IN ('666600613','666000570','666000571','666600598','666000510')
    AND order_main."Order_Main_OrderBeginDtTm" BETWEEN
        CONCAT(date_format(date_trunc('month', date_add('month', -13, current_date)), '%Y-%m-%d'), ' 00:00:00')
        AND CONCAT(date_format(date_add('day', -1, date_trunc('month', date_add('month', -12, current_date))), '%Y-%m-%d'), ' 23:59:59')