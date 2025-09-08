-- 医嘱信息查询SQL - 基于datacenter数据中心
-- 需求：根据病案号查询登记号、就诊号、开单日期、医嘱名、医嘱大类、医嘱小类
-- 血缘分析：病案号字段在datacenter中缺失，使用就诊号作为病案号
-- 优化：添加时间范围过滤(2023-2024年)并减少返回结果数量，解决内存不足问题

SELECT 
    -- 基础信息字段
    ipr."Visit_IPReg_IPRegID" as "登记号",                -- 住院登记ID
    om."Order_Main_VisitNo" as "就诊号",                  -- 就诊号
    CAST(CAST(om."Order_Main_OrderDtTm" AS TIMESTAMP) AS DATE) as "开单日期", -- 开医嘱时间（转换为日期格式）
    
    -- 医嘱相关字段
    om."Order_Main_OrderItemName" as "医嘱名",            -- 医嘱项目名称
    om."Order_Main_OrderPClassName" as "医嘱大类",        -- 医嘱大类名称
    om."Order_Main_OrderSClassName" as "医嘱小类",        -- 医嘱子类名称（医嘱小类）
    
    -- 补充关联字段
    ipr."Visit_IPReg_PersName" as "患者姓名",             -- 患者姓名
    ipr."Visit_IPReg_PersNo" as "人员号",                 -- 人员号
    om."Order_Main_DeptName" as "开单科室",               -- 开单科室
    om."Order_Main_OrderDoctName" as "开医嘱医生",        -- 开医嘱医生姓名
    
    -- 病案号 - 使用就诊号替代
    om."Order_Main_VisitNo" as "病案号"                   -- 使用就诊号作为病案号

FROM datacenter_db."Order_Main" om
LEFT JOIN datacenter_db."Visit_IPReg" ipr 
    ON om."Order_Main_VisitID" = ipr."Visit_IPReg_VisitID"

WHERE 1=1
    AND om."Order_Main_VisitNo" IS NOT NULL              -- 确保就诊号不为空
    AND ipr."Visit_IPReg_IPRegID" IS NOT NULL            -- 确保登记号不为空
    AND om."Order_Main_OrderDtTm" IS NOT NULL            -- 确保开单日期不为空
    AND CAST(CAST(om."Order_Main_OrderDtTm" AS TIMESTAMP) AS DATE) >= CAST('2023-01-01' AS DATE)  -- 添加开始日期限制
    AND CAST(CAST(om."Order_Main_OrderDtTm" AS TIMESTAMP) AS DATE) <= CAST('2024-12-31' AS DATE)  -- 添加结束日期限制
    
-- 可选过滤条件（根据实际需求调整）
-- AND om."Order_Main_OrderPClassName" IN ('药品医嘱','检查医嘱','检验医嘱') -- 医嘱大类过滤

ORDER BY 
    om."Order_Main_OrderDtTm" DESC,                      -- 按开单时间倒序
    ipr."Visit_IPReg_IPRegID",                           -- 按登记号排序
    om."Order_Main_VisitNo"                              -- 按就诊号排序

LIMIT 500;  -- 减少返回结果数量以避免内存不足