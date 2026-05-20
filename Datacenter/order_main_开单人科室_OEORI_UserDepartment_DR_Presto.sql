-- =============================================================================
-- 开单人科室（医嘱录入人所在科室）独立查询：可唯一对齐 datacenter_db.order_main
-- =============================================================================
-- 【证据链 — HIS 基本表结构】文件：sql----/HIS/his基本表结构.md
--   1) OE_OrdItem 字段表 3.2.4.2：
--      - 序号5  OEORI_OrdDept_DR     → 开医嘱科室     → DR → CT_Loc  （DC 已有 order_main_dept*，即「开单科室」）
--      - 序号21 OEORI_UserDepartment_DR → 医生科室     → DR → CT_Loc  （本查询：「开单人科室」/录入操作所在科室）
--   2) 业务别名（同文档约 4506–4507 行）：
--      - OEORI_UserAdd            → 医嘱录入人      → SS_User
--      - OEORI_UserDepartment_DR  → 医嘱录入科室    → CT_LOC
-- 【cache 层取值】hid0101/hid0103_cache_his_dhcapp_sqluser.oe_orditem
--   OE_OrdItem.OEORI_UserDepartment_DR = CT_Loc.CTLOC_RowID（与 DocCTLoc 同构，换 DR 字段即可）
-- 【与 datacenter 唯一关联】
--   order_main_dstablekey = 'OEORI_RowId'
--   AND CAST(order_main_dstablevalue AS VARCHAR) = CAST(oe_orditem.oeori_rowid AS VARCHAR)
--   再加 medorgcode 与对应 catalog 一致；DC 主键业务侧常用 rowkey 校验一行一单明细。
-- 【与开单科室对比】开单科室=开立时指定的医嘱科室(OEORI_OrdDept_DR)；开单人科室=录入时刻用户所属科室(OEORI_UserDepartment_DR)，二者均可落 CT_Loc，语义不同。
-- =============================================================================

SELECT
  om.rowkey AS dc_rowkey,
  om.medorgcode,
  om.order_main_dstablekey,
  om.order_main_dstablevalue AS oeori_rowid,
  om.order_main_deptcode AS order_main_orddept_code,
  om.order_main_deptname AS order_main_orddept_name,
  CAST(COALESCE(ud1.ctloc_code, ud3.ctloc_code) AS VARCHAR) AS order_main_orderuserdept_code,
  CAST(COALESCE(ud1.ctloc_rowid, ud3.ctloc_rowid) AS VARCHAR) AS order_main_orderuserdept_id,
  CAST(COALESCE(ud1.ctloc_desc, ud3.ctloc_desc) AS VARCHAR) AS order_main_orderuserdept_name
FROM datacenter_db.order_main om
LEFT JOIN hid0101_cache_his_dhcapp_sqluser.oe_orditem o1
  ON om.medorgcode = 'HID0101'
 AND om.order_main_dstablevalue = CAST(o1.oeori_rowid AS VARCHAR)
 AND o1.isdeleted = '0'
LEFT JOIN hid0101_cache_his_dhcapp_sqluser.ct_loc ud1
  ON om.medorgcode = 'HID0101'
 AND ud1.ctloc_rowid = o1.oeori_userdepartment_dr
LEFT JOIN hid0103_cache_his_dhcapp_sqluser.oe_orditem o3
  ON om.medorgcode = 'HID0103'
 AND om.order_main_dstablevalue = CAST(o3.oeori_rowid AS VARCHAR)
 AND o3.isdeleted = '0'
LEFT JOIN hid0103_cache_his_dhcapp_sqluser.ct_loc ud3
  ON om.medorgcode = 'HID0103'
 AND ud3.ctloc_rowid = o3.oeori_userdepartment_dr
WHERE om.isdeleted = '0'
  AND om.order_main_dstablekey = 'OEORI_RowId'
  AND om.medorgcode IN ('HID0101', 'HID0103');

-- 异常血缘：oeori_userdepartment_dr 为空 → 三列为 NULL；HIS 无对应 CT_Loc 行 → NULL；dstablevalue 与 oeori_rowid 不一致 → 左表有行但 o1/o3 全空 → 三列 NULL
-- 列名若需与集群一致：SHOW COLUMNS FROM ... oe_orditem / ct_loc（可能为 oeori_userdepartment_dr 大小写差异）
