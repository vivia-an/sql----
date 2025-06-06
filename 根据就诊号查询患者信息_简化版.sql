-- 根据就诊号查询患者信息（简化版）
-- 查询字段：患者姓名、病案号、登记号、身份证号、参保类型、医保类型、统筹区、参保地区划代码、参保地区划名称

-- 住院患者信息查询
SELECT 
    CAST(COALESCE(b.patient_name, '') AS VARCHAR(100)) AS 患者姓名,
    CAST(COALESCE(b.bah, '') AS VARCHAR(100)) AS 病案号,
    CAST(COALESCE(b.fee_billdet_persno, '') AS VARCHAR(100)) AS 登记号,
    CAST(COALESCE(b.id_card, '') AS VARCHAR(100)) AS 身份证号,
    CAST(COALESCE(b.cblx, '') AS VARCHAR(50)) AS 参保类型,
    CAST(COALESCE(b.yblx, '') AS VARCHAR(50)) AS 医保类型,
    CAST(COALESCE(b.tcq, '') AS VARCHAR(50)) AS 统筹区,
    CAST(COALESCE(b.cbdqdm, '') AS VARCHAR(50)) AS 参保地区划代码,
    CAST(COALESCE(b.cbdqmc, '') AS VARCHAR(100)) AS 参保地区划名称,
    CAST('住院' AS VARCHAR(10)) AS 就诊类型,
    CAST(b.zyh AS VARCHAR(100)) AS 就诊号
FROM flycheck_realtime.settle_zy b
WHERE b.zyh IN ('就诊号1', '就诊号2', '就诊号3')  -- 请替换为实际的住院号集合

UNION ALL

-- 门诊患者信息查询
SELECT 
    CAST(COALESCE(b.patient_name, '') AS VARCHAR(100)) AS 患者姓名,
    CAST(COALESCE(b.bah, '') AS VARCHAR(100)) AS 病案号,
    CAST(COALESCE(b.fee_billdet_persno, '') AS VARCHAR(100)) AS 登记号,
    CAST(COALESCE(b.id_card, '') AS VARCHAR(100)) AS 身份证号,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50)) AS 参保类型,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50)) AS 医保类型,
    CAST(COALESCE(b.tcq, '') AS VARCHAR(50)) AS 统筹区,
    CAST(COALESCE(b.cbdqdm, '') AS VARCHAR(50)) AS 参保地区划代码,
    CAST(COALESCE(b.cbdqmc, '') AS VARCHAR(100)) AS 参保地区划名称,
    CAST('门诊' AS VARCHAR(10)) AS 就诊类型,
    CAST(b.mzh AS VARCHAR(100)) AS 就诊号
FROM flycheck_realtime.settle_mz b
WHERE b.mzh IN ('就诊号1', '就诊号2', '就诊号3')  -- 请替换为实际的门诊号集合

ORDER BY 就诊号;

-- 使用示例：
-- 住院号查询：将 WHERE b.zyh IN ('就诊号1', '就诊号2', '就诊号3') 
-- 替换为：WHERE b.zyh IN ('2024001', '2024002', '2024003')
-- 
-- 门诊号查询：将 WHERE b.mzh IN ('就诊号1', '就诊号2', '就诊号3')
-- 替换为：WHERE b.mzh IN ('MZ2024001', 'MZ2024002', 'MZ2024003') 