-- 检验明细：CFYS/CFKS 回源 HIS 医嘱；WJJGDM/WJJGMC 取 order_main 外检子类
-- 主血缘：mt_reportdet -> mt_report(orderdetid) -> oe_orditem -> CT_CareProv/CT_Loc
-- 外检：mt_report_orderdetid = order_main_dstablevalue；大类=外检时 WJJGDM=ordersclasscode，WJJGMC=ordersclassname

select
  tt.JZBS as JZBS,
  tt.CFYS as CFYS,
  tt.CFKS as CFKS,
  tt.FWLB as FWLB,
  tt.ZLFWXMID as ZLFWXMID,
  tt.JCJYBGID as JCJYBGID,
  tt.JCJYSJ as JCJYSJ,
  tt.JCJYXMMC as JCJYXMMC,
  tt.JYJG as JYJG,
  tt.JYDW as JYDW,
  tt.JYCKZFW as JYCKZFW,
  tt.JCFX as JCFX,
  tt.JCJL as JCJL,
  tt.CFID as CFID,
  tt.WJJGDM as WJJGDM,
  tt.WJJGMC as WJJGMC,
  tt.YLJGBM as YLJGBM,
  tt.YLJGMC as YLJGMC
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
    '检验' as FWLB,
    tari.tari_code as ZLFWXMID,
    rep.mt_report_reportid as JCJYBGID,
    rep.mt_report_checkdttm as JCJYSJ,
    repdet.mt_reportdet_sitemcnname as JCJYXMMC,
    repdet.mt_reportdet_resultproperty as JYJG,
    repdet.mt_reportdet_unit as JYDW,
    repdet.mt_reportdet_referrange as JYCKZFW,
    '' as JCFX,
    '' as JCJL,
    rep.mt_report_orderdetid as CFID,
    case
      when coalesce(om.order_main_orderpclassname, '') = '外检'
        then coalesce(om.order_main_ordersclasscode, '')
      else ''
    end as WJJGDM,
    case
      when coalesce(om.order_main_orderpclassname, '') = '外检'
        then coalesce(om.order_main_ordersclassname, '')
      else ''
    end as WJJGMC,
    '12510000450756139Y' as YLJGBM,
    '四川大学华西医院(四川省国际医院)' as YLJGMC,
    row_number() over (
      partition by rep.mt_report_reportid, repdet.mt_reportdet_sitemcnname
      order by rep.mt_report_reportid, repdet.mt_reportdet_sitemcnname
    ) as rn
  from datacenter_db.mt_reportdet repdet
  left join datacenter_db.mt_report rep
    on rep.mt_report_reportid = repdet.mt_reportdet_reportid
  left join (
    select
      paadm_rowid,
      paadm_admno,
      paadm_admdate,
      paadm_type
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
  left join datacenter_db.order_main om
    on om.medorgcode = 'HID0101'
   and om.order_main_isdeleted = '0'
   and cast(om.order_main_dstablevalue as varchar) = cast(rep.mt_report_orderdetid as varchar)
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
    repdet.medorgcode = 'HID0101'
    and repdet.mt_reportdet_isdeleted = '0'
    and repdet.datasourceflag in ('8', '32')
    and adm.paadm_admdate >= '2024-05-31'
    and adm.paadm_admdate < '2026-05-31'
    and repdet.mt_reportdet_reportstatusname in ('audited', 'sent', 'reported', 'finished')
    and repdet.mt_reportdet_resultproperty is not null
) tt
where
  JZBS is not null
  and ZLFWXMID is not null
  and JCJYBGID is not null
  and JCJYSJ is not null
  and JCJYXMMC is not null
  and CFID is not null
  and rn = 1;

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
