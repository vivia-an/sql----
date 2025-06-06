-- 耳鼻喉科互斥项目查询（修复版）
-- 查找同一小时收取"鼻内镜检查"(310402001)与"表面麻醉"(33010000101)的患者明细
-- 修复所有字段类型不匹配问题

SELECT 
    T1.患者姓名,
    T1.患者性别,
    T1.身份证号,
    T1.就诊类别,
    T1.入院诊断,
    T1.出院诊断,
    T1.计费时间,
    T1.计费科室,
    T1.项目名称 AS 项目A名称,
    T1.单价 AS 项目A单价,
    T1.数量 AS 项目A数量,
    T1.总费用 AS 项目A总费用,
    T1.医保基金支付费用 AS 项目A医保支付,
    T2.项目名称 AS 项目B名称,
    T2.单价 AS 项目B单价,
    T2.数量 AS 项目B数量,
    T2.总费用 AS 项目B总费用,
    T2.医保基金支付费用 AS 项目B医保支付,
    T1.参保地,
    T1.参保类别
FROM (
    -- 项目A：鼻内镜检查(310402001) - 住院患者
    SELECT 
        CAST(b.PATIENT_NAME AS VARCHAR(100)) AS 患者姓名,
        CAST(b.PATIENT_GENDER AS VARCHAR(10)) AS 患者性别,
        CAST(b.ID_CARD AS VARCHAR(100)) AS 身份证号,
        CAST('住院' AS VARCHAR(10)) AS 就诊类别,
        CAST(COALESCE(d.ADMISSION_DISEASE_NAME, '') AS VARCHAR(200)) AS 入院诊断,
        CAST(COALESCE(d.DISCHARGE_DISEASE_NAME_MAIN, '') AS VARCHAR(200)) AS 出院诊断,
        a.USAGE_DATE AS 计费时间,
        CAST(a.EXCUTE_DEPT_NAME AS VARCHAR(100)) AS 计费科室,
        CAST(a.ITEM_NAME AS VARCHAR(100)) AS 项目名称,
        CAST(a.UNIT_PRICE AS VARCHAR(20)) AS 单价,
        CAST(a.NUM AS VARCHAR(20)) AS 数量,
        CAST(a.COST AS VARCHAR(20)) AS 总费用,
        CAST(a.BMI_CONVERED_AMOUNT AS VARCHAR(20)) AS 医保基金支付费用,
        CAST(CASE 
            WHEN b.IF_LOCAL_FLAG = '本地' THEN '省内'
            WHEN b.IF_LOCAL_FLAG = '异地' THEN '省外'
            ELSE COALESCE(b.IF_LOCAL_FLAG, '未知')
        END AS VARCHAR(50)) AS 参保地,
        CAST(COALESCE(b.BENEFIT_TYPE, '') AS VARCHAR(50)) AS 参保类别,
        CAST(a.PATIENT_ID AS VARCHAR(100)) AS 个人ID,
        a.USAGE_DATE AS 计费小时,
        CAST(b.DISCHARGE_DEPT_NAME AS VARCHAR(100)) AS 科室名称
    FROM flycheck_realtime.settle_zy_detail a
    INNER JOIN flycheck_realtime.settle_zy b ON a.zyh = b.zyh AND a.hisid = b.hisid
    LEFT JOIN flycheck_realtime.settle_zy_diagnosis d ON b.hisid = d.hisid AND b.zyh = d.zyh
    WHERE a.bill_date >= '2022-12-01' 
        AND a.bill_date < '2025-05-27'
        AND b.bill_date >= '2022-12-01' 
        AND b.bill_date < '2025-05-27'
        AND a.ITEM_ID_HOSP = '310402001'  -- 鼻内镜检查
        AND (b.DISCHARGE_DEPT_NAME LIKE '%耳鼻喉%' OR b.DISCHARGE_DEPT_NAME LIKE '%ENT%')
    
    UNION ALL
    
    -- 项目A：鼻内镜检查(310402001) - 门诊患者
    SELECT 
        CAST(b.PATIENT_NAME AS VARCHAR(100)) AS 患者姓名,
        CAST(b.PATIENT_GENDER AS VARCHAR(10)) AS 患者性别,
        CAST(b.ID_CARD AS VARCHAR(100)) AS 身份证号,
        CAST('门诊' AS VARCHAR(10)) AS 就诊类别,
        CAST(COALESCE(b.ADMISSION_DISEASE_NAME, '') AS VARCHAR(200)) AS 入院诊断,
        CAST(COALESCE(b.ADMISSION_DISEASE_NAME, '') AS VARCHAR(200)) AS 出院诊断,
        a.USAGE_DATE AS 计费时间,
        CAST(a.EXCUTE_DEPT_NAME AS VARCHAR(100)) AS 计费科室,
        CAST(a.ITEM_NAME AS VARCHAR(100)) AS 项目名称,
        CAST(a.UNIT_PRICE AS VARCHAR(20)) AS 单价,
        CAST(a.NUM AS VARCHAR(20)) AS 数量,
        CAST(a.COST AS VARCHAR(20)) AS 总费用,
        CAST(a.BMI_CONVERED_AMOUNT AS VARCHAR(20)) AS 医保基金支付费用,
        CAST(CASE 
            WHEN b.IF_LOCAL_FLAG = '本地' THEN '省内'
            WHEN b.IF_LOCAL_FLAG = '异地' THEN '省外'
            ELSE COALESCE(b.IF_LOCAL_FLAG, '未知')
        END AS VARCHAR(50)) AS 参保地,
        CAST(COALESCE(b.BENEFIT_TYPE, '') AS VARCHAR(50)) AS 参保类别,
        CAST(a.PATIENT_ID AS VARCHAR(100)) AS 个人ID,
        a.USAGE_DATE AS 计费小时,
        CAST(b.ADMISSION_DEPT_NAME AS VARCHAR(100)) AS 科室名称
    FROM flycheck_realtime.settle_mz_detail a
    INNER JOIN flycheck_realtime.settle_mz b ON a.hisid = b.hisid
    WHERE a.bill_date >= '2022-12-01' 
        AND a.bill_date < '2025-05-27'
        AND b.bill_date >= '2022-12-01' 
        AND b.bill_date < '2025-05-27'
        AND a.ITEM_ID_HOSP = '310402001'  -- 鼻内镜检查
        AND (b.ADMISSION_DEPT_NAME LIKE '%耳鼻喉%' OR b.ADMISSION_DEPT_NAME LIKE '%ENT%')
) T1

