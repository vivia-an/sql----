/**
 * 输血科血液明细表 (BTS_Blood_Detail)
 * 
 * 基于输血SQL字段血缘关系汇总.md v3.0 版本设计
 * 整合所有核心表的血缘关系：
 * - BIS6_BLOODBAG_INPUT (血袋入库记录表) - 主要数据源
 * - BIS6_BLOODBAG_MATCH (配血匹配记录表) - 配血业务数据
 * - BIS6_BLOODBAG_INFUSION (输血记录表) - 输血执行数据
 * - BIS6_MATCH_BLOOD_TYPE (血型匹配关系表) - 血型关联数据
 * - BIS6_BLOOD_COMPONENT (血液成分字典表) - 成分字典数据
 * - LIS_INSPECTION_RESULT (检验结果表) - 检验数据
 * - LIS6_INSPECT_SAMPLE (检验样本表) - 样本数据
 */

-- 血液明细表 (完整版)
CREATE TABLE BTS_Blood_Detail (
    -- ================================
    -- 基础标识信息 (主键和基础标识)
    -- ================================
    BTS_Blood_Detail_MedOrgCode VARCHAR(60) NOT NULL,              -- 医疗机构代码
    BTS_Blood_Detail_BloodID VARCHAR(60) PRIMARY KEY,              -- 血液ID (对应: BIS6_BLOODBAG_INPUT.BLOODBAG_ID)
    BTS_Blood_Detail_BloodBagNo VARCHAR(60),                       -- 血袋编号 (对应: BIS6_BLOODBAG_INPUT.BLOODBAG_ID)
    BTS_Blood_Detail_BloodBagCode VARCHAR(60),                     -- 血袋编码 (对应: BIS6_BLOODBAG_INPUT.BLOOD_BAG_CODE)
    BTS_Blood_Detail_BloodDate VARCHAR(10),                        -- 血液日期(YYYYMMDD)
    
    -- ================================
    -- 血液属性信息
    -- ================================
    BTS_Blood_Detail_BloodTypeID VARCHAR(60),                      -- 血液类型ID (对应: BIS6_BLOODBAG_INPUT.BLOOD_TYPE_ID)
    BTS_Blood_Detail_BloodTypeName VARCHAR(100),                   -- 血液类型名称 (对应: BIS6_MATCH_BLOOD_TYPE.BLOOD_NAME)
    BTS_Blood_Detail_BloodVolume FLOAT8,                           -- 血液容量/数量 (对应: BIS6_BLOODBAG_INPUT.BLOOD_AMOUNT)
    BTS_Blood_Detail_BloodUnit VARCHAR(20),                        -- 血液单位 (对应: BIS6_BLOODBAG_INPUT.BLOOD_UNIT)
    BTS_Blood_Detail_BloodABOName VARCHAR(100),                    -- ABO血型名称 (对应: BIS6_BLOODBAG_INPUT.ABO_BLOOD_GROUP)
    BTS_Blood_Detail_BloodRhName VARCHAR(100),                     -- Rh血型名称 (对应: BIS6_BLOODBAG_INPUT.RH_BLOOD_GROUP)
    BTS_Blood_Detail_BloodStatusCode VARCHAR(20),                  -- 血液状态编码 (对应: BIS6_BLOODBAG_INPUT.BLOODBAG_STATE)
    BTS_Blood_Detail_BloodStatusName VARCHAR(100),                 -- 血液状态名称 (状态转换: '1'=入库,'2'=出库)
    
    -- ================================
    -- 血液成分信息 (来源: BIS6_BLOOD_COMPONENT)
    -- ================================
    BTS_Blood_Detail_ComponentID VARCHAR(60),                      -- 血液成分编码 (对应: BIS6_BLOOD_COMPONENT.COMPONENT_ID)
    BTS_Blood_Detail_ComponentName VARCHAR(100),                   -- 血液成分名称 (对应: BIS6_BLOOD_COMPONENT.COMPONENT_NAME)
    BTS_Blood_Detail_ComponentType VARCHAR(50),                    -- 成分类型 ('00000009'=红细胞悬液,'00000010'=血小板,'00000011'=新鲜冰冻血浆,'00000012'=冷沉淀)
    
    -- ================================
    -- 血库和院区信息
    -- ================================
    BTS_Blood_Detail_BloodBankCode VARCHAR(60),                    -- 血库代码/院区ID (对应: BIS6_BLOODBAG_INPUT.AREA_ID)
    BTS_Blood_Detail_BloodBankName VARCHAR(100),                   -- 血库名称 (A001=本院,A002=温江,A003=天府,A004=锦江)
    BTS_Blood_Detail_AreaID VARCHAR(20),                           -- 院区编码 (对应: BIS6_BLOODBAG_INPUT.AREA_ID)
    BTS_Blood_Detail_AreaName VARCHAR(100),                        -- 院区名称
    
    -- ================================
    -- 时间信息 (关键时间节点)
    -- ================================
    BTS_Blood_Detail_InboundDtTm timestamp,                        -- 入库时间 (对应: BIS6_BLOODBAG_INPUT.IN_TIME/IN_DATE)
    BTS_Blood_Detail_OutboundDtTm timestamp,                       -- 出库时间 (对应: BIS6_BLOODBAG_INPUT.OUT_DATE)
    BTS_Blood_Detail_TransfusionDtTm timestamp,                    -- 输血时间 (对应: BIS6_BLOODBAG_INPUT.SENDBLOOD_TIME)
    BTS_Blood_Detail_InfusionCheckDtTm timestamp,                  -- 输血核查时间 (对应: BIS6_BLOODBAG_INFUSION.R_CHECK_TIME)
    BTS_Blood_Detail_PreparationDtTm timestamp,                    -- 制备/捐血时间 (对应: BIS6_BLOODBAG_INPUT.PREPARATION_DATE)
    BTS_Blood_Detail_ExpireDtTm timestamp,                         -- 过期时间
    
    -- ================================
    -- 配血信息 (来源: BIS6_BLOODBAG_MATCH)
    -- ================================
    BTS_Blood_Detail_MatchID VARCHAR(60),                          -- 配血记录ID (对应: BIS6_BLOODBAG_MATCH.MATCH_ID)
    BTS_Blood_Detail_MatchDtTm timestamp,                          -- 配血时间 (对应: BIS6_BLOODBAG_MATCH.MACTH_DATE)
    BTS_Blood_Detail_MatchPersonID VARCHAR(60),                    -- 配血人ID (对应: BIS6_BLOODBAG_MATCH.MACTH_PERSON)
    BTS_Blood_Detail_MatchPersonName VARCHAR(100),                 -- 配血人姓名
    BTS_Blood_Detail_CheckPersonID VARCHAR(60),                    -- 配血核对人ID (对应: BIS6_BLOODBAG_MATCH.MATCH_CHECK_PERSON)
    BTS_Blood_Detail_CheckPersonName VARCHAR(100),                 -- 配血核对人姓名
    BTS_Blood_Detail_MatchState VARCHAR(20),                       -- 配血状态 (对应: BIS6_BLOODBAG_MATCH.MATCH_STATE)
    BTS_Blood_Detail_MethodTypeID VARCHAR(20),                     -- 配血方法 (对应: BIS6_BLOODBAG_MATCH.METHOD_TYPE_ID)
    
    -- ================================
    -- 患者信息 (来源: 多表关联)
    -- ================================
    BTS_Blood_Detail_PatientID VARCHAR(60),                        -- 患者标识 (对应: BIS6_BLOODBAG_INPUT.PAT_ID)
    BTS_Blood_Detail_OutpatientID VARCHAR(60),                     -- 门诊/住院号 (对应: LIS_INSPECTION_RESULT.OUTPATIENT_ID)
    BTS_Blood_Detail_PatientName VARCHAR(100),                     -- 患者姓名
    BTS_Blood_Detail_PatientSex VARCHAR(10),                       -- 患者性别
    BTS_Blood_Detail_PatientAge VARCHAR(20),                       -- 患者年龄
    
    -- ================================
    -- 检验信息 (来源: LIS_INSPECTION_RESULT + LIS6_INSPECT_SAMPLE)
    -- ================================
    BTS_Blood_Detail_InspectionID VARCHAR(60),                     -- 检验单ID (对应: BIS6_BLOODBAG_INPUT.INSPECTION_ID)
    BTS_Blood_Detail_TestItemID VARCHAR(60),                       -- 检验项目ID (对应: LIS_INSPECTION_RESULT.TEST_ITEM_ID)
    BTS_Blood_Detail_TestItemName VARCHAR(200),                    -- 配血检验项目名称 (对应: LIS_INSPECTION_RESULT.CHINESE_NAME)
    BTS_Blood_Detail_TestResult VARCHAR(500),                      -- 检验结果 (对应: LIS_INSPECTION_RESULT.QUANTITATIVE_RESULT)
    BTS_Blood_Detail_SampleType VARCHAR(50),                       -- 样本类型 (对应: LIS6_INSPECT_SAMPLE.SAMPLE_TYPE)
    BTS_Blood_Detail_SampleCollectDtTm timestamp,                  -- 样本采集时间 (对应: LIS6_INSPECT_SAMPLE.COLLECT_TIME)
    BTS_Blood_Detail_SampleReceiveDtTm timestamp,                  -- 样本接收时间 (对应: LIS6_INSPECT_SAMPLE.RECEIVE_TIME)
    
    -- ================================
    -- 操作人员信息
    -- ================================
    BTS_Blood_Detail_InputPersonID VARCHAR(60),                    -- 入库操作人员ID
    BTS_Blood_Detail_InputPersonName VARCHAR(100),                 -- 入库操作人员姓名
    BTS_Blood_Detail_OutputPersonID VARCHAR(60),                   -- 出库操作人员ID (对应: BIS6_BLOODBAG_INPUT.OUT_PERSON)
    BTS_Blood_Detail_OutputPersonName VARCHAR(100),                -- 出库操作人员姓名
    
    -- ================================
    -- 业务信息
    -- ================================
    BTS_Blood_Detail_BloodSource VARCHAR(100),                     -- 血液来源
    BTS_Blood_Detail_OperationType VARCHAR(60),                    -- 操作类型(入库/出库/盘存)
    BTS_Blood_Detail_ChargeState VARCHAR(20),                      -- 收费状态 (对应: BIS6_BLOODBAG_MATCH.BLOOD_charge_state)
    BTS_Blood_Detail_ChargeAmount FLOAT8,                          -- 收费金额
    BTS_Blood_Detail_BloodCost FLOAT8,                             -- 血液成本
    
    -- ================================
    -- 质量控制字段 (电子病历评级相关)
    -- ================================
    BTS_Blood_Detail_QualityFlag VARCHAR(20),                      -- 质量标识 (完整性/一致性/时效性/整合性)
    BTS_Blood_Detail_DataIntegrity INT8 DEFAULT 1,                 -- 数据完整性标识 (1=完整,0=不完整)
    BTS_Blood_Detail_TimeEfficiency INT8 DEFAULT 1,                -- 时效性标识 (1=及时,0=延迟)
    BTS_Blood_Detail_DataConsistency INT8 DEFAULT 1,               -- 一致性标识 (1=一致,0=不一致)
    BTS_Blood_Detail_DataIntegration INT8 DEFAULT 1,               -- 整合性标识 (1=完整对照,0=缺失对照)
    
    -- ================================
    -- 扩展字段 (DC标准扩展)
    -- ================================
    BTS_Blood_Detail_ExtStr1 VARCHAR(200),                         -- 扩展字符串1
    BTS_Blood_Detail_ExtStr2 VARCHAR(200),                         -- 扩展字符串2
    BTS_Blood_Detail_ExtStr3 VARCHAR(200),                         -- 扩展字符串3
    BTS_Blood_Detail_ExtNum1 FLOAT8,                               -- 扩展数值1
    BTS_Blood_Detail_ExtNum2 FLOAT8,                               -- 扩展数值2
    BTS_Blood_Detail_ExtDate1 timestamp,                           -- 扩展日期1
    BTS_Blood_Detail_ExtDate2 timestamp,                           -- 扩展日期2
    
    -- ================================
    -- 数据管理字段 (符合DC标准)
    -- ================================
    BTS_Blood_Detail_DataSourceFlag VARCHAR(10) DEFAULT 'BIS6',    -- 数据来源标识 (BIS6=输血系统6.x)
    BTS_Blood_Detail_DataVersion VARCHAR(20) DEFAULT 'v3.0',       -- 数据版本 (对应血缘关系汇总版本)
    BTS_Blood_Detail_ETLBatchID VARCHAR(100),                      -- ETL批次ID
    BTS_Blood_Detail_IsDeleted INT8 DEFAULT 0,                     -- 删除标识 (对应各源表: isdeleted='0')
    BTS_Blood_Detail_IsValid INT8 DEFAULT 1,                       -- 有效性标识
    BTS_Blood_Detail_CreateUser VARCHAR(60) DEFAULT 'ETL_SYSTEM',  -- 创建用户
    BTS_Blood_Detail_UpdateUser VARCHAR(60) DEFAULT 'ETL_SYSTEM',  -- 更新用户
    BTS_Blood_Detail_LastUpdateDtTm timestamp DEFAULT CURRENT_TIMESTAMP, -- 最后更新时间
    BTS_Blood_Detail_DataCreateDtTm timestamp DEFAULT CURRENT_TIMESTAMP  -- 数据创建时间
);

