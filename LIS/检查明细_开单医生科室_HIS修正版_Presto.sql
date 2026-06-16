-- 检查明细：CFYS/CFKS 回源 HIS 医嘱
-- 主血缘：mt_report.mt_report_orderdetid -> oe_orditem -> CT_CareProv/CT_Loc
-- 异常：orderdetid 为空或医嘱/字典未命中时，退回 mt_report 申请医生/申请科室。

select
  t.JZBS as JZBS,
  t.CFYS as CFYS,
  t.CFKS as CFKS,
  t.FWLB as FWLB,
  t.ZLFWXMID as ZLFWXMID,
  t.JCJYBGID as JCJYBGID,
  t.JCJYSJ as JCJYSJ,
  t.JCJYXMMC as JCJYXMMC,
  t.JYJG as JYJG,
  t.JYDW as JYDW,
  t.JYCKZFW as JYCKZFW,
  t.JCFX as JCFX,
  t.JCJL as JCJL,
  t.CFID as CFID,
  t.WJJGDM as WJJGDM,
  t.WJJGMC as WJJGMC,
  t.YLJGBM as YLJGBM,
  t.YLJGMC as YLJGMC
from (
  select
    adm.paadm_rowid as JZBS,
    coalesce(
      nullif(trim(doc.ctpcp_desc), ''),
      nullif(trim(rep.mt_report_applydoctname), '')
    ) as CFYS,
    coalesce(
      nullif(trim(orddept.ctloc_desc), ''),
      nullif(trim(rep.mt_report_applydeptname), '')
    ) as CFKS,
    '检查' as FWLB,
    tari.tari_code as ZLFWXMID,
    rep.mt_report_reportid as JCJYBGID,
    rep.mt_report_checkdttm as JCJYSJ,
    rep.mt_report_itemname as JCJYXMMC,
    '' as JYJG,
    '' as JYDW,
    '' as JYCKZFW,
    rep.mt_report_examfinding as JCFX,
    rep.mt_report_resultdesc as JCJL,
    rep.mt_report_orderdetid as CFID,
    '' as WJJGDM,
    '' as WJJGMC,
    '12510000450756139Y' as YLJGBM,
    '四川大学华西医院(四川省国际医院)' as YLJGMC
  from datacenter_db.mt_report rep
  left join (
    select
      paadm_rowid,
      paadm_admno,
      paadm_admdate
    from hid0101_cache_his_dhcapp_sqluser.pa_adm
  ) adm
    on adm.paadm_admno = rep.mt_report_visitno
  left join (
    select
      oeori_rowid,
      oeori_doctor_dr,
      oeori_orddept_dr
    from hid0101_cache_his_dhcapp_sqluser.oe_orditem
    where isdeleted = '0'
  ) oe
    on cast(oe.oeori_rowid as varchar) = cast(rep.mt_report_orderdetid as varchar)
  left join (
    select
      ctpcp_rowid1,
      ctpcp_desc
    from hid0101_cache_his_dhcapp_sqluser.ct_careprov
  ) doc
    on doc.ctpcp_rowid1 = oe.oeori_doctor_dr
  left join (
    select
      ctloc_rowid,
      ctloc_desc
    from hid0101_cache_his_dhcapp_sqluser.ct_loc
  ) orddept
    on orddept.ctloc_rowid = oe.oeori_orddept_dr
  left join (
    select
      arcim_rowid,
      arcim_code
    from hid0101_cache_his_dhcapp_sqluser.arc_itmmast
  ) arcim
    on arcim.arcim_code = rep.mt_report_itemcode
  left join (
    select
      olt_arcim_dr,
      olt_tariff_dr
    from hid0101_cache_his_dhcapp_sqluser.dhc_orderlinktar
  ) lnk
    on lnk.olt_arcim_dr = arcim.arcim_rowid
  left join (
    select
      tari_rowid,
      tari_code
    from hid0101_cache_his_dhcapp_sqluser.dhc_taritem
  ) tari
    on tari.tari_rowid = lnk.olt_tariff_dr
  where
    rep.medorgcode = 'HID0101'
    and rep.mt_report_isdeleted = '0'
    and rep.datasourceflag not in ('8', '32')
    and adm.paadm_admdate between '2022-01-01' and '2022-01-03'
    and rep.mt_report_reportstatusname in (
      '已发布',
      '已完成',
      '已报告',
      '已审核',
      '报告已审核',
      '报告已打印',
      '终审状态',
      '已报告,已签名(主任医生)',
      '审核完成',
      '确认补充报告',
      '确认报告'
    )
) t;

/*
诊断 SQL：回源命中与补空效果。
把上面 from/where 主体保留到 base 后执行：

select
  count(*) as total_rows,
  count_if(nullif(trim(rep.mt_report_applydoctname), '') is null) as report_doctor_empty_rows,
  count_if(oe.oeori_rowid is not null) as his_order_hit_rows,
  count_if(nullif(trim(rep.mt_report_applydoctname), '') is null and nullif(trim(doc.ctpcp_desc), '') is not null) as doctor_recovered_rows,
  count_if(nullif(trim(rep.mt_report_applydeptname), '') is null and nullif(trim(orddept.ctloc_desc), '') is not null) as dept_recovered_rows
from base;
*/
