
    -- 查询23年以后每天只做单次胸部CT的人数
WITH patient_daily_ct AS (
    SELECT 
        b.f_stu_exam_date AS "执行日期",
        a.patient_id AS "患者ID",
        COUNT(*) AS "当日CT胸部普通扫描次数"
    FROM 
        hid0101_mssql_ris_ris.v_ris_reg AS a
    LEFT JOIN 
        hid0101_mssql_ris_ris.v_ris_exam AS b 
        ON a.order_number = b.f_stu_char405
    WHERE 
        -- 2023年以后（字符串比较，格式：2023.01.01）
        b.f_stu_exam_date >= '2023.01.01'
        -- 检查项目为CT胸部普通扫描 
--     and       a.f_place_name = 'CT胸部普通扫描'
        AND b.F_CLASS_ID='11'
        -- 执行日期不为空
        AND b.f_stu_exam_date IS NOT NULL
        AND LTRIM(b.f_stu_exam_date) <> ''
        AND RTRIM(b.f_stu_exam_date) <> ''
        and b.f_stu_char406 ='2'
        and b.F_MODALITY_ID='1'
        and b.F_PSOURCE_ID<> '6'
        and b.F_STATUS_ID='12'
    GROUP BY 
        b.f_stu_exam_date, 
        a.patient_id
    HAVING 
        COUNT(*)= 1
)
select sum("只做单次胸部CT的人数") from (
SELECT 
    "执行日期",
    COUNT(DISTINCT "患者ID") AS "只做单次胸部CT的人数"
FROM 
    patient_daily_ct
GROUP BY 
    "执行日期"
ORDER BY 
    "执行日期"
) t

======
1528610

=====

719689

==== 
1552000



-- 查询23年以后每天只做单次腹部CT的人数
WITH patient_daily_ct AS (
    SELECT 
        b.f_stu_exam_date AS "执行日期",
        a.patient_id AS "患者ID",
        COUNT(*) AS "当日CT腹部普通扫描次数"
    FROM 
        hid0101_mssql_ris_ris.v_ris_reg AS a
    LEFT JOIN 
        hid0101_mssql_ris_ris.v_ris_exam AS b 
        ON a.order_number = b.f_stu_char405
    WHERE 
        -- 2023年以后（字符串比较，格式：2023.01.01）
        b.f_stu_exam_date >= '2023.01.01'
        -- 检查项目为CT腹部普通扫描
             AND b.F_CLASS_ID='10'
--              AND a.f_place_name = 'CT腹部普通扫描'
        -- 执行日期不为空
        AND b.f_stu_exam_date IS NOT NULL
        AND LTRIM(b.f_stu_exam_date) <> ''
        AND RTRIM(b.f_stu_exam_date) <> ''
        and b.f_stu_char406 = '2'
        and b.F_MODALITY_ID='1'
        and b.F_PSOURCE_ID<> '6'
        and b.F_STATUS_ID='12'
    GROUP BY 
        b.f_stu_exam_date, 
        a.patient_id
    HAVING 
        COUNT(*) = 1
)
select sum("只做单次腹部CT的人数") from (
SELECT 
    "执行日期",
    COUNT(DISTINCT "患者ID") AS "只做单次腹部CT的人数"
FROM 
    patient_daily_ct
GROUP BY 
    "执行日期"
ORDER BY 
    "执行日期"
) t

======
713665
============

==============
720398


  -- 统计23年以后做过多次（>=2次）胸腹CT的患者人数
WITH patient_exam_count AS (
    SELECT 
        a.patient_id AS "患者ID",
        COUNT(DISTINCT a.order_number) AS "检查总次数"
    FROM 
        hid0101_mssql_ris_ris.v_ris_reg AS a
    LEFT JOIN 
        hid0101_mssql_ris_ris.v_ris_exam AS b 
        ON a.order_number = b.f_stu_char405
    WHERE 
        -- 2023年以后
        b.f_stu_exam_date >= '2023.01.01'
        
          AND b.F_CLASS_ID in ('10','11')
--       and a.f_place_name in ('CT腹部普通扫描','CT胸部普通扫描')
        -- 执行日期不为空
        AND b.f_stu_exam_date IS NOT NULL
        AND LTRIM(b.f_stu_exam_date) <> ''
        AND RTRIM(b.f_stu_exam_date) <> ''
        
        and b.F_MODALITY_ID='1'
        and b.F_PSOURCE_ID<> '6'
           and b.f_stu_char406 = '2' -- 阳性
        and b.F_STATUS_ID='12'
    GROUP BY 
        a.patient_id
    HAVING 
        COUNT(DISTINCT a.order_number) >= 2
)
SELECT 
    COUNT(DISTINCT "患者ID") AS "多次影像检查患者人数"
FROM 
    patient_exam_count


注意
============
条件解释

WHERE F_STU_EXAM_DATE='2025.11.01'--检查日期
AND F_MODALITY_ID=1--CT检查
AND F_PSOURCE_ID<>6--不包括体检
AND F_CLASS_ID=10--腹部检查,9肌骨检查，10腹部检查，11胸部检查
AND F_STATUS_ID=12--报告审核
AND F_STU_IMG_COUNT>0--有图