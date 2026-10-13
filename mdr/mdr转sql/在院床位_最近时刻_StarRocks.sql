-- 在院床位：只取全表最近一个快照（StarRocks）
-- 时刻：先取最大 repdate，再在这一天取最大 rephour（按数值，不按字符串）
-- 字典关联、床位列、运管口径与已跑通的 在院床位_StarRocks.sql 相同
-- 床位列：prebednum / approvebed / limitbed
-- dict_bednum 后半关联截图被截断，这里仍只按 wardid_code

with base as (
    select
        repdate,
        rephour
    from m1.mdr_beinhosp
    where iswait in (0, '0')
      and medorgcode = 'HID0101'
      and repdate is not null
      and repdate <> ''
      and rephour regexp '^[0-9]+$'
),
latest_dt as (
    select max(cast(repdate as date)) as rep_dt
    from base
),
latest_hr as (
    select max(cast(b.rephour as int)) as rep_hr
    from base as b
    inner join latest_dt as d
        on cast(b.repdate as date) = d.rep_dt
)
select
    cast(a.repdate as date) as `日期`,
    lpad(cast(cast(a.rephour as int) as string), 2, '0') as `时刻`,
    a.currentwardname as `护理单元`,
    a.currentwardcode as `护理单元编码`,
    a.currentmedelementname as `医疗单元`,
    a.currentmedelementcode as `医疗单元编码`,
    d.code as `运管科室编码`,
    d.name as `运管科室名称`,
    e.ygloctyp_desc as `运管医疗单元分类`,
    sum(a.beinhospperscount) as `在院人次`,
    cast(max(b.prebednum) as int) as `编制床位`,
    cast(max(b.approvebed) as int) as `核定床位`,
    cast(max(b.limitbed) as int) as `极限床位`
from m1.mdr_beinhosp as a
inner join latest_dt as ld
    on cast(a.repdate as date) = ld.rep_dt
inner join latest_hr as lh
    on cast(a.rephour as int) = lh.rep_hr
left join md.dict_bednum as b
    on a.currentwardcode = b.wardid_code
left join md.tbl_1306_h as c
    on c.ctloc_code = a.currentmedelementcode
left join md.tbl_1305_h as d
    on d.id = c.ygks
left join md.dim_ygloctype as e
    on d.depttypeid = e.oid
where a.iswait in (0, '0')
  and a.medorgcode = 'HID0101'
  and a.rephour regexp '^[0-9]+$'
group by
    cast(a.repdate as date),
    cast(a.rephour as int),
    a.currentwardname,
    a.currentwardcode,
    a.currentmedelementname,
    a.currentmedelementcode,
    d.code,
    d.name,
    e.ygloctyp_desc
having sum(a.beinhospperscount) > 0;
