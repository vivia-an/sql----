-- 运管输血报表SQL结果StarRocks建表语句
-- 根据 运管输血报表sql-报表-lis部分11.sql 的查询结果字段生成
-- 创建时间: 2024-09-24

CREATE TABLE m1.blood_analysis_report_lis (
    -- 基础维度字段
    `周期` VARCHAR(50) COMMENT '统计周期，格式为YYYY-MM',
    `周期名称` VARCHAR(50) COMMENT '周期名称：上月/上上月/去年同期/同比/环比',
    `排序` INT COMMENT '排序字段：1-上月，2-上上月，3-去年同期，4-同比，5-环比',
    `统计月` VARCHAR(50) COMMENT '统计月份，格式为YYYY年-MM月',
    `院区分类` VARCHAR(50) COMMENT '院区分类',
    `运管科室` VARCHAR(50) COMMENT '运管科室名称',
    
    -- 业务指标字段
    `样本数` DECIMAL(18,3) COMMENT '样本总数',
    `项目数` DECIMAL(18,3) COMMENT '项目总数',
    `工作量` DECIMAL(18,3) COMMENT '工作量总数',
    
    -- 血型检测相关指标
    `卡查血型` DECIMAL(18,3) COMMENT '卡查血型检测数量',
    `抗A、抗B血清查血型` DECIMAL(18,3) COMMENT '抗A、抗B血清查血型检测数量',
    `红细胞血型复查` DECIMAL(18,3) COMMENT '红细胞血型复查数量',
    
    -- 配血相关指标  
    `抗体筛查` DECIMAL(18,3) COMMENT '抗体筛查数量',
    `凝聚胺配血` DECIMAL(18,3) COMMENT '凝聚胺配血数量',
    `卡式配血` DECIMAL(18,3) COMMENT '卡式配血数量',
    `直接抗人球蛋白` DECIMAL(18,3) COMMENT '直接抗人球蛋白检测数量',
    `抗体鉴定` DECIMAL(18,3) COMMENT '抗体鉴定数量',
    
    -- 血小板相关指标
    `血小板交叉` DECIMAL(18,3) COMMENT '血小板交叉配血数量',
    `血小板抗体` DECIMAL(18,3) COMMENT '血小板抗体检测数量',
    
    -- 其他专项检测指标
    `抗体效价` DECIMAL(18,3) COMMENT '抗体效价测定数量',
    `Rh分型` DECIMAL(18,3) COMMENT 'Rh分型检测数量',
    `血小板血型复查` DECIMAL(18,3) COMMENT '血小板血型复查数量',
    `吸收放散试验` DECIMAL(18,3) COMMENT '吸收放散试验数量',
    `治疗性单采例数` DECIMAL(18,3) COMMENT '治疗性单采例数',
    `特殊血型抗原鉴定` DECIMAL(18,3) COMMENT '特殊血型抗原鉴定数量',
    
 
)
ENGINE=OLAP
unique KEY ("周期", "周期名称", "排序","统计月","院区分类","运管科室")
COMMENT="输血科运管报表数据表-LIS部分"
DISTRIBUTED BY HASH("周期", "排序") BUCKETS 8
PROPERTIES(
    "replication_num" = "3",
    "storage_format" = "DEFAULT",
    "compression" = "LZ4"
);

-- 添加分区（按月分区）
-- ALTER TABLE ods.lis_blood_transfusion_management_report 
-- ADD PARTITION p202409 VALUES [('2024-09-01'), ('2024-10-01'));

-- 字段说明注释
/*
表结构说明：
1. 该表用于存储输血科运管报表的LIS部分数据
2. 包含三个时期的实际数据：上月、上上月、去年同期
3. 包含两种对比计算：同比（上月vs去年同期）、环比（上月vs上上月）
4. 数值字段使用DECIMAL(18,3)类型以保证计算精度
5. 同比/环比数据以百分比形式存储（如12.34表示12.34%）

数据血缘：
- 数据来源：多个LIS系统库（hid0101_orcl_lis_*）
- 包含：检验样本、收费信息、血袋管理、配血方法等
- 更新频率：建议按月更新
- 计算逻辑：复杂的UNION查询，包含9个不同数据源的合并

使用建议：
1. 建议按月进行分区管理
2. 可根据实际查询需求添加相应索引
3. 数据加载前建议进行数据质量检查
4. 同比/环比为NULL时表示基础数据为0无法计算
*/ 