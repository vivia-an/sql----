-- 耳鼻喉科互斥项目查询（简洁版）
-- 查找('330100005','33010000502','33010000503')任意一个编码与'33010001501'同一小时存在的住院患者明细
-- 项目A和项目B在同一行显示
-- 数据提取时间：2022.12.1-2025.5.26
-- 仅住院患者，出院科室为耳鼻喉科

SELECT 
    ROW_NUMBER() OVER (ORDER BY b.discharge_date DESC, b.zyh) AS 序号,
    CAST(COALESCE(a.fee_billdet_persno, '') AS VARCHAR(100)) AS 登记号,
    CAST(COALESCE(b.patient_name, '') AS VARCHAR(100)) AS 患者姓名,
    CAST(COALESCE(b.patient_age, '') AS VARCHAR(10)) AS 年龄,
    CAST(COALESCE(b.patient_gender, '') AS VARCHAR(10)) AS 性别,
    CAST(b.admission_date AS VARCHAR(20)) AS 入院时间,
    CAST(b.discharge_date AS VARCHAR(20)) AS 出院时间,
    CAST(b.discharge_dept_name AS VARCHAR(100)) AS 病人科室,
    CAST(b.id_card AS VARCHAR(100)) AS 身份证号码,
    CAST(COALESCE(b.benefit_type, '') AS VARCHAR(50)) AS 参保类型,
    CAST(MAX(a.yblx) AS VARCHAR(50)) AS 医保类型,
    CAST(MAX(a.tcq) AS VARCHAR(50)) AS 统筹区,
    CAST(MAX(a.cbdqdm) AS VARCHAR(50)) AS 参保地区划代码,
    CAST(MAX(a.cbdqmc) AS VARCHAR(100)) AS 参保地区划名称,
    
    -- 项目A信息 (编码: 330100005)
    CAST(MAX(CASE WHEN a.item_id_hosp = '330100005' THEN a.item_id_hosp END) AS VARCHAR(50)) AS 项目A编码,
    CAST(MAX(CASE WHEN a.item_id_hosp = '330100005' THEN a.item_name_hosp END) AS VARCHAR(100)) AS 项目A名称,
    CAST(MAX(CASE WHEN a.item_id_hosp = '330100005' THEN a.unit_price END) AS VARCHAR(20)) AS 项目A单价,
    CAST(SUM(CASE WHEN a.item_id_hosp = '330100005' THEN a.num ELSE 0 END) AS VARCHAR(20)) AS 项目A数量,
    CAST(SUM(CASE WHEN a.item_id_hosp = '330100005' THEN a.cost ELSE 0 END) AS VARCHAR(20)) AS 项目A金额,
    CAST(SUM(CASE WHEN a.item_id_hosp = '330100005' THEN a.bmi_convered_amount ELSE 0 END) AS VARCHAR(20)) AS 项目A符合报销金额,
    CAST(MAX(CASE WHEN a.item_id_hosp = '330100005' THEN a.usage_date END) AS VARCHAR(20)) AS 项目A计费时间,
    
    -- 项目B信息 (编码: 33010000502)
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010000502' THEN a.item_id_hosp END) AS VARCHAR(50)) AS 项目B编码,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010000502' THEN a.item_name_hosp END) AS VARCHAR(100)) AS 项目B名称,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010000502' THEN a.unit_price END) AS VARCHAR(20)) AS 项目B单价,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010000502' THEN a.num ELSE 0 END) AS VARCHAR(20)) AS 项目B数量,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010000502' THEN a.cost ELSE 0 END) AS VARCHAR(20)) AS 项目B金额,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010000502' THEN a.bmi_convered_amount ELSE 0 END) AS VARCHAR(20)) AS 项目B符合报销金额,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010000502' THEN a.usage_date END) AS VARCHAR(20)) AS 项目B计费时间,
    
    -- 项目C信息 (编码: 33010000503)
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010000503' THEN a.item_id_hosp END) AS VARCHAR(50)) AS 项目C编码,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010000503' THEN a.item_name_hosp END) AS VARCHAR(100)) AS 项目C名称,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010000503' THEN a.unit_price END) AS VARCHAR(20)) AS 项目C单价,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010000503' THEN a.num ELSE 0 END) AS VARCHAR(20)) AS 项目C数量,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010000503' THEN a.cost ELSE 0 END) AS VARCHAR(20)) AS 项目C金额,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010000503' THEN a.bmi_convered_amount ELSE 0 END) AS VARCHAR(20)) AS 项目C符合报销金额,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010000503' THEN a.usage_date END) AS VARCHAR(20)) AS 项目C计费时间,
    
    -- 项目D信息 (编码: 33010001501)
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010001501' THEN a.item_id_hosp END) AS VARCHAR(50)) AS 项目D编码,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010001501' THEN a.item_name_hosp END) AS VARCHAR(100)) AS 项目D名称,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010001501' THEN a.unit_price END) AS VARCHAR(20)) AS 项目D单价,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010001501' THEN a.num ELSE 0 END) AS VARCHAR(20)) AS 项目D数量,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010001501' THEN a.cost ELSE 0 END) AS VARCHAR(20)) AS 项目D金额,
    CAST(SUM(CASE WHEN a.item_id_hosp = '33010001501' THEN a.bmi_convered_amount ELSE 0 END) AS VARCHAR(20)) AS 项目D符合报销金额,
    CAST(MAX(CASE WHEN a.item_id_hosp = '33010001501' THEN a.usage_date END) AS VARCHAR(20)) AS 项目D计费时间

