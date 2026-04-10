

SELECT 
    DATE_FORMAT(DATE_PARSE(SUBSTR(r."MT_Report_CheckDtTm", 1, 7), '%Y-%m'), '%Y-%m') AS "月份",
    COUNT(DISTINCT r."MT_Report_VisitID") AS "3天内出报告人次"
FROM 
    datacenter_db."MT_Report" r
INNER JOIN 
    datacenter_db."Visit_Reg" v
    ON CAST(r."MT_Report_VisitID" AS VARCHAR) = CAST(v."Visit_Reg_VisitID" AS VARCHAR)
WHERE 
    -- 逻辑删除筛选
  r."MT_Report_CheckDtTm" >= '2025-01-01'
    AND r."MT_Report_CheckDtTm" < '2025-11-01'
    -- 门诊类型筛选（门诊代码可能为O或OP，根据实际数据调整）
    AND r."MT_Report_VisitTypeCode" IN ('O', 'OP')
    -- 已审核且有审核时间
    AND r."MT_Report_CheckDtTm" IS NOT NULL
    AND TRIM(r."MT_Report_CheckDtTm") <> ''
    -- 挂号时间不为空
    AND v."Visit_Reg_RegDtTm" IS NOT NULL
    AND TRIM(v."Visit_Reg_RegDtTm") <> ''
--    and r.mt_report_reportstatusname = '审核'
    and r.mt_report_medorgcode = 'HID0101'
    -- 3天内出报告：报告审核日期 - 挂号日期 <= 3天
    AND DATE_DIFF('day', 
        DATE(DATE_PARSE(SUBSTR(v."Visit_Reg_RegDtTm", 1, 10), '%Y-%m-%d')),
        DATE(DATE_PARSE(SUBSTR(r."MT_Report_CheckDtTm", 1, 10), '%Y-%m-%d'))
    ) <= 3
GROUP BY 
    DATE_FORMAT(DATE_PARSE(SUBSTR(r."MT_Report_CheckDtTm", 1, 7), '%Y-%m'), '%Y-%m')
ORDER BY 
    "月份" ASC











    SELECT 
    SUBSTR(CAST(o."visitdate" AS VARCHAR), 1, 7) AS "统计月份",
    COUNT(DISTINCT o."VisitNo") AS "门诊就诊人次"
FROM m1.mdr_outpatient o
INNER JOIN (
    -- 子查询：获取有化验/检查/影像收入且费用不为0的就诊号
    SELECT DISTINCT "VisitNo"
    FROM m1.mdr_income
    WHERE "IsDeleted" = '0'
      AND "medorgcode" = 'HID0101'
      AND "CheckPClassName" IN ('化验收入', '检查收入', '影像收入')
      AND CAST("TotalFee" AS DECIMAL(20,4)) <> 0
) inc ON o."VisitNo" = inc."VisitNo"
WHERE  o."MedOrgCode" = 'HID0101'
  AND o."VisitType" = 'O'
  AND SUBSTR(CAST(o."visitdate" AS VARCHAR), 1, 7) >= '2025-01'
  AND SUBSTR(CAST(o."visitdate" AS VARCHAR), 1, 7) <= '2025-10'
GROUP BY SUBSTR(CAST(o."visitdate" AS VARCHAR), 1, 7)
ORDER BY "统计月份";