INNER JOIN (
    -- 项目B：表面麻醉(33010000101) - 住院患者
    SELECT 
        CAST(a.PATIENT_ID AS VARCHAR(100)) AS 个人ID,
        a.USAGE_DATE AS 计费小时,
        CAST(a.ITEM_NAME AS VARCHAR(100)) AS 项目名称,
        CAST(a.UNIT_PRICE AS VARCHAR(20)) AS 单价,
        CAST(a.NUM AS VARCHAR(20)) AS 数量,
        CAST(a.COST AS VARCHAR(20)) AS 总费用,
        CAST(a.BMI_CONVERED_AMOUNT AS VARCHAR(20)) AS 医保基金支付费用,
        CAST(b.DISCHARGE_DEPT_NAME AS VARCHAR(100)) AS 科室名称
    FROM flycheck_realtime.settle_zy_detail a
    INNER JOIN flycheck_realtime.settle_zy b ON a.zyh = b.zyh AND a.hisid = b.hisid
    WHERE a.bill_date >= '2022-12-01' 
        AND a.bill_date < '2025-05-27'
        AND b.bill_date >= '2022-12-01' 
        AND b.bill_date < '2025-05-27'
        AND a.ITEM_ID_HOSP = '33010000101'  -- 表面麻醉
        AND (b.DISCHARGE_DEPT_NAME LIKE '%耳鼻喉%' OR b.DISCHARGE_DEPT_NAME LIKE '%ENT%')
    
    UNION ALL
    
    -- 项目B：表面麻醉(33010000101) - 门诊患者
    SELECT 
        CAST(a.PATIENT_ID AS VARCHAR(100)) AS 个人ID,
        a.USAGE_DATE AS 计费小时,
        CAST(a.ITEM_NAME AS VARCHAR(100)) AS 项目名称,
        CAST(a.UNIT_PRICE AS VARCHAR(20)) AS 单价,
        CAST(a.NUM AS VARCHAR(20)) AS 数量,
        CAST(a.COST AS VARCHAR(20)) AS 总费用,
        CAST(a.BMI_CONVERED_AMOUNT AS VARCHAR(20)) AS 医保基金支付费用,
        CAST(b.ADMISSION_DEPT_NAME AS VARCHAR(100)) AS 科室名称
    FROM flycheck_realtime.settle_mz_detail a
    INNER JOIN flycheck_realtime.settle_mz b ON a.hisid = b.hisid
    WHERE a.bill_date >= '2022-12-01' 
        AND a.bill_date < '2025-05-27'
        AND b.bill_date >= '2022-12-01' 
        AND b.bill_date < '2025-05-27'
        AND a.ITEM_ID_HOSP = '33010000101'  -- 表面麻醉
        AND (b.ADMISSION_DEPT_NAME LIKE '%耳鼻喉%' OR b.ADMISSION_DEPT_NAME LIKE '%ENT%')
) T2 ON T1.个人ID = T2.个人ID 
    AND TO_CHAR(T1.计费小时, 'YYYY-MM-DD HH24') = TO_CHAR(T2.计费小时, 'YYYY-MM-DD HH24')  -- 同一小时
    AND T1.科室名称 = T2.科室名称

ORDER BY T1.身份证号, T1.计费时间;

-- 修复说明：
-- 1. 所有字段都使用 CAST 函数明确转换为 VARCHAR 类型
-- 2. 为每个 VARCHAR 指定了合适的长度
-- 3. 确保 UNION ALL 两边对应字段的类型完全一致
-- 4. 解决了 numeric 和 character varying 类型不匹配的问题 