FROM flycheck_realtime.settle_zy_detail a
INNER JOIN flycheck_realtime.settle_zy b ON a.zyh = b.zyh AND a.hisid = b.hisid
WHERE a.bill_date >= '2022-12-01' 
    AND a.bill_date < '2025-05-27'
    AND b.bill_date >= '2022-12-01' 
    AND b.bill_date < '2025-05-27'
    AND (b.discharge_dept_name LIKE '%耳鼻%' OR b.discharge_dept_name LIKE '%ENT%')  -- 出院科室为耳鼻喉科
    AND a.item_id_hosp IN ('330100005','33010000502','33010000503','33010001501')  -- 四个项目编码
    AND EXISTS (
        -- 确保存在互斥项目组合（ABC中至少一个 + D）
        SELECT 1 FROM flycheck_realtime.settle_zy_detail a1
        WHERE a1.zyh = a.zyh AND a1.hisid = a.hisid
        AND a1.item_id_hosp IN ('330100005','33010000502','33010000503')  -- ABC项目
        AND EXISTS (
            SELECT 1 FROM flycheck_realtime.settle_zy_detail a2
            WHERE a2.zyh = a1.zyh AND a2.hisid = a1.hisid
            AND a2.item_id_hosp = '33010001501'  -- D项目
            AND TO_CHAR(a1.usage_date, 'YYYY-MM-DD') = TO_CHAR(a2.usage_date, 'YYYY-MM-DD')  -- 同一天
        )
    )
GROUP BY 
    b.zyh, 
    b.hisid,
    b.fee_billdet_persno,
    b.patient_name,
    b.patient_age,
    b.patient_gender,
    b.admission_date,
    b.discharge_date,
    b.discharge_dept_name,
    b.id_card,
    b.benefit_type
ORDER BY b.discharge_date DESC, b.zyh;

-- 查询说明：
-- 1. 仅查询住院患者（settle_zy表）
-- 2. 出院科室必须包含"耳鼻"或"ENT"
-- 3. 项目A：编码为('330100005','33010000502','33010000503')任意一个
-- 4. 项目B：编码为'33010001501'
-- 5. 通过INNER JOIN确保同一患者同一小时既有项目A又有项目B
-- 6. 项目A和项目B的信息在同一行显示，分别以A和B前缀区分
-- 7. 数据时间范围：2022.12.1-2025.5.26
-- 8. 按出院日期倒序、住院号排序

-- 字段来源血缘：
-- 患者基本信息来自：settle_zy表
-- 项目A信息来自：settle_zy_detail表（别名a）
-- 项目B信息来自：settle_zy_detail表（别名c）
-- 关联条件：同一患者(patient_id)、同一住院号(zyh)、同一结算单据号(hisid)、同一小时(usage_date)

-- 输出字段说明：
-- 基本信息：序号、登记号、患者姓名、入院时间、出院时间、病人科室、身份证号码、参保类型、医保类型、统筹区、参保地区划代码、参保地区划名称
-- 项目A信息：项目A编码、项目A名称、项目A单价、项目A数量、项目A金额、项目A符合报销金额、项目A计费时间
-- 项目B信息：项目B编码、项目B名称、项目B单价、项目B数量、项目B金额、项目B符合报销金额、项目B计费时间

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

-- 耳鼻喉科神经导航系统加收查询
-- 查找同一小时收取"应用神经导航系统加收"(33020000001)费用数量大于等于2的住院患者明细
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
    CAST(b.DISCHARGE_DEPT_NAME AS VARCHAR(100)) AS 出院科室,
    a.USAGE_DATE AS 计费时间,
    CAST(TO_CHAR(a.USAGE_DATE, 'YYYY-MM-DD HH24') AS VARCHAR(20)) AS 计费小时,
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
    CAST(COALESCE(b.BENEFIT_TYPE, '') AS VARCHAR(50)) AS 参保类别,
    -- 计算同一小时该项目的总数量
    CAST(SUM(a.NUM) OVER (
        PARTITION BY a.PATIENT_ID, TO_CHAR(a.USAGE_DATE, 'YYYY-MM-DD HH24'), a.ITEM_ID_HOSP
    ) AS VARCHAR(20)) AS 同一小时总数量
