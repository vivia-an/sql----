-- 根据输血报表LIS部分SQL输出创建StarRocks建表语句
-- 基于 运管输血报表sql-报表-lis部分.sql 的输出字段

CREATE TABLE `blood_analysis_report_lis` (
    -- 基础维度字段（与SQL输出顺序完全一致）
    `周期名称` varchar(50) NULL COMMENT "周期名称（上月/上上月/去年同期/环比/同比）",
    `周期` varchar(50) NULL COMMENT "统计周期",
    `排序` int(11) NULL COMMENT "排序号：1-上月,2-上上月,3-去年同期,4-环比,5-同比",
    `院区分类` varchar(50) NULL COMMENT "院区分类",
    `运管科室` varchar(50) NULL COMMENT "运管科室",
    
    -- LIS检验项目统计字段（严格按照SQL输出顺序）
    `样本数` decimal(20, 2) NULL COMMENT "样本数量",
    `项目数` decimal(20, 2) NULL COMMENT "项目数量", 
    `工作量` decimal(20, 2) NULL COMMENT "工作量",
    `卡费血型数` decimal(20, 2) NULL COMMENT "卡费血型数量",
    `抗A_抗B血清配血型` decimal(20, 2) NULL COMMENT "抗A、抗B血清配血型数量",
    `脉血负血型复查量` decimal(20, 2) NULL COMMENT "脉血负血型复查数量",
    `抗体筛查` decimal(20, 2) NULL COMMENT "抗体筛查数量",
    `凝聚胺血` decimal(20, 2) NULL COMMENT "凝聚胺血数量",
    `卡式配血` decimal(20, 2) NULL COMMENT "卡式配血数量",
    `直接抗人球蛋白` decimal(20, 2) NULL COMMENT "直接抗人球蛋白数量",
    `抗体全套` decimal(20, 2) NULL COMMENT "抗体全套数量",
    `血小板交叉` decimal(20, 2) NULL COMMENT "血小板交叉数量",
    `抗体鉴定` decimal(20, 2) NULL COMMENT "抗体鉴定数量",
    `血小板抗体` decimal(20, 2) NULL COMMENT "血小板抗体数量",
    `抗体效价` decimal(20, 2) NULL COMMENT "抗体效价数量",
    `Rh分型` decimal(20, 2) NULL COMMENT "Rh分型数量",
    `血小板配血型复查量` decimal(20, 2) NULL COMMENT "血小板配血型复查数量",
    `血库计算` decimal(20, 2) NULL COMMENT "血库计算数量（综合血库统计）"
) ENGINE=OLAP
UNIQUE KEY (`周期名称`)
DISTRIBUTED BY HASH(`周期名称`) BUCKETS 3
PROPERTIES (
    "replication_num" = "3",
    "in_memory" = "false",
    "enable_persistent_index" = "false",
    "replicated_storage" = "true",
    "compression" = "LZ4"
);