-- ================================
-- 索引创建 (基于血缘关系优化)
-- ================================

-- 主要业务索引
CREATE INDEX idx_BTS_Blood_Detail_BloodBagNo ON BTS_Blood_Detail(BTS_Blood_Detail_BloodBagNo);
CREATE INDEX idx_BTS_Blood_Detail_PatientID ON BTS_Blood_Detail(BTS_Blood_Detail_PatientID);
CREATE INDEX idx_BTS_Blood_Detail_InspectionID ON BTS_Blood_Detail(BTS_Blood_Detail_InspectionID);
CREATE INDEX idx_BTS_Blood_Detail_MatchID ON BTS_Blood_Detail(BTS_Blood_Detail_MatchID);

-- 时间维度索引
CREATE INDEX idx_BTS_Blood_Detail_InboundDate ON BTS_Blood_Detail(BTS_Blood_Detail_InboundDtTm);
CREATE INDEX idx_BTS_Blood_Detail_OutboundDate ON BTS_Blood_Detail(BTS_Blood_Detail_OutboundDtTm);
CREATE INDEX idx_BTS_Blood_Detail_MatchDate ON BTS_Blood_Detail(BTS_Blood_Detail_MatchDtTm);

-- 院区和血型维度索引
CREATE INDEX idx_BTS_Blood_Detail_AreaID ON BTS_Blood_Detail(BTS_Blood_Detail_AreaID);
CREATE INDEX idx_BTS_Blood_Detail_BloodABO ON BTS_Blood_Detail(BTS_Blood_Detail_BloodABOName);
CREATE INDEX idx_BTS_Blood_Detail_ComponentID ON BTS_Blood_Detail(BTS_Blood_Detail_ComponentID);

