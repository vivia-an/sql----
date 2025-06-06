-- 根据就诊号查询患者信息（最终版）
-- 基于实际数据库字段名称
-- 查询字段：患者姓名、病案号、登记号、身份证号、参保类型、医保类型、统筹区、参保地区划代码、参保地区划名称

-- 住院患者信息查询
SELECT 
    CAST(COALESCE('', '') AS VARCHAR(100)) AS 患者姓名,  -- 住院主单表中可能没有患者姓名字段
    CAST(COALESCE(b.bridge_id, '') AS VARCHAR(100)) AS 病案号,
    CAST(COALESCE('', '') AS VARCHAR(100)) AS 登记号,  -- 住院主单表中可能没有登记号字段
    CAST(COALESCE(b.id_card, '') AS VARCHAR(100)) AS 身份证号,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50)) AS 参保类型,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50)) AS 医保类型,
    CAST(COALESCE('', '') AS VARCHAR(50)) AS 统筹区,  -- 住院主单表中可能没有统筹区字段
    CAST(COALESCE('', '') AS VARCHAR(50)) AS 参保地区划代码,  -- 住院主单表中可能没有此字段
    CAST(COALESCE('', '') AS VARCHAR(100)) AS 参保地区划名称,  -- 住院主单表中可能没有此字段
    CAST('住院' AS VARCHAR(10)) AS 就诊类型,
    CAST(b.zyh AS VARCHAR(100)) AS 就诊号
FROM flycheck_realtime.settle_zy b
WHERE b.zyh IN ('168880097')  -- 请替换为实际的住院号集合

UNION ALL

-- 门诊患者信息查询
SELECT 
    CAST(COALESCE('', '') AS VARCHAR(100)) AS 患者姓名,  -- 门诊主单表中可能没有患者姓名字段
    CAST(COALESCE('', '') AS VARCHAR(100)) AS 病案号,  -- 门诊主单表中可能没有病案号字段
    CAST(COALESCE('', '') AS VARCHAR(100)) AS 登记号,  -- 门诊主单表中可能没有登记号字段
    CAST(COALESCE(b.id_card, '') AS VARCHAR(100)) AS 身份证号,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50)) AS 参保类型,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50)) AS 医保类型,
    CAST(COALESCE('', '') AS VARCHAR(50)) AS 统筹区,  -- 门诊主单表中可能没有统筹区字段
    CAST(COALESCE('', '') AS VARCHAR(50)) AS 参保地区划代码,  -- 门诊主单表中可能没有此字段
    CAST(COALESCE('', '') AS VARCHAR(100)) AS 参保地区划名称,  -- 门诊主单表中可能没有此字段
    CAST('门诊' AS VARCHAR(10)) AS 就诊类型,
    CAST(b.mzh AS VARCHAR(100)) AS 就诊号
FROM flycheck_realtime.settle_mz b
WHERE b.mzh IN ('168880097')  -- 请替换为实际的门诊号集合

ORDER BY 就诊号;

-- 使用示例：
-- 住院号查询：将 WHERE b.zyh IN ('就诊号1', '就诊号2', '就诊号3') 
-- 替换为：WHERE b.zyh IN ('2024001', '2024002', '2024003')
-- 
-- 门诊号查询：将 WHERE b.mzh IN ('就诊号1', '就诊号2', '就诊号3')
-- 替换为：WHERE b.mzh IN ('MZ2024001', 'MZ2024002', 'MZ2024003')

-- 注意：
-- 1. 住院主单表中可能没有患者姓名字段，如需要请从明细表关联获取
-- 2. 字段名称已根据实际数据库结构调整
-- 3. 如果某些字段不存在，请根据实际表结构进行调整 