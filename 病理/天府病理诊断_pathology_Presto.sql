-- =============================================================================
-- 天府院区病理诊断查询 — hid0117_mysql_bl_pis
-- =============================================================================
-- 【血缘】pathology（登记/状态）← LEFT JOIN report（诊断正文）
-- 【运管口径】deleted_at IS NULL + library_id NOT IN + receive_at 区间
-- 【对照本部 t_jcxx】f_blzd→report.diagnostic_opinion；f_lczd→pathology.clinical_diagnosis
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 字段含义字典（information_schema 实查，2026-07-22）
-- 格式：表.列 — 含义
-- -----------------------------------------------------------------------------

-- apply（病理申请）
--   apply_content          — 申请单内容/申请说明
--   clinical_diagnosis     — 临床诊断（申请时填写）
--   report_url             — 报告访问链接/URL

-- config_dict_diagnostic_term（诊断术语字典）
--   diagnostic_term_name   — 诊断术语名称

-- config_dict_pathologic_diagnosis（病理诊断字典）
--   dict_diagnostic_term_id    — 关联诊断术语 ID
--   pathologic_diagnosis_name  — 病理诊断标准名称

-- config_pathology_library_detail（病例库明细配置）
--   report_template_id     — 绑定的报告模板 ID

-- config_struct_report（结构化报告模板）
--   content                — 结构化报告模板/内容定义

-- config_timeout（超时规则配置）
--   timeout_content        — 超时规则说明文本

-- flow_cytometry（流式细胞）
--   diagnostic_opinion     — 流式细胞诊断意见

-- messages（系统消息）
--   content                — 消息正文
--   report_id              — 关联 report 表 ID

-- pathology（病理登记主表）★ 运管人次主源
--   clinical_diagnosis     — 临床诊断
--   intern_diagnostic_opinion — 初诊/住院医师诊断意见
--   intern_diagnostic_time    — 初诊诊断时间
--   report_extra_status    — 报告扩展状态（子状态/附加状态）
--   report_status          — 报告状态（如已登记/已审核等）
--   reported_at            — 报告完成/签发时间（主表侧）

-- pathology_assess（病理评估/质控）
--   processing_opinion     — 评估/处理意见
--   report_id              — 关联 report 表 ID

-- pathology_remark（病理备注）
--   content                — 备注内容

-- report（病理报告）★ 诊断正文主源
--   audit_report           — 审核后报告内容
--   consultation_report_number — 会诊报告编号
--   content                — 报告全文/正文
--   diagnostic_opinion     — 病理诊断意见（优先核对，≈本部 f_blzd）
--   first_report           — 初报内容
--   media_content          — 报告内嵌媒体/图像内容
--   no_water_report_path   — 无水印 PDF/文件路径
--   report_at              — 报告时间
--   report_order           — 报告序号（同一病例多份报告时排序）
--   report_path            — 报告文件路径
--   report_paths           — 报告文件路径集合（多路径）
--   report_type            — 报告类型（常规/补充/冰冻等）
--   show_diagnostic        — 展示用诊断文本（格式化后的诊断展示字段）
--   transfer_from_report_id — 转自哪份报告 ID（转审/修订来源）

-- report_ihc（免疫组化报告扩展）
--   report_id              — 关联 report 表 ID

-- specimen_sample（标本取材）
--   media_content          — 取材相关媒体/图像内容

-- transship（标本转运）
--   content                — 转运说明/转运记录内容


-- -----------------------------------------------------------------------------
-- 步骤 1：登记明细（pathology 主表，不关联 report）
-- -----------------------------------------------------------------------------
WITH params AS (
    SELECT
        '2026-01-01 00:00:00' AS start_date,
        '2026-01-31 23:59:59' AS end_date
)
SELECT
    p.id,
    p.clinical_diagnosis,           -- 临床诊断
    p.intern_diagnostic_opinion,    -- 初诊诊断意见
    p.intern_diagnostic_time,       -- 初诊诊断时间
    p.report_status,                -- 报告状态
    p.report_extra_status,          -- 报告扩展状态
    p.reported_at,                  -- 报告时间（主表）
    p.receive_at,                   -- 接收时间（运管统计口径）
    p.library_id,
    p.library_detail_id,
    CASE
        WHEN p.library_detail_id IN ('1', '39') THEN '常规组织病例TZ'
        WHEN p.library_detail_id = '40'          THEN '快速TQ'
        WHEN p.library_detail_id = '22'          THEN '冷冻TF'
        WHEN p.library_detail_id = '24'          THEN '细胞学TC'
        ELSE '其他'
    END AS pathology_type_name
FROM hid0117_mysql_bl_pis.pathology p, params
WHERE p.deleted_at IS NULL
  AND p.library_id NOT IN ('39', '40', '41', '60', '67', '68', '69', '77', '18')
  AND p.receive_at >= params.start_date
  AND p.receive_at <= params.end_date
LIMIT 100;


-- -----------------------------------------------------------------------------
-- 步骤 2：诊断明细（pathology + report，诊断正文取 report 表）
-- 关联键：report.pathology_id = pathology.id（若报错请 DESCRIBE report 确认外键列名）
-- 诊断优先级：diagnostic_opinion > content > show_diagnostic > first_report
-- -----------------------------------------------------------------------------
/*
WITH params AS (
    SELECT
        '2026-01-01 00:00:00' AS start_date,
        '2026-01-31 23:59:59' AS end_date
)
SELECT
    p.id,
    p.clinical_diagnosis,                              -- 临床诊断
    p.intern_diagnostic_opinion,                       -- 初诊诊断意见
    r.diagnostic_opinion,                              -- 病理诊断意见（主）
    r.content                          AS report_content,   -- 报告全文
    r.show_diagnostic,                                 -- 展示用诊断
    r.first_report,                                    -- 初报内容
    r.audit_report,                                    -- 审核后报告
    r.report_type,                                     -- 报告类型
    r.report_order,                                    -- 报告序号
    p.report_status,                                   -- 报告状态
    p.report_extra_status,                             -- 报告扩展状态
    p.receive_at,                                      -- 接收时间
    coalesce(r.report_at, p.reported_at) AS report_at, -- 报告时间
    r.report_path,                                     -- 报告文件路径
    CASE
        WHEN p.library_detail_id IN ('1', '39') THEN '常规组织病例TZ'
        WHEN p.library_detail_id = '40'          THEN '快速TQ'
        WHEN p.library_detail_id = '22'          THEN '冷冻TF'
        WHEN p.library_detail_id = '24'          THEN '细胞学TC'
        ELSE '其他'
    END AS pathology_type_name
FROM hid0117_mysql_bl_pis.pathology p
LEFT JOIN hid0117_mysql_bl_pis.report r
    ON r.pathology_id = p.id
CROSS JOIN params
WHERE p.deleted_at IS NULL
  AND p.library_id NOT IN ('39', '40', '41', '60', '67', '68', '69', '77', '18')
  AND p.receive_at >= params.start_date
  AND p.receive_at <= params.end_date
  AND coalesce(
        trim(cast(r.diagnostic_opinion AS varchar)),
        trim(cast(r.content AS varchar)),
        trim(cast(r.show_diagnostic AS varchar)),
        ''
      ) <> ''
LIMIT 100;
*/
