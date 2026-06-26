-- =============================================================================
-- 住院患者非计划手术率 · 空结果排查（逐步跑，看哪一步归零）
-- =============================================================================

-- Step0: ipi_registration 出院字段填充率（手麻库常见为空 → 分母归零）
SELECT
    count(*) AS ipi_total,
    count(CASE WHEN nullif(trim(coalesce(cast(leave_dept_date AS varchar), cast(discharge_date AS varchar), '')), '') IS NOT NULL THEN 1 END) AS has_out_dt,
    count(CASE WHEN nullif(trim(coalesce(cast(admission_time AS varchar), cast(registration_date AS varchar), '')), '') IS NOT NULL THEN 1 END) AS has_in_dt,
    count(CASE
        WHEN nullif(trim(coalesce(cast(leave_dept_date AS varchar), cast(discharge_date AS varchar), '')), '') >= '2025-07-01'
         AND nullif(trim(coalesce(cast(leave_dept_date AS varchar), cast(discharge_date AS varchar), '')), '') < '2026-07-01'
        THEN 1
    END) AS in_range_202507_202606
FROM hid0101_orcl_operaanesthisa_emrhis.ipi_registration
WHERE coalesce(cast(isdeleted AS varchar), '0') = '0';

-- Step1: Visit_IPReg 分母（HIS 已验证有数）
SELECT
    count(*) AS visit_total,
    count(CASE
        WHEN "Visit_IPReg_OutHospDtTm" >= '2025-07-01' AND "Visit_IPReg_OutHospDtTm" < '2026-01-01' THEN 1
    END) AS range1_cnt,
    count(CASE
        WHEN "Visit_IPReg_OutHospDtTm" >= '2026-01-01' AND "Visit_IPReg_OutHospDtTm" < '2026-07-01' THEN 1
    END) AS range2_cnt
FROM datacenter_db.Visit_IPReg
WHERE "Visit_IPReg_MedOrgCode" = 'HID0101'
  AND "Visit_IPReg_IsDeleted" = '0'
  AND "Visit_IPReg_OutHospDtTm" IS NOT NULL
  AND "Visit_IPReg_OutHospDtTm" != ''
  AND "Visit_IPReg_InHospDtTm" IS NOT NULL
  AND "Visit_IPReg_InHospDtTm" != ''
  AND "Visit_IPReg_OutHospDtTm" >= '2025-07-01'
  AND "Visit_IPReg_OutHospDtTm" < '2026-07-01';

-- Step2: Visit ↔ ipi 关联命中（分子桥接）
SELECT
    count(DISTINCT v."Visit_IPReg_VisitID") AS visit_cnt,
    count(DISTINCT CASE WHEN ieg.id IS NOT NULL THEN v."Visit_IPReg_VisitID" END) AS visit_with_ipi
FROM datacenter_db.Visit_IPReg v
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ieg
    ON coalesce(cast(ieg.isdeleted AS varchar), '0') = '0'
   AND (
        trim(cast(ieg.id AS varchar)) = trim(cast(v."Visit_IPReg_IPRegID" AS varchar))
     OR trim(cast(ieg.ipi_registration_no AS varchar)) = trim(cast(v."Visit_IPReg_VisitNo" AS varchar))
   )
WHERE v."Visit_IPReg_MedOrgCode" = 'HID0101'
  AND v."Visit_IPReg_IsDeleted" = '0'
  AND v."Visit_IPReg_OutHospDtTm" >= '2025-07-01'
  AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01';

-- Step3: 手麻非计划手术字段分布
SELECT
    coalesce(cast(is_unplanned_oper AS varchar), '(null)') AS is_unplanned_oper,
    count(*) AS cnt
FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply
WHERE coalesce(cast(isdeleted AS varchar), '0') = '0'
  AND coalesce(cast(health_service_org_id AS varchar), '') = 'HXSSMZK'
GROUP BY 1
ORDER BY cnt DESC
LIMIT 20;

-- Step4: reason_oper_also 含「非计划」样本量
SELECT count(*) AS reason_unplanned_cnt
FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply
WHERE coalesce(cast(isdeleted AS varchar), '0') = '0'
  AND trim(coalesce(cast(reason_oper_also AS varchar), '')) LIKE '%非计划%';

-- Step5: HIS Apply_OPS 分子对照（同区间）
SELECT count(DISTINCT v."Visit_IPReg_VisitID") AS his_numer_cnt
FROM datacenter_db.Visit_IPReg v
INNER JOIN datacenter_db.Apply_OPS p
    ON v."Visit_IPReg_VisitID" = p."Apply_OPS_VisitID"
WHERE v."Visit_IPReg_MedOrgCode" = 'HID0101'
  AND p."Apply_OPS_MedOrgCode" = 'HID0101'
  AND v."Visit_IPReg_IsDeleted" = '0'
  AND p."Apply_OPS_IsDeleted" = '0'
  AND v."Visit_IPReg_OutHospDtTm" >= '2025-07-01'
  AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01'
  AND p."Apply_OPS_PlanAgainOPSFlag" = '非计划再次手术';