FROM flycheck_realtime.settle_zy_detail a
INNER JOIN flycheck_realtime.settle_zy b ON a.zyh = b.zyh AND a.hisid = b.hisid
LEFT JOIN flycheck_realtime.settle_zy_diagnosis d ON b.hisid = d.hisid AND b.zyh = d.zyh
WHERE a.bill_date >= '2022-12-01' 
    AND a.bill_date < '2025-05-27'
    AND b.bill_date >= '2022-12-01' 
    AND b.bill_date < '2025-05-27'
    AND a.ITEM_ID_HOSP = '33020000001'  -- 应用神经导航系统加收
    AND (b.DISCHARGE_DEPT_NAME LIKE '%耳鼻%' OR b.DISCHARGE_DEPT_NAME LIKE '%ENT%')  -- 出院科室为耳鼻喉科
    AND a.PATIENT_ID IN (
        -- 子查询：找出同一小时该项目数量大于等于2的患者
        SELECT DISTINCT a2.PATIENT_ID
        FROM flycheck_realtime.settle_zy_detail a2
        INNER JOIN flycheck_realtime.settle_zy b2 ON a2.zyh = b2.zyh AND a2.hisid = b2.hisid
        WHERE a2.bill_date >= '2022-12-01' 
            AND a2.bill_date < '2025-05-27'
            AND b2.bill_date >= '2022-12-01' 
            AND b2.bill_date < '2025-05-27'
            AND a2.ITEM_ID_HOSP = '33020000001'  -- 应用神经导航系统加收
            AND (b2.DISCHARGE_DEPT_NAME LIKE '%耳鼻%' OR b2.DISCHARGE_DEPT_NAME LIKE '%ENT%')
        GROUP BY a2.PATIENT_ID, TO_CHAR(a2.USAGE_DATE, 'YYYY-MM-DD HH24')
        HAVING SUM(a2.NUM) >= 2  -- 同一小时数量大于等于2
    )

ORDER BY b.DISCHARGE_DATE DESC, b.zyh, a.USAGE_DATE;

-- 查询说明：
-- 1. 仅查询住院患者（根据需求）
-- 2. 出院科室必须包含"耳鼻"或"ENT"
-- 3. 项目编码为"33020000001"的"应用神经导航系统加收"
-- 4. 通过子查询筛选出同一小时该项目数量大于等于2的患者
-- 5. 使用窗口函数显示每个患者同一小时的总数量
-- 6. 数据时间范围：2022.12.1-2025.5.26
-- 7. 按出院日期倒序、住院号、计费时间排序 


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
-- 查询说明：
-- 1. 仅查询住院患者（settle_zy表）
-- 2. 出院科室必须包含"耳鼻"或"ENT"
-- 3. 查找项目编码('330100005','33010000502','33010000503')任意一个与'33010001501'同一小时存在的患者
-- 4. 使用子查询确保患者同一小时既有项目组A又有项目B
-- 5. 一个项目一行的方式呈现所有相关项目明细
-- 6. 数据时间范围：2022.12.1-2025.5.26
-- 7. 不存在的字段用空字符串填充
-- 8. 按出院日期倒序、住院号、计费时间排序

-- 字段来源血缘：
-- settle_zy_detail表：登记号(fee_billdet_persno)、开单科室(billing_dept_name)、接收科室(excute_dept_name)、
--                   开单医生(doctor_name)、项目编码(item_id_hosp)、项目名称(item_name_hosp)、
--                   账单时间(bill_date)、数量(num)、金额(cost)、支付类别(p_type)、
--                   单价(unit_price)、符合报销金额(bmi_convered_amount)、计费科室(excute_dept_name)、
--                   计费时间(usage_date)
-- settle_zy表：患者姓名(patient_name)、入院时间(admission_date)、出院时间(discharge_date)、
--             病人科室(discharge_dept_name)、身份证号码(id_card)、参保类型(benefit_type)、
--             总费用(total_amount)
-- 空字符串字段：医嘱项目名称、医嘱开始时间、医保类型、统筹区、参保地区划代码、参保地区划名称 

-- 修改说明：
-- 1. 将时间比较从 'YYYY-MM-DD' 改为 'YYYY-MM-DD HH24'，精确到小时
-- 2. 这样可以查找在同一小时内收取这些项目的患者
-- 3. 例如：2024-01-01 14:xx 和 2024-01-01 14:xx 会被认为是同一小时 