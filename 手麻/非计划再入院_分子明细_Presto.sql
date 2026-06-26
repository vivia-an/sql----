-- =============================================================================
-- 住院患者非计划手术率 · 分子明细（手麻库 + Visit 桥接）
-- =============================================================================

WITH base_visit AS (
    SELECT
        v."Visit_IPReg_VisitID" AS visit_id,
        v."Visit_IPReg_VisitNo" AS visit_no,
        v."Visit_IPReg_IPRegID" AS ipreg_id,
        v."Visit_IPReg_InHospDtTm" AS in_dt,
        v."Visit_IPReg_OutHospDtTm" AS out_dt
    FROM datacenter_db.Visit_IPReg v
    WHERE v."Visit_IPReg_MedOrgCode" = 'HID0101'
      AND v."Visit_IPReg_IsDeleted" = '0'
      AND v."Visit_IPReg_OutHospDtTm" IS NOT NULL
      AND v."Visit_IPReg_OutHospDtTm" != ''
      AND v."Visit_IPReg_InHospDtTm" IS NOT NULL
      AND v."Visit_IPReg_InHospDtTm" != ''
      AND v."Visit_IPReg_OutHospDtTm" >= '2025-07-01'
      AND v."Visit_IPReg_OutHospDtTm" < '2026-07-01'
)
SELECT
    bv.visit_no AS "就诊号",
    ieg.ipi_registration_no AS "登记号",
    ieg.ipno AS "病案号",
    bv.in_dt AS "入院时间",
    bv.out_dt AS "出院时间",
    a.id AS "手术申请ID",
    trim(coalesce(cast(a.scheduled_date AS varchar), '')) AS "排程日期",
    trim(coalesce(cast(ar.oper_beging_date AS varchar), '')) AS "麻醉开始时间",
    coalesce(cast(a.is_unplanned_oper AS varchar), '') AS "是否非计划手术",
    coalesce(cast(a.reason_oper_also AS varchar), '') AS "再次手术原因",
    coalesce(cast(a.unplanned_oper_check_status AS varchar), '') AS "非计划审核状态",
    array_join(
        array_agg(trim(coalesce(cast(o.operation_name AS varchar), '')) ORDER BY o.id),
        '+'
    ) AS "手术名称"
FROM base_visit bv
INNER JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ieg
    ON coalesce(cast(ieg.isdeleted AS varchar), '0') = '0'
   AND (
        trim(cast(ieg.id AS varchar)) = trim(cast(bv.ipreg_id AS varchar))
     OR trim(cast(ieg.ipi_registration_no AS varchar)) = trim(cast(bv.visit_no AS varchar))
   )
INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    ON a.ipi_registration_id = ieg.id
   AND coalesce(cast(a.isdeleted AS varchar), '0') = '0'
INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
    ON ar.sam_apply_id = a.id
   AND coalesce(cast(ar.isdeleted AS varchar), '0') = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_apply_op o
    ON o.sam_apply_id = a.id
   AND coalesce(cast(o.isdeleted AS varchar), '0') = '0'
WHERE coalesce(cast(a.health_service_org_id AS varchar), '') = 'HXSSMZK'
  AND coalesce(cast(a.oper_type AS varchar), '') = 'ROOM_OPER'
  AND coalesce(cast(a.s_sssyzt_dm AS varchar), '') >= '70'
  AND nullif(trim(coalesce(cast(ar.oper_beging_date AS varchar), '')), '') IS NOT NULL
  AND (
        coalesce(cast(a.is_unplanned_oper AS varchar), '') IN ('1', 'Y', 'y', '是')
     OR trim(coalesce(cast(a.reason_oper_also AS varchar), '')) LIKE '%非计划%'
  )
GROUP BY
    bv.visit_no,
    ieg.ipi_registration_no,
    ieg.ipno,
    bv.in_dt,
    bv.out_dt,
    a.id,
    a.scheduled_date,
    ar.oper_beging_date,
    a.is_unplanned_oper,
    a.reason_oper_also,
    a.unplanned_oper_check_status
ORDER BY bv.out_dt, bv.visit_no, a.scheduled_date;
