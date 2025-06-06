-- 耳鼻喉科鼻中隔偏曲患者查询
-- 查找出院诊断为"鼻中隔偏曲"且收取了"鼻畸形矫正术"(330601025)费用的住院患者数据
-- 数据提取时间：2022.12.1-2025.5.26

SELECT 
    CAST(b.PATIENT_NAME AS VARCHAR(100)) AS 患者姓名,
    CAST(b.PATIENT_GENDER AS VARCHAR(10)) AS 患者性别,
    CAST(b.ID_CARD AS VARCHAR(100)) AS 身份证号,
    CAST('住院' AS VARCHAR(10)) AS 就诊类别,
    CAST(b.zyh AS VARCHAR(50)) AS 住院号,
    CAST(b.ADMISSION_DATE AS VARCHAR(20)) AS 入院日期,
    CAST(b.DISCHARGE_DATE AS VARCHAR(20)) AS 出院日期,
    CAST(COALESCE(d.ADMISSION_DISEASE_NAME, '') AS VARCHAR(200)) AS 入院诊断,
    CAST(COALESCE(d.DISCHARGE_DISEASE_NAME_MAIN, '') AS VARCHAR(200)) AS 出院主诊断,
    CAST(COALESCE(d.DISCHARGE_DISEASE_NAME_MAIN, '') AS VARCHAR(500)) AS 出院诊断,
    CAST(b.DISCHARGE_DEPT_NAME AS VARCHAR(100)) AS 出院科室,
    a.USAGE_DATE AS 计费时间,
    CAST(a.EXCUTE_DEPT_NAME AS VARCHAR(100)) AS 计费科室,
    CAST(a.ITEM_NAME AS VARCHAR(100)) AS 项目名称,
    CAST(a.ITEM_ID_HOSP AS VARCHAR(50)) AS 项目编码,
    CAST(a.UNIT_PRICE AS VARCHAR(20)) AS 单价,
    CAST(a.NUM AS VARCHAR(20)) AS 数量,
    CAST(a.COST AS VARCHAR(20)) AS 总费用,
    CAST(a.BMI_CONVERED_AMOUNT AS VARCHAR(20)) AS 医保基金支付费用,
    CAST(CASE 
        WHEN b.IF_LOCAL_FLAG = '本地' THEN '省内'
        WHEN b.IF_LOCAL_FLAG = '异地' THEN '省外'
        ELSE COALESCE(b.IF_LOCAL_FLAG, '未知')
    END AS VARCHAR(50)) AS 参保地,
    CAST(COALESCE(b.BENEFIT_TYPE, '') AS VARCHAR(50)) AS 参保类别
FROM flycheck_realtime.settle_zy_detail a
INNER JOIN flycheck_realtime.settle_zy b ON a.zyh = b.zyh AND a.hisid = b.hisid
LEFT JOIN flycheck_realtime.settle_zy_diagnosis d ON b.hisid = d.hisid AND b.zyh = d.zyh
WHERE a.bill_date >= '2022-12-01' 
    AND a.bill_date < '2025-05-27'
    AND b.bill_date >= '2022-12-01' 
    AND b.bill_date < '2025-05-27'
    AND a.ITEM_ID_HOSP = '330601025'  -- 鼻畸形矫正术
    AND (b.DISCHARGE_DEPT_NAME LIKE '%耳鼻%' OR b.DISCHARGE_DEPT_NAME LIKE '%ENT%')  -- 出院科室为耳鼻喉科
    AND (
        d.DISCHARGE_DISEASE_NAME_MAIN LIKE '%鼻中隔偏曲%' 
        OR d.ADMISSION_DISEASE_NAME LIKE '%鼻中隔偏曲%'
    )  -- 诊断包含"鼻中隔偏曲"

ORDER BY b.DISCHARGE_DATE DESC, b.zyh, a.USAGE_DATE;

-- 查询说明：
-- 1. 仅查询住院患者（根据需求，门诊患者不适用于"出院诊断"概念）
-- 2. 出院科室必须包含"耳鼻"或"ENT"
-- 3. 诊断字段包含"鼻中隔偏曲"（检查主诊断、出院诊断、入院诊断）
-- 4. 必须收取了项目编码为"330601025"的"鼻畸形矫正术"费用
-- 5. 数据时间范围：2022.12.1-2025.5.26
-- 6. 按出院日期倒序、住院号、计费时间排序 