-- 状态和质量控制索引
CREATE INDEX idx_BTS_Blood_Detail_BloodStatus ON BTS_Blood_Detail(BTS_Blood_Detail_BloodStatusCode);
CREATE INDEX idx_BTS_Blood_Detail_MatchState ON BTS_Blood_Detail(BTS_Blood_Detail_MatchState);
CREATE INDEX idx_BTS_Blood_Detail_QualityFlag ON BTS_Blood_Detail(BTS_Blood_Detail_QualityFlag);

-- 数据管理索引
CREATE INDEX idx_BTS_Blood_Detail_IsDeleted ON BTS_Blood_Detail(BTS_Blood_Detail_IsDeleted);
CREATE INDEX idx_BTS_Blood_Detail_DataSource ON BTS_Blood_Detail(BTS_Blood_Detail_DataSourceFlag);
CREATE INDEX idx_BTS_Blood_Detail_LastUpdate ON BTS_Blood_Detail(BTS_Blood_Detail_LastUpdateDtTm);

-- ================================
-- 表注释
-- ================================
COMMENT ON TABLE BTS_Blood_Detail IS '输血科血液明细表 - 整合所有血液相关业务数据，基于输血SQL字段血缘关系汇总v3.0设计';

-- 基础字段注释
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_BloodID IS '血液ID，对应BIS6_BLOODBAG_INPUT.BLOODBAG_ID，主键';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_BloodBagNo IS '血袋编号，对应BIS6_BLOODBAG_INPUT.BLOODBAG_ID';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_BloodTypeID IS '血液类型ID，对应BIS6_BLOODBAG_INPUT.BLOOD_TYPE_ID，关联BIS6_MATCH_BLOOD_TYPE';

