-- 默认版（宽口径探查）：不按申请科室/单位/手术类型/完成态过滤，先把行带全；择期仍与报表明细一致
-- 血缘：sam_apply / sam_reg / sam_reg_op / sam_apply_op / sam_anar / ipi_registration / hra00_department / gb_t_2261_1_2003
--
-- v4：去掉「单位」类筛选（原对 req 麻醉手术中心 LIKE）；去掉 oper_type、s_sssyzt、is_reject 等 WHERE，避免误杀
-- v5：SELECT 与需求 12 字段对齐（顺序一致）；探查用列移至文末注释块
-- 择期：coalesce(reg,a).is_emergency IS DISTINCT FROM '1'（与 CASE 急诊/择期 一致）
-- 时间：入室、出 PACU 均有值，且前 10 位日期落在 p_sched（若仍无数据，见文末「宽口径 B」仅按排程日期）
--
-- 需求字段映射：病案号/登记号←ipi/opc；性别←GB_T；年龄←生日+入室年差；入出院←ipi；入出院科室←hra00+ipi；离院方式←ipi.s_cyqk_dm(代码，名称需字典另接)；诊断/手术「及编码」←main_diag+占位、手术名+ICD9CM3

WITH p_sched AS (
    SELECT
        '2022-01-01' AS d_start,
        '2025-12-20' AS d_end
),
rop_agg AS (
    SELECT
        sam_reg_id,
        array_join(array_agg(operation_name ORDER BY operation_name), '；') AS operation_name_agg,
        array_join(array_agg(operation_code ORDER BY operation_name), '；') AS operation_code_agg
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_reg_op
    WHERE isdeleted = '0'
    GROUP BY sam_reg_id
),
aop_agg AS (
    SELECT
        sam_apply_id,
        array_join(array_agg(operation_name ORDER BY operation_name), '；') AS operation_name_agg,
        array_join(array_agg(operation_code ORDER BY operation_name), '；') AS operation_code_agg
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply_op
    WHERE isdeleted = '0'
    GROUP BY sam_apply_id
)
SELECT
    ieg.ipno AS "病案号",
    coalesce(ieg.ipi_registration_no, opc.opc_registration_no) AS "登记号",
    xb.s_xb_cmc AS "性别",
    CASE
        WHEN info.birthday IS NOT NULL
            AND info.in_oproom_date IS NOT NULL
            AND length(trim(info.birthday)) >= 4
            AND length(trim(info.in_oproom_date)) >= 4
        THEN cast(
            cast(substr(trim(info.in_oproom_date), 1, 4) AS INTEGER)
            - cast(substr(trim(info.birthday), 1, 4) AS INTEGER) AS VARCHAR
        )
        ELSE ''
    END AS "年龄",
    ieg.registration_date AS "入院日期",
    coalesce(ieg.leave_dept_date, ieg.discharge_date) AS "出院日期",
    ry.department_chinese_name AS "入院科室",
    cy.department_chinese_name AS "出院科室",
    coalesce(ieg.s_cyqk_dm, CAST('' AS VARCHAR)) AS "离院方式",
    concat(
        trim(coalesce(info.main_diag, '')),
        ' | ICD10:',
        trim(coalesce(info.diag_icd10_placeholder, ''))
    ) AS "诊断名称及编码",
    concat(
        trim(coalesce(info.oper_name, '')),
        ' | ICD9CM3:',
        trim(coalesce(info.oper_codes, ''))
    ) AS "手术名称及编码",
    info.scheduled_date AS "手术日期"
