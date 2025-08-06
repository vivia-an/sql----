/**
 * 输血科血液明细表 (BTS_Blood_Detail) 数据集成查询SQL
 * 
 * 基于输血SQL字段血缘关系汇总.md v3.0 版本
 * 整合7个核心表的完整血缘关系查询
 * 
 * 数据源表：
 * - BIS6_BLOODBAG_INPUT (血袋入库记录表) - 主表
 * - BIS6_BLOODBAG_MATCH (配血匹配记录表) - 配血业务
 * - BIS6_BLOODBAG_INFUSION (输血记录表) - 输血执行
 * - BIS6_MATCH_BLOOD_TYPE (血型匹配关系表) - 血型关联
 * - BIS6_BLOOD_COMPONENT (血液成分字典表) - 成分字典
 * - LIS_INSPECTION_RESULT (检验结果表) - 检验数据
 * - LIS6_INSPECT_SAMPLE (检验样本表) - 样本数据
 */

-- ================================
-- 主要数据集成查询
-- ================================
INSERT INTO BTS_Blood_Detail (
    -- 基础标识信息
    BTS_Blood_Detail_MedOrgCode,
    BTS_Blood_Detail_BloodID,
    BTS_Blood_Detail_BloodBagNo,
    BTS_Blood_Detail_BloodBagCode,
    BTS_Blood_Detail_BloodDate,
    
    -- 血液属性信息
    BTS_Blood_Detail_BloodTypeID,
    BTS_Blood_Detail_BloodTypeName,
    BTS_Blood_Detail_BloodVolume,
    BTS_Blood_Detail_BloodUnit,
    BTS_Blood_Detail_BloodABOName,
    BTS_Blood_Detail_BloodRhName,
    BTS_Blood_Detail_BloodStatusCode,
    BTS_Blood_Detail_BloodStatusName,
    
    -- 血液成分信息
    BTS_Blood_Detail_ComponentID,
    BTS_Blood_Detail_ComponentName,
    BTS_Blood_Detail_ComponentType,
    
    -- 血库和院区信息
    BTS_Blood_Detail_BloodBankCode,
    BTS_Blood_Detail_BloodBankName,
    BTS_Blood_Detail_AreaID,
    BTS_Blood_Detail_AreaName,
    
    -- 时间信息
    BTS_Blood_Detail_InboundDtTm,
    BTS_Blood_Detail_OutboundDtTm,
    BTS_Blood_Detail_TransfusionDtTm,
    BTS_Blood_Detail_InfusionCheckDtTm,
    BTS_Blood_Detail_PreparationDtTm,
    
    -- 配血信息
    BTS_Blood_Detail_MatchID,
    BTS_Blood_Detail_MatchDtTm,
    BTS_Blood_Detail_MatchPersonID,
    BTS_Blood_Detail_MatchPersonName,
    BTS_Blood_Detail_CheckPersonID,
    BTS_Blood_Detail_CheckPersonName,
    BTS_Blood_Detail_MatchState,
    BTS_Blood_Detail_MethodTypeID,
    
    -- 患者信息
    BTS_Blood_Detail_PatientID,
    BTS_Blood_Detail_OutpatientID,
    BTS_Blood_Detail_PatientName,
    BTS_Blood_Detail_PatientSex,
    BTS_Blood_Detail_PatientAge,
    
    -- 检验信息
    BTS_Blood_Detail_InspectionID,
    BTS_Blood_Detail_TestItemID,
    BTS_Blood_Detail_TestItemName,
    BTS_Blood_Detail_TestResult,
    BTS_Blood_Detail_SampleType,
    BTS_Blood_Detail_SampleCollectDtTm,
    BTS_Blood_Detail_SampleReceiveDtTm,
    
    -- 操作人员信息
    BTS_Blood_Detail_OutputPersonID,
    BTS_Blood_Detail_OutputPersonName,
    
    -- 业务信息
    BTS_Blood_Detail_OperationType,
    BTS_Blood_Detail_ChargeState,
    
    -- 质量控制字段
    BTS_Blood_Detail_QualityFlag,
    BTS_Blood_Detail_DataIntegrity,
    BTS_Blood_Detail_TimeEfficiency,
    BTS_Blood_Detail_DataConsistency,
    BTS_Blood_Detail_DataIntegration,
    
    -- 数据管理字段
    BTS_Blood_Detail_DataSourceFlag,
    BTS_Blood_Detail_DataVersion,
    BTS_Blood_Detail_ETLBatchID,
    BTS_Blood_Detail_IsDeleted,
    BTS_Blood_Detail_LastUpdateDtTm,
    BTS_Blood_Detail_DataCreateDtTm
)
   -- ================================
    -- 基础标识信息
    -- ================================
  select  COALESCE('HID0101', 'DEFAULT') AS BTS_Blood_Detail_MedOrgCode,              -- 医疗机构代码
    a.BLOODBAG_ID AS BTS_Blood_Detail_BloodID,                                  -- 血液ID (主键)
    a.BLOODBAG_ID AS BTS_Blood_Detail_BloodBagNo,                               -- 血袋编号
    a.BLOOD_BAG_CODE AS BTS_Blood_Detail_BloodBagCode,                          -- 血袋编码
    COALESCE(a.OUT_DATE, a.IN_DATE, a.IN_TIME) AS BTS_Blood_Detail_BloodDate, -- 血液日期

    -- ================================
    -- 血液属性信息 (来源: BIS6_BLOODBAG_INPUT)
    -- ================================
    a.BLOOD_TYPE_ID AS BTS_Blood_Detail_BloodTypeID,                            -- 血液类型ID
    bt.BLOOD_NAME AS BTS_Blood_Detail_BloodTypeName,                            -- 血液类型名称
    a.BLOOD_AMOUNT  AS BTS_Blood_Detail_BloodVolume,              -- 血液数量(CAST转换)
    a.BLOOD_UNIT AS BTS_Blood_Detail_BloodUnit,                                 -- 血液单位
    a.ABO_BLOOD_GROUP AS BTS_Blood_Detail_BloodABOName,                         -- ABO血型
    a.RH_BLOOD_GROUP AS BTS_Blood_Detail_BloodRhName,                           -- RH血型
    a.BLOODBAG_STATE AS BTS_Blood_Detail_BloodStatusCode,                       -- 血袋状态编码
   b.data_cname AS BTS_Blood_Detail_BloodStatusName,                         -- 血袋状态名称

    -- ================================
    -- 血液成分信息 (来源: BIS6_BLOOD_COMPONENT)
    -- ================================
    c.COMPONENT_ID AS BTS_Blood_Detail_ComponentID,                             -- 血液成分编码
    c.COMPONENT_NAME AS BTS_Blood_Detail_ComponentName,                         -- 血液成分名称
    c.component_name
     AS BTS_Blood_Detail_ComponentType,
    

    -- ================================
    -- 血库和院区信息 (来源: BIS6_BLOODBAG_INPUT.AREA_ID)
    -- ================================
    a.AREA_ID AS BTS_Blood_Detail_BloodBankCode,                                -- 血库代码
    CASE a.AREA_ID                                                              -- 血库名称映射
        WHEN 'A001' THEN '本院血库'
        WHEN 'A002' THEN '温江血库'
        WHEN 'A003' THEN '天府血库'
        WHEN 'A004' THEN '锦江血库'
        ELSE '未知血库'
    END AS BTS_Blood_Detail_BloodBankName,
    a.AREA_ID AS BTS_Blood_Detail_AreaID,                                       -- 院区编码
    CASE a.AREA_ID                                                              -- 院区名称映射
        WHEN 'A001' THEN '本院'
        WHEN 'A002' THEN '温江院区'
        WHEN 'A003' THEN '天府院区'
        WHEN 'A004' THEN '锦江院区'
        ELSE '未知院区'
    END AS BTS_Blood_Detail_AreaName,

    -- ================================
    -- 时间信息 (关键时间节点)
    -- ================================
    COALESCE(
        TRY_CAST(a.IN_TIME AS timestamp), 
        TRY_CAST(a.IN_DATE AS timestamp)
    ) AS BTS_Blood_Detail_InboundDtTm,                                           -- 入库时间
    TRY_CAST(a.OUT_DATE AS timestamp) AS BTS_Blood_Detail_OutboundDtTm,          -- 出库时间
    TRY_CAST(a.SENDBLOOD_TIME AS timestamp) AS BTS_Blood_Detail_TransfusionDtTm, -- 输血时间
    TRY_CAST(inf.R_CHECK_TIME AS timestamp) AS BTS_Blood_Detail_InfusionCheckDtTm, -- 输血核查时间
    TRY_CAST(a.PREPARATION_DATE AS timestamp) AS BTS_Blood_Detail_PreparationDtTm, -- 制备时间

    -- ================================
    -- 配血信息 (来源: BIS6_BLOODBAG_MATCH)
    -- ================================
    m.MATCH_ID AS BTS_Blood_Detail_MatchID,                                     -- 配血记录ID
    TRY_CAST(m.MACTH_DATE AS timestamp) AS BTS_Blood_Detail_MatchDtTm,           -- 配血时间(注意拼写)
    m.MACTH_PERSON_ID AS BTS_Blood_Detail_MatchPersonID,                           -- 配血人ID
    m.MACTH_PERSON AS BTS_Blood_Detail_MatchPersonName,                         -- 配血人姓名
    m.MATCH_CHECK_PERSON_ID AS BTS_Blood_Detail_CheckPersonID,                     -- 配血核对人ID
    m.MATCH_CHECK_PERSON AS BTS_Blood_Detail_CheckPersonName,                   -- 配血核对人姓名
    m.MATCH_STATE AS BTS_Blood_Detail_MatchState,                               -- 配血状态
    m.METHOD_TYPE_ID AS BTS_Blood_Detail_MethodTypeID,                          -- 配血方法

    -- ================================
    -- 患者信息 (来源: 多表关联)
    -- ================================
    a.PAT_ID AS BTS_Blood_Detail_PatientID,                                     -- 患者标识（登记号）
    CAST(COALESCE(pa."paadm_admno", '') AS VARCHAR(65535))
      AS BTS_Blood_Detail_OutpatientID,                          -- 就诊号
    NULL AS BTS_Blood_Detail_PatientName,                                       -- 患者姓名(需HIS关联)
    NULL AS BTS_Blood_Detail_PatientSex,                                        -- 患者性别(需HIS关联)
    NULL AS BTS_Blood_Detail_PatientAge,                                        -- 患者年龄(需HIS关联)

    -- ================================
    -- 检验信息 (来源: LIS_INSPECTION_RESULT + LIS6_INSPECT_SAMPLE)
    -- ================================
    a.INSPECTION_ID AS BTS_Blood_Detail_InspectionID,                           -- 检验单ID
    lr.TEST_ITEM_ID AS BTS_Blood_Detail_TestItemID,                             -- 检验项目ID
    lr.CHINESE_NAME AS BTS_Blood_Detail_TestItemName,                           -- 配血检验项目名称
    lr.QUANTITATIVE_RESULT AS BTS_Blood_Detail_TestResult,                      -- 检验结果
    ls.sample_class AS BTS_Blood_Detail_SampleType,                              -- 样本类型
    ls.SAMPLING_TIME  AS BTS_Blood_Detail_SampleCollectDtTm, -- 样本采集时间
    ls.INCEPT_TIME  AS BTS_Blood_Detail_SampleReceiveDtTm, -- 样本接收时间

    
  
        
    
    
    -- ================================
    -- 操作人员信息
    -- ================================
    a.OUT_PERSON_ID AS BTS_Blood_Detail_OutputPersonID,                            -- 出库操作人员ID
    a.OUT_PERSON AS BTS_Blood_Detail_OutputPersonName,                          -- 出库操作人员姓名(同ID)

    -- ================================
    -- 业务信息
    -- ================================
                                                     
    b.data_cname AS BTS_Blood_Detail_OperationType,  -- 操作类型
    m.BLOOD_charge_state AS BTS_Blood_Detail_ChargeState,                       -- 收费状态

    -- ================================
    -- 质量控制字段 (电子病历评级逻辑)
    -- ================================
    CASE 
        WHEN m.MATCH_STATE = '-1' OR m.METHOD_TYPE_ID = '4' THEN '质量异常'
        WHEN a.BLOODBAG_STATE IN ('14','15','16') THEN '状态异常'
        ELSE '正常'
    END AS BTS_Blood_Detail_QualityFlag,                                        -- 质量标识

    -- 数据完整性检查 (1=完整, 0=不完整)
    CASE 
        WHEN a.BLOODBAG_ID IS NOT NULL 
         AND a.ABO_BLOOD_GROUP IS NOT NULL 
         AND a.BLOOD_TYPE_ID IS NOT NULL THEN 1
        ELSE 0
    END AS BTS_Blood_Detail_DataIntegrity,

    -- 时效性检查 (1=及时, 0=延迟) - 入库 < 出库 < 输血时间
    CASE 
        WHEN TRY_CAST(a.OUT_DATE AS timestamp) > COALESCE(TRY_CAST(a.IN_TIME AS timestamp), TRY_CAST(a.IN_DATE AS timestamp))
         AND COALESCE(TRY_CAST(inf.R_CHECK_TIME AS timestamp), TRY_CAST(a.SENDBLOOD_TIME AS timestamp)) > TRY_CAST(a.OUT_DATE AS timestamp) THEN 1
        ELSE 0
    END AS BTS_Blood_Detail_TimeEfficiency,

    -- 一致性检查 (1=一致, 0=不一致) - 血型编码一致性
    CASE 
        WHEN a.ABO_BLOOD_GROUP = lr.GROUP_ID OR lr.GROUP_ID IS NULL THEN 1
        ELSE 0
    END AS BTS_Blood_Detail_DataConsistency,

    -- 整合性检查 (1=完整对照, 0=缺失对照) - 表间关联完整性
    CASE 
        WHEN m.BLOODBAG_ID IS NOT NULL 
         AND lr.INSPECTION_ID IS NOT NULL 
         AND bt.BLOOD_TYPE_ID IS NOT NULL THEN 1
        ELSE 0
    END AS BTS_Blood_Detail_DataIntegration,

    -- ================================
    -- 数据管理字段
    -- ================================
    '161' AS BTS_Blood_Detail_DataSourceFlag,                                  -- 数据来源标识
    'v3.0' AS BTS_Blood_Detail_DataVersion,                                     -- 数据版本
   format_datetime(now(), 'yyyyMMddHHmmss') AS BTS_Blood_Detail_ETLBatchID,         -- ETL批次ID
    CASE WHEN a.isdeleted = '0' THEN 0 ELSE 1 END AS BTS_Blood_Detail_IsDeleted, -- 删除标识
    CURRENT_TIMESTAMP AS BTS_Blood_Detail_LastUpdateDtTm,                       -- 最后更新时间
    CURRENT_TIMESTAMP AS BTS_Blood_Detail_DataCreateDtTm                        -- 数据创建时间

