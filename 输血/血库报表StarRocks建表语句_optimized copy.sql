-- 根据血库优化SQL输出创建StarRocks建表语句
-- 基于 运管输血报表sql-报表-血库_stage_optimized.sql 的输出字段

CREATE TABLE `blood_transfusion_report_blood_bank` (
    -- 基础维度字段（与SQL输出顺序完全一致）
    统计月 varchar(50) NOT NULL COMMENT "统计月份",
    院区分类 varchar(50) NOT NULL COMMENT "院区分类", 
    运管科室 varchar(50) NOT NULL COMMENT "运管科室",
    周期 varchar(50) NULL COMMENT "统计周期",
    周期名称 varchar(50) NULL COMMENT "周期名称(上月/上上月/去年同期/环比/同比)",
    排序 decimal(20, 2) NULL COMMENT "排序号",
    
    -- 血液统计字段（严格按照SQL输出顺序和字段名）
    入库血液 decimal(20, 2) NULL COMMENT "入库血液袋数汇总",
    出库血液 decimal(20, 2) NULL COMMENT "出库血液袋数汇总",
    
    -- 红细胞相关统计（注意字段名带"-"）
    红细胞入库 decimal(20, 2) NULL COMMENT "红细胞入库袋数",
    红细胞出库 decimal(20, 2) NULL COMMENT "红细胞出库袋数", 
    `红细胞入库-量` decimal(20, 2) NULL COMMENT "红细胞入库数量",
    `红细胞出库-量` decimal(20, 2) NULL COMMENT "红细胞出库数量",
    
    -- 冷沉淀相关统计
    冷沉淀入库 decimal(20, 2) NULL COMMENT "冷沉淀入库袋数",
    冷沉淀出库 decimal(20, 2) NULL COMMENT "冷沉淀出库袋数",
    
    -- 血浆相关统计（注意字段名带"-"）
    `血浆入库-量` decimal(20, 2) NULL COMMENT "血浆入库数量",  
    血浆出库 decimal(20, 2) NULL COMMENT "血浆出库袋数",
    
    -- 血小板相关统计（注意字段名带"-"）
    血小板入库 decimal(20, 2) NULL COMMENT "血小板入库袋数",
    血小板出库 decimal(20, 2) NULL COMMENT "血小板出库袋数",
    `血小板出库-量` decimal(20, 2) NULL COMMENT "血小板出库数量",
    全院调剂血小板次数 decimal(20, 2) NULL COMMENT "全院调剂血小板次数(血小板出库袋数*3)",
    
    -- 手术相关统计
    周末加班手术台次 decimal(20, 2) NULL COMMENT "周末加班手术台次",
    
    -- 收入统计
    配血检收入 decimal(20, 2) NULL COMMENT "配血检验收入"
) ENGINE=OLAP
UNIQUE KEY (统计月, 院区分类, 运管科室, 周期, 周期名称, 排序) BUCKETS 3
DISTRIBUTED BY HASH(统计月, 院区分类, 运管科室, 周期) BUCKETS 3
PROPERTIES (
    "replication_num" = "3",
    "in_memory" = "false",
    "enable_persistent_index" = "false",
    "replicated_storage" = "true",
    "compression" = "LZ4"
);