-- 2025年全年病案首页三级手术例次统计
-- 需求：统计2025年全年病案首页填写的三级手术手术例次（不分科室）
-- 
-- 数据血缘：
--   datacenter_db.MR_FPOPS (病案首页手术表)
--     - MR_FPOPS_OPSLevelCode: 手术级别代码 ('3'=三级手术)
--     - MR_FPOPS_OPSDtTm: 手术时间 (VARCHAR类型)
--     - MR_FPOPS_IsDeleted: 逻辑删除标识 ('0'=未删除)

SELECT 
    '2025年' AS "统计年份",
    '三级手术' AS "手术级别",
    COUNT(*) AS "手术例次"
FROM datacenter_db.MR_FPOPS ops
WHERE ops."MR_FPOPS_OPSLevelCode" = '3'                           -- 三级手术
    AND SUBSTRING(CAST(ops."MR_FPOPS_OPSDtTm" AS VARCHAR), 1, 4) = '2025'  -- 2025年
    AND ops."MR_FPOPS_IsDeleted" = '0'                            -- 未删除

-- 字段来源说明：
-- 手术例次：COUNT(*) 统计MR_FPOPS表中符合条件的手术记录数
-- 筛选条件：
--   1. 手术级别代码 = '3' (三级手术)
--   2. 手术时间年份 = 2025
--   3. 逻辑删除 = '0' (未删除)


SELECT 
    '2025年' AS "统计年份",
    '三级手术' AS "手术级别",
    COUNT(DISTINCT ops."MR_FPOPS_VisitID") AS "人次"
FROM datacenter_db.MR_FPOPS ops
WHERE ops."MR_FPOPS_OPSLevelCode" = '3'                           -- 三级手术
    AND SUBSTRING(CAST(ops."MR_FPOPS_OPSDtTm" AS VARCHAR), 1, 4) = '2025'  -- 2025年
    AND ops."MR_FPOPS_IsDeleted" = '0'                            -- 未删除


    明白了，有两个调整点：
按人次统计：用 COUNT(DISTINCT "MR_FPOPS_VisitID") 按就诊ID去重，一个住院患者多台三级手术只算1人次
加上院区筛选：增加 MR_FPOPS_MedOrgCode = 'HID0101' 条件
修改后的SQL应该是：
SELECT     '2025年' AS "统计年份",    '三级手术' AS "手术级别",    COUNT(DISTINCT ops."MR_FPOPS_VisitID") AS "手术人次"FROM datacenter_db.MR_FPOPS opsWHERE ops."MR_FPOPS_OPSLevelCode" = '3'                           -- 三级手术    AND ops."MR_FPOPS_MedOrgCode" = 'HID0101'                     -- 院区筛选    AND SUBSTRING(CAST(ops."MR_FPOPS_OPSDtTm" AS VARCHAR), 1, 4) = '2025'  -- 2025年    AND ops."MR_FPOPS_IsDeleted" = '0'                            -- 未删除
差异说明：
统计方式	SQL	含义
手术例次	COUNT(*)	每条手术记录算1例
手术人次	COUNT(DISTINCT VisitID)	每个住院患者算1人次
