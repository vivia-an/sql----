-- ========================================
-- 急会诊有效率统计（基于HIS原始表）
-- 时间范围：2024.1.1-2024.7.31 和 2025.1.1-2025.7.31
-- ========================================

-- ========================================
-- 查询逻辑与表来源血缘分析说明
-- ========================================
-- 1. 查询目标：
--    统计2024.1.1-2024.7.31和2025.1.1-2025.7.31期间，HIS系统内“单科急会诊”的有效率。
--    有效率=（单科急会诊后2小时内生成医嘱的会诊次数）/（同期单科急会诊总次数）* 100%

-- 2. 主要数据流程与来源表
-- 【A】基础会诊数据来源：hid0101_cache_his_dhcapp_sqluser.DHC_EmConsult 与 DHC_EmConsultLog
--      - DHC_EmConsult（会诊主表）：记录每次会诊的基本信息，包括会诊ID、就诊ID、会诊日期、会诊时间、分类（EC_Category），急诊标志（ec_emflag）等。
--      - DHC_EmConsultLog（会诊操作日志）：记录会诊操作流转状态，ECL_Status_Dr说明流转环节（6-确认到达、7-完成、10-请会诊评价等）。
--      - 通过DHC_EmConsult的主键EC_RowId与DHC_EmConsultLog的ECL_Cst_Ref字段进行关联（ECL_Cst_Ref取'||'前半段），仅计状态为6、7、10的流程，限制在单科会诊（EC_Category = '1'）且为急（ec_emflag = 'Y'），并限定统计时间范围（2024/2025年1-7月）。
--      - 拼接“会诊日期+会诊时间”作为“会诊时间戳”用于后续和医嘱开立时间对比。

-- 【B】会诊后开具医嘱的数据：hid0101_cache_his_dhcapp_sqluser.OE_Order 与 OE_OrdItem
--      - OE_Order（医嘱主表）：每条医嘱的就诊ID（OEORD_Adm_DR）、医嘱ID等。
--      - OE_OrdItem（医嘱明细）：包含医嘱子项具体时间（OEORI_SttDat开嘱日期、OEORI_SttTim开嘱时间），
--      - 通过ConsultBase会诊基础数据的“就诊ID”与OE_Order的OEORD_Adm_DR关联，OE_Order与OE_OrdItem通过OEORD_RowId=OEORI_OEORD_ParRef关联。
--      - 统计医嘱时间 ≥ 会诊时间戳，且 < 会诊时间戳+2小时的医嘱明细，按“会诊ID”计数。

-- 3. 统计口径说明
--    - 会诊基础总次数：指同期所有符合条件的“单科”、“急”且在指定流转状态的会诊（ConsultBase）。
--    - 有效会诊次数：指上面基础会诊后2小时内至少生成一条医嘱的会诊次数。
--    - 有效率=有效次数/总次数。

-- 4. 主要代码血缘关系（核心字段来源）：
--    | 字段                 | 来源表/字段                                                    |
--    |---------------------|-------------------------------------------------------------|
--    | 会诊ID              | DHC_EmConsult.EC_RowId                                       |
--    | 就诊ID              | DHC_EmConsult.EC_ADM_DR                                      |
--    | 会诊日期            | DHC_EmConsult.EC_RDate                                       |
--    | 会诊时间            | DHC_EmConsult.EC_RTime                                       |
--    | 会诊类别            | DHC_EmConsult.EC_Category                                    |
--    | 急诊标志            | DHC_EmConsult.ec_emflag                                      |
--    | 会诊日志状态        | DHC_EmConsultLog.ECL_Status_Dr                               |
--    | 医嘱开立日期/时间   | OE_OrdItem.OEORI_SttDat / OEORI_SttTim                      |
--    | 医嘱、会诊表关联    | ConsultBase.就诊ID = OE_Order.OEORD_Adm_DR                  |
--    | 医嘱主子表关联      | OE_Order.OEORD_RowId = OE_OrdItem.OEORI_OEORD_ParRef         |

-- 5. 注意事项
--    - 所有表字段在大数据平台均为varchar类型，时间字段拼接后需按TIMESTAMP格式比较。
--    - 所有关联均加逻辑删除过滤isdeleted='0'（原代码未显式添加，如数据血缘/业务要求可补充）。
--    - 查询库名均为：hid0101_cache_his_dhcapp_sqluser（HIS集成大数据表）。

-- 6. 业务解释总结
--    该查询用于衡量 HIS 系统中“单科急会诊”后能否快速落实诊疗（通过医嘱情况反映），
--    有效会诊定义为：会诊后2小时内有对应医嘱生成的情况，从而反映临床沟通与执行能力。




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