-- StarRocks建表语句：运管科LIS报表整体同比环比分析表
-- 数据来源：运管科lis报表整体 同比环比..sql

CREATE TABLE IF NOT EXISTS lis_operational_report (
    -- 基础维度字段
    `运管科室` VARCHAR(50) COMMENT '运管科室名称，固定值：实验医学科(检验科)',
    `运管院区` VARCHAR(20) COMMENT '运管院区：主院区/温江院区/天府院区/合计/本部实际量',
    `亚专业组` VARCHAR(50) COMMENT '亚专业组名称：具体实验室名称或汇总标识',
    
    -- 当月数据
    `标本数` BIGINT COMMENT '当月标本数量',
    `项目数` BIGINT COMMENT '当月项目数量(工作量)',
    `总收入` DECIMAL(15,2) COMMENT '当月总收入金额',
    
    -- 上月数据
    `上月标本数` BIGINT COMMENT '上月标本数量',
    `上月项目数` BIGINT COMMENT '上月项目数量',
    `上月总收入` DECIMAL(15,2) COMMENT '上月总收入金额',
    
    -- 去年同期数据
    `去年同期标本数` BIGINT COMMENT '去年同期标本数量',
    `去年同期项目数` BIGINT COMMENT '去年同期项目数量',
    `去年同期总收入` DECIMAL(15,2) COMMENT '去年同期总收入金额',
    
    -- 收入占比
    `总收入占比%` DECIMAL(5,2) COMMENT '当月总收入占比百分比',
    `上月总收入占比%` DECIMAL(5,2) COMMENT '上月总收入占比百分比',
    `去年同期总收入占比%` DECIMAL(5,2) COMMENT '去年同期总收入占比百分比',
    
    -- 环比增长率
    `标本数环比增长率%` DECIMAL(10,2) COMMENT '标本数环比增长率百分比',
    `项目数环比增长率%` DECIMAL(10,2) COMMENT '项目数环比增长率百分比',
    `收入环比增长率%` DECIMAL(10,2) COMMENT '收入环比增长率百分比',
    
    -- 同比增长率
    `标本数同比增长率%` DECIMAL(10,2) COMMENT '标本数同比增长率百分比',
    `项目数同比增长率%` DECIMAL(10,2) COMMENT '项目数同比增长率百分比',
    `收入同比增长率%` DECIMAL(10,2) COMMENT '收入同比增长率百分比',
    
    -- 数据处理时间戳
    `report_date` DATE COMMENT '报表统计日期',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP() COMMENT '数据创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '数据更新时间'
) 
ENGINE=OLAP
DUPLICATE KEY(`运管科室`, `运管院区`, `亚专业组`, `report_date`)
COMMENT "LIS运管科报表整体同比环比分析表"
DISTRIBUTED BY HASH(`运管院区`, `亚专业组`) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "storage_format" = "DEFAULT",
    "compression" = "LZ4"
);

-- 创建索引以提高查询性能
-- ALTER TABLE lis_operational_report ADD INDEX idx_report_date (report_date) USING BITMAP COMMENT '报表日期索引';
-- ALTER TABLE lis_operational_report ADD INDEX idx_campus (运管院区) USING BITMAP COMMENT '院区索引';