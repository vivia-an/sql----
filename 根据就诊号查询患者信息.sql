-- 根据就诊号查询患者信息
-- 查询字段：患者姓名、病案号、登记号、身份证号、参保类型、医保类型、统筹区、参保地区划代码、参保地区划名称
-- 支持住院号(ZYH)和门诊号(MZH)查询

-- 住院患者信息查询
SELECT 
    COALESCE(b.patient_name, '') AS 患者姓名,
    COALESCE(a.bah, '') AS 病案号,
    COALESCE(a.fee_billdet_persno, '') AS 登记号,
    COALESCE(a.sfzhm, '') AS 身份证号,
    COALESCE(a.cblx, '') AS 参保类型,
    COALESCE(a.yblx, '') AS 医保类型,
    COALESCE(a.tcq, '') AS 统筹区,
    COALESCE(a.cbdqdm, '') AS 参保地区划代码,
    COALESCE(a.cbdqmc, '') AS 参保地区划名称,
    '住院' AS 就诊类型,
    b.zyh AS 就诊号
FROM flycheck_realtime.settle_zy_detail a
INNER JOIN flycheck_realtime.settle_zy b ON a.zyh = b.zyh AND a.hisid = b.hisid
WHERE b.zyh IN ('就诊号1', '就诊号2', '就诊号3')  -- 请替换为实际的就诊号集合

UNION ALL

-- 门诊患者信息查询
SELECT 
    COALESCE(b.patient_name, '') AS 患者姓名,
    COALESCE(a.bah, '') AS 病案号,
    COALESCE('', '') AS 登记号,
    COALESCE(b.id_card, '') AS 身份证号,
    COALESCE(b.benefit_type, '') AS 参保类型,
    COALESCE('', '') AS 医保类型,
    COALESCE(a.tcq, '') AS 统筹区,
    COALESCE(a.cbdqdm, '') AS 参保地区划代码,
    COALESCE(a.cbdqmc, '') AS 参保地区划名称,
    '门诊' AS 就诊类型,
    b.mzh AS 就诊号
FROM flycheck_realtime.settle_mz_detail a
INNER JOIN flycheck_realtime.settle_mz b ON a.hisid = b.hisid
WHERE b.mzh IN ('就诊号1', '就诊号2', '就诊号3')  -- 请替换为实际的就诊号集合

ORDER BY 就诊号;

-- 使用示例：
-- 将上述SQL中的 ('就诊号1', '就诊号2', '就诊号3') 替换为实际的就诊号集合
-- 例如：('2024001', '2024002', '2024003', '2024004') 

-- 字段说明：
-- 1. 患者基本信息优先从主单表(settle_zy/settle_mz)获取
-- 2. 身份证号：主单表优先，明细表的sfzhm作为备用(仅住院)
-- 3. 参保类型：主单表的benefit_type优先，明细表的cblx作为备用(仅住院)
-- 4. 医保类型：仅住院明细表有此字段(yblx)，门诊置空
-- 5. 统筹区、参保地区划：从明细表获取，两表字段一致
-- 6. 所有字段统一转换为VARCHAR类型避免类型冲突 