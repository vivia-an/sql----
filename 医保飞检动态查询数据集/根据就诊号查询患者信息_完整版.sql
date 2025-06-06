-- 根据就诊号查询患者信息（完整版）
-- 从多个表关联获取完整信息
-- 查询字段：患者姓名、病案号、登记号、身份证号、参保类型、医保类型、统筹区、参保地区划代码、参保地区划名称

-- 住院患者信息查询（从明细表关联获取完整信息）

-- 住院患者信息查询（从明细表关联获取完整信息）
SELECT DISTINCT * FROM (
  SELECT DISTINCT
    CAST(COALESCE(a.patient_name, '') AS VARCHAR(100))   AS 患者姓名,
    CAST(COALESCE(a.bah,          '') AS VARCHAR(100))   AS 病案号,
    CAST(COALESCE(a.fee_billdet_persno, '') AS VARCHAR(100)) AS 登记号,
    CAST(COALESCE(a.sfzhm,        '') AS VARCHAR(100))   AS 身份证号,
    CAST(COALESCE(a.cblx,         '') AS VARCHAR(50))    AS 参保类型,
    CAST(COALESCE(a.yblx,         '') AS VARCHAR(50))    AS 医保类型,
    CAST(COALESCE(a.tcq,          '') AS VARCHAR(50))    AS 统筹区,
    CAST(COALESCE(a.cbdqdm,       '') AS VARCHAR(50))    AS 参保地区划代码,
    CAST(COALESCE(a.cbdqmc,       '') AS VARCHAR(100))   AS 参保地区划名称,
    CAST('住院'                   AS VARCHAR(10))        AS 就诊类型,
    CAST(b.zyh                    AS VARCHAR(100))       AS 就诊号
  FROM flycheck_realtime.settle_zy b
  LEFT JOIN flycheck_realtime.settle_zy_detail a
    ON b.zyh = a.zyh
   AND b.hisid = a.hisid
  WHERE b.zyh IN ('183727407')    -- 请替换为实际的住院号集合

  UNION ALL

  -- 门诊患者信息查询（从明细表关联获取完整信息）
  SELECT DISTINCT
    CAST(COALESCE(b.patient_name, '') AS VARCHAR(100))   AS 患者姓名,
    CAST(COALESCE('',        '') AS VARCHAR(100))   AS 病案号,   -- 门诊通常没有病案号
    CAST(COALESCE('',          '') AS VARCHAR(100))   AS 登记号,  -- 门诊没有登记号记录
    CAST(COALESCE(b.id_card,      '') AS VARCHAR(100))   AS 身份证号,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50))    AS 参保类型,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50))    AS 医保类型,
    CAST(COALESCE(a.tcq,          '') AS VARCHAR(50))    AS 统筹区,
    CAST(COALESCE(a.cbdqdm,       '') AS VARCHAR(50))    AS 参保地区划代码,
    CAST(COALESCE(a.cbdqmc,       '') AS VARCHAR(100))   AS 参保地区划名称,
    CAST('门诊'                   AS VARCHAR(10))        AS 就诊类型,
    CAST(b.mzh                    AS VARCHAR(100))       AS 就诊号
  FROM flycheck_realtime.settle_mz b
  LEFT JOIN flycheck_realtime.settle_mz_detail a
    ON b.hisid = a.hisid
  WHERE b.mzh IN ('183727407')    -- 请替换为实际的门诊号集合
) t
ORDER BY 就诊号;

-- 使用示例：
-- 住院号查询：将 WHERE b.zyh IN ('168880097') 
-- 替换为：WHERE b.zyh IN ('2024001', '2024002', '2024003')
-- 
-- 门诊号查询：将 WHERE b.mzh IN ('168880097')
-- 替换为：WHERE b.mzh IN ('MZ2024001', 'MZ2024002', 'MZ2024003')

-- 说明：
-- 1. 使用 COALESCE 函数优先从明细表获取字段，如果明细表没有则从主单表获取
-- 2. 使用 DISTINCT 去除重复记录（因为一个患者可能有多条明细记录）
-- 3. 使用 LEFT JOIN 确保即使没有明细记录也能查到主单信息
-- 4. 字段优先级：明细表 > 主单表 > 空字符串 