-- ================================
-- 表关联 (基于血缘关系汇总的关联模式)
-- ================================
FROM hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT a                               -- 主表：血袋入库记录表
--select * from hid0101_orcl_lis_xhbis.BIS6_BLOODBAG_INPUT
    -- 配血匹配记录关联 (核心业务关联)
    LEFT JOIN hid0101_orcl_lis_xhbis.bis6_bloodbag_match m
        ON a.BLOODBAG_ID = m.BLOODBAG_ID
        AND m.isdeleted = '0'
    --    AND m.MATCH_STATE <> '-1'                                               -- 排除无效配血状态
      --  AND m.METHOD_TYPE_ID <> '4'                                             -- 排除无效配血方法

    -- 输血记录关联 (时效性分析)
    LEFT JOIN hid0101_orcl_lis_bis6.BIS6_BLOODBAG_INFUSION inf
        ON a.BLOODBAG_ID = inf.BLOODBAG_ID
        AND inf.isdeleted = '0'

    -- 血型匹配关系关联 (血型和成分关联)
    LEFT JOIN hid0101_orcl_lis_xhbis.bis6_match_blood_type bt
        ON a.BLOOD_TYPE_ID = bt.BLOOD_TYPE_ID
        AND bt.isdeleted = '0'

    -- 血液成分字典关联 (成分信息)
    LEFT JOIN hid0101_orcl_lis_xhbis.BIS6_BLOOD_COMPONENT c
        ON bt.COMPONENT_ID = c.COMPONENT_ID
        AND c.isdeleted = '0'

    -- 检验结果关联 (检验数据) - 注意库名 hid0101_orcl_lis_dbo
    LEFT JOIN hid0101_orcl_lis_dbo.LIS_INSPECTION_RESULT lr
        ON a.INSPECTION_ID = lr.INSPECTION_ID
        AND lr.isdeleted = '0'

    -- 检验样本关联 (样本数据) - 库名 hid0101_orcl_lis_xhdata
    LEFT JOIN hid0101_orcl_lis_xhdata.LIS6_INSPECT_SAMPLE ls
        ON a.INSPECTION_ID = ls.INSPECTION_ID
        AND ls.isdeleted = '0'

		left join (
select data_id,data_cname from hid0101_orcl_lis_xhsys.sys6_base_data where class_id = '血袋状态' and isdeleted = '0' ) b on a.bloodbag_state = b.data_id
        
-- 添加就诊号关联（血缘规则）
LEFT JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm pa
    ON ls.inpatient_id = pa."rowkey"
    AND pa."isdeleted" = '0'

-- ================================
-- 筛选条件 (基于血缘关系汇总的业务规则)
-- ================================
WHERE a.isdeleted = '0'                                                         -- 逻辑删除筛选