FROM (
    SELECT
        coalesce(max(reg.ipi_registration_id), max(a.ipi_registration_id)) AS ipi_registration_id,
        coalesce(max(reg.opc_registration_id), max(a.opc_registration_id)) AS opc_registration_id,
        coalesce(max(rop.operation_name_agg), max(aop.operation_name_agg)) AS oper_name,
        coalesce(max(rop.operation_code_agg), max(aop.operation_code_agg)) AS oper_codes,
        coalesce(max(reg.birthday), max(a.birthday)) AS birthday,
        coalesce(max(reg.main_diag), max(a.main_diag)) AS main_diag,
        CAST('' AS VARCHAR) AS diag_icd10_placeholder,
        max(a.scheduled_date) AS scheduled_date,
        coalesce(max(reg.s_xb_dm), max(a.s_xb_dm)) AS s_xb_dm,
        max(ar.in_oproom_date) AS in_oproom_date,
        max(ar.rec_out_date) AS rec_out_date
    FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
    INNER JOIN hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
        ON a.id = ar.sam_apply_id AND ar.isdeleted = '0'
    LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.sam_reg reg
        ON reg.id = a.id AND reg.isdeleted = '0'
    LEFT JOIN rop_agg rop
        ON rop.sam_reg_id = reg.id
    LEFT JOIN aop_agg aop
        ON aop.sam_apply_id = a.id
    WHERE a.isdeleted = '0'
      AND coalesce(reg.is_emergency, a.is_emergency) IS DISTINCT FROM '1'
      AND nullif(trim(ar.in_oproom_date), '') IS NOT NULL
      AND nullif(trim(ar.rec_out_date), '') IS NOT NULL
      AND length(trim(ar.in_oproom_date)) >= 10
      AND length(trim(ar.rec_out_date)) >= 10
      AND substr(trim(ar.in_oproom_date), 1, 10) >= (SELECT d_start FROM p_sched)
      AND substr(trim(ar.in_oproom_date), 1, 10) <= (SELECT d_end FROM p_sched)
      AND substr(trim(ar.rec_out_date), 1, 10) >= (SELECT d_start FROM p_sched)
      AND substr(trim(ar.rec_out_date), 1, 10) <= (SELECT d_end FROM p_sched)
    GROUP BY a.id
) info
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.ipi_registration ieg
    ON ieg.id = info.ipi_registration_id AND ieg.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.opc_registration opc
    ON opc.id = info.opc_registration_id AND opc.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department ry
    ON ry.id = ieg.ipi_dept_id AND ry.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.hra00_department cy
    ON cy.id = ieg.dept_id AND cy.isdeleted = '0'
LEFT JOIN hid0101_orcl_operaanesthisa_emrhis.gb_t_2261_1_2003 xb
    ON xb.s_xb_dm = info.s_xb_dm AND xb.isdeleted = '0'
ORDER BY info.in_oproom_date;

/*
-- 可选：探查列（与需求 12 列无关时单独执行）
-- SELECT info.apply_id, info.is_emergency, req.department_chinese_name, ...
======== 若仍无行：多半是入室/出 PACU 字符串前 10 位不是 yyyy-mm-dd，或该时段无 PACU 出室时间 ========

-- 宽口径 B：与《手麻报表明细》一致，仅用排程日期落窗（不强制 rec_out / in_oproom 格式）
WITH p_sched AS (
    SELECT '2022-01-01 00:00:00' AS dt_start, '2025-12-20 23:59:59' AS dt_end
)
SELECT count(*) AS cnt
FROM hid0101_orcl_operaanesthisa_emrhis.sam_apply a
WHERE a.isdeleted = '0'
  AND a.scheduled_date >= (SELECT dt_start FROM p_sched)
  AND a.scheduled_date <= (SELECT dt_end FROM p_sched);

--- 诊断块（与当前宽口径内层条件对齐）
SELECT count(*) AS c_anar
FROM hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
WHERE ar.isdeleted = '0'
  AND nullif(trim(ar.in_oproom_date), '') IS NOT NULL
  AND nullif(trim(ar.rec_out_date), '') IS NOT NULL
  AND length(trim(ar.in_oproom_date)) >= 10
  AND length(trim(ar.rec_out_date)) >= 10
  AND substr(trim(ar.in_oproom_date), 1, 10) BETWEEN '2022-01-01' AND '2025-12-20';

SELECT DISTINCT substr(trim(ar.in_oproom_date), 1, 12) AS sample_in_fmt, count(*) AS n
FROM hid0101_orcl_operaanesthisa_emrhis.sam_anar ar
WHERE ar.isdeleted = '0' AND ar.in_oproom_date IS NOT NULL
GROUP BY 1 ORDER BY n DESC LIMIT 20;
*/
