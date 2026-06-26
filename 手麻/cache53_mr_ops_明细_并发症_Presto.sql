-- cache53.mr_ops 明细 + 并发症（Presto）
-- 原因：mr_ops/mr_base 无并发症列；ZPack.testWyl5_BFZFLAG 仅 Cache 可用
-- 并发症：Visit_Diag T81/T88（关联键探查 Desc 全 0，ICD 2025 约 1004 ADM）

WITH params AS (
    SELECT
        '2025-01-01' AS startdate,
        '2025-12-31 23:59:59' AS enddate,
        cast(null AS varchar) AS opsdoc,
        cast(null AS varchar) AS opsas
),
visit_icd AS (
    SELECT DISTINCT trim(cast(diag."Visit_Diag_VisitNo" AS varchar)) AS visit_no
    FROM datacenter_db."Visit_Diag" diag
    WHERE diag."Visit_Diag_MedOrgCode" = 'HID0101'
      AND coalesce(cast(diag."Visit_Diag_IsDeleted" AS varchar), '0') = '0'
      AND (
            trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T81%'
            OR trim(cast(diag."Visit_Diag_DiagICDCode" AS varchar)) LIKE 'T88%'
          )
)

SELECT
    o.mrops_paadmdr AS "患者ADM",
    o.mrops_papmino AS "登记号",
    o.mrops_padmno AS "病案号",
    b.mrb_paname AS "姓名",
    b.mrb_panationdesc AS "民族",
    b.mrb_pasexdr AS "性别代码",
    b.mrb_paageyear AS "年龄",
    b.mrb_padindate AS "入院日期",
    o.mrops_foutdate AS "出院日期",
    b.mrb_painlocdesc AS "入院科室",
    b.mrb_paoutlocdesc AS "出院科室",
    o.mrops_mainopsflag AS "主手术标志",
    o.mrops_opfirstcode AS "手术编码",
    o.mrops_opfirstname AS "手术名称",
    o.mrops_assistantfirst AS "手术一助",
    o.mrops_assistantsecond AS "手术二助",
    o.mrops_opdocdesc AS "手术医师",
    o.mrops_narcosisdocname AS "麻醉医师",
    o.mrops_surgtype AS "手术类型",
    o.mrops_narcosisname AS "麻醉方式名称",
    o.mrops_opsdate AS "手术日期",
    b.mrb_paouthealdr AS "出院情况_4为死亡",
    CASE
        WHEN vi.visit_no IS NOT NULL THEN 1
        ELSE 0
    END AS "并发症"
FROM cache53.mr_ops o
INNER JOIN cache53.mr_base b
    ON cast(o.mrops_mrbaseid AS varchar) = cast(b.id AS varchar)
LEFT JOIN hid0101_cache_his_dhcapp_sqluser.pa_adm adm
    ON cast(adm.paadm_rowid AS varchar) = cast(o.mrops_paadmdr AS varchar)
LEFT JOIN visit_icd vi
    ON vi.visit_no IN (
        cast(o.mrops_paadmdr AS varchar),
        trim(cast(adm.paadm_admno AS varchar)),
        trim(cast(o.mrops_padmno AS varchar)),
        trim(cast(b.mrb_padmno AS varchar)),
        trim(cast(b.mrb_paadmdr AS varchar))
    )
CROSS JOIN params p
WHERE trim(coalesce(b.mrb_checkitem2, '')) = '医院'
  AND coalesce(cast(o.isdeleted AS varchar), '0') = '0'
  AND coalesce(cast(b.isdeleted AS varchar), '0') = '0'
  AND trim(cast(o.mrops_foutdate AS varchar)) >= p.startdate
  AND trim(cast(o.mrops_foutdate AS varchar)) <= p.enddate
  AND (
        p.opsdoc IS NULL
        OR trim(o.mrops_opdocdesc) = p.opsdoc
        OR trim(o.mrops_assistantfirst) = p.opsas
      );

-- 仅看并发症=1 的明细：外层 WHERE "并发症" = 1