-- 血液属性注释
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_BloodABOName IS 'ABO血型，对应BIS6_BLOODBAG_INPUT.ABO_BLOOD_GROUP，取值：O型/A型/B型/AB型';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_BloodRhName IS 'Rh血型，对应BIS6_BLOODBAG_INPUT.RH_BLOOD_GROUP';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_BloodVolume IS '血液数量，对应BIS6_BLOODBAG_INPUT.BLOOD_AMOUNT，需CAST为DOUBLE类型';

-- 成分信息注释
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_ComponentID IS '血液成分编码，对应BIS6_BLOOD_COMPONENT.COMPONENT_ID，关联字典表';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_ComponentType IS '成分类型：00000009=红细胞悬液,00000010=血小板,00000011=新鲜冰冻血浆,00000012=冷沉淀';

-- 院区信息注释
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_AreaID IS '院区编码，对应BIS6_BLOODBAG_INPUT.AREA_ID，A001=本院,A002=温江,A003=天府,A004=锦江';

-- 配血信息注释
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_MatchID IS '配血记录ID，对应BIS6_BLOODBAG_MATCH.MATCH_ID';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_MatchDtTm IS '配血时间，对应BIS6_BLOODBAG_MATCH.MACTH_DATE（注意原始拼写）';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_MatchState IS '配血状态，对应BIS6_BLOODBAG_MATCH.MATCH_STATE，排除-1无效状态';

-- 检验信息注释
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_InspectionID IS '检验单ID，对应BIS6_BLOODBAG_INPUT.INSPECTION_ID，关联LIS_INSPECTION_RESULT';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_TestItemName IS '配血检验项目名称，对应LIS_INSPECTION_RESULT.CHINESE_NAME';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_TestResult IS '检验结果，对应LIS_INSPECTION_RESULT.QUANTITATIVE_RESULT';

-- 质量控制注释
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_QualityFlag IS '质量标识，支持电子病历评级：完整性/一致性/时效性/整合性检查';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_DataIntegrity IS '数据完整性标识，用于电子病历评级完整性检查';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_TimeEfficiency IS '时效性标识，用于电子病历评级时效性检查：入库<出库<输血时间';

-- 数据管理注释
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_DataSourceFlag IS '数据来源标识：BIS6=输血系统6.x版本';
COMMENT ON COLUMN BTS_Blood_Detail.BTS_Blood_Detail_IsDeleted IS '删除标识，对应各源表isdeleted字段，0=有效，1=已删除'; 