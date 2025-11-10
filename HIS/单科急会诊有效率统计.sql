-- ========================================
-- 急会诊有效率统计（基于HIS原始表）
-- 时间范围：2024.1.1-2024.7.31 和 2025.1.1-2025.7.31
-- ========================================

WITH ConsultBase AS (
    -- 基础会诊数据：单科急会诊 + 状态筛选
    SELECT DISTINCT
        c.EC_RowId AS "会诊ID",
        c.EC_ADM_DR AS "就诊ID",
        c.EC_RDate AS "会诊日期",
        c.EC_RTime AS "会诊时间",
        c.EC_Category AS "会诊类别",
        c.EC_RLoc_Dr AS "申请科室ID",
        -- 拼接完整的会诊时间戳用于时间比较
        CAST(c.EC_RDate || ' ' || c.EC_RTime AS TIMESTAMP) AS "会诊时间戳"
    FROM hid0101_cache_his_dhcapp_sqluser.DHC_EmConsult c
    INNER JOIN hid0101_cache_his_dhcapp_sqluser.DHC_EmConsultLog l
        ON CAST(c.EC_RowId AS VARCHAR) = SPLIT_PART(l.ECL_Cst_Ref, '||', 1)
        AND l.ECL_Status_Dr IN ('6', '7', '10')  -- 确认到达、完成、请会诊评价
    WHERE c.EC_Category = '1'  -- 单科会诊（请根据实际值调整）
         and c.ec_emflag='Y'  -- 急
        AND (
            (c.EC_RDate >= '2024-01-01' AND c.EC_RDate < '2024-08-01')
            OR
            (c.EC_RDate >= '2025-01-01' AND c.EC_RDate < '2025-08-01')
        )
),
ConsultWithOrder AS (
    -- 会诊后2小时内有医嘱的会诊
    SELECT DISTINCT
        cb."会诊ID",
        cb."会诊日期",
        cb."会诊时间",
        cb."会诊类别",
        COUNT(DISTINCT oi.OEORI_RowId) AS "医嘱数量"
    FROM ConsultBase cb
    INNER JOIN hid0101_cache_his_dhcapp_sqluser.OE_Order o
        ON cb."就诊ID" = o.OEORD_Adm_DR
    INNER JOIN hid0101_cache_his_dhcapp_sqluser.OE_OrdItem oi
        ON o.OEORD_RowId = oi.OEORI_OEORD_ParRef
    WHERE 
        
        -- 医嘱时间在会诊时间之后
        CAST(oi.OEORI_SttDat || ' ' || oi.OEORI_SttTim AS TIMESTAMP) >= cb."会诊时间戳"
        -- 医嘱时间在会诊后2小时内
        AND CAST(oi.OEORI_SttDat || ' ' || oi.OEORI_SttTim AS TIMESTAMP) < 
            cb."会诊时间戳" + INTERVAL '2' HOUR
    GROUP BY 
        cb."会诊ID",
        cb."会诊日期",
        cb."会诊时间",
        cb."会诊类别"
)
-- 最终统计结果
SELECT 
    '2024-2025年(1-7月)' AS "统计周期",
    COUNT(DISTINCT cb."会诊ID") AS "同期单科急会诊总次数",
    COUNT(DISTINCT cwo."会诊ID") AS "单科急会诊后开具相关医嘱的次数",
    CAST(
        COUNT(DISTINCT cwo."会诊ID") * 100.0 / 
        NULLIF(COUNT(DISTINCT cb."会诊ID"), 0) 
        AS DECIMAL(10,2)
    ) AS "急会诊有效率(%)"
FROM ConsultBase cb
LEFT JOIN ConsultWithOrder cwo
    ON cb."会诊ID" = cwo."会诊ID";