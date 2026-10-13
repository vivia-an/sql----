-- 在院床位：Kylin/Hive → StarRocks（逻辑与截图一致）
-- 字典库 mdv → md；表名、字段名一律小写
-- 事实表：m1.mdr_beinhosp
--
-- 仅引擎差异：
--   1) 派生表必须有别名 t
--   2) 中文列名用反引号
--   3) group by 补 currentmedelementcode（select/partition 已有；hive 可省略，sr 不能）
--   4) iswait 落表是字符串，sr 用 in (0,'0') 对齐 hive 隐式转换
--
-- dict_bednum：截图可见 currentwardcode = wardid_code；
--   and a.currentmedelement 后半被截断，仓库无表结构，未编造 b 侧字段
-- 【未找到】md.dict_bednum.approvedbed 已报 cannot be resolved
--   prebednum / limitbed 同表、仓库同样无证据，下一报错也会是这两列
--   先跑 在院床位_dict_bednum字段探测_StarRocks.sql，再改三列映射

select
    t.`日期`,
    t.`时刻`,
    t.`护理单元`,
    t.`护理单元编码`,
    t.`医疗单元`,
    t.`医疗单元编码`,
    t.`运管科室编码`,
    t.`运管科室名称`,
    t.`运管医疗单元分类`,
    t.`在院人次`,
    t.`编制床位`,
    t.`核定床位`,
    t.`极限床位`
from (
    select
        cast(a.repdate as date) as `日期`,
        a.rephour as `时刻`,
        a.currentwardname as `护理单元`,
        a.currentwardcode as `护理单元编码`,
        a.currentmedelementname as `医疗单元`,
        a.currentmedelementcode as `医疗单元编码`,
        d.code as `运管科室编码`,
        d.name as `运管科室名称`,
        e.ygloctyp_desc as `运管医疗单元分类`,
        row_number() over (
            partition by
                a.repdate,
                a.currentwardname,
                a.currentwardcode,
                a.currentmedelementname,
                a.currentmedelementcode,
                d.code,
                d.name,
                e.ygloctyp_desc
            order by a.rephour desc
        ) as num,
        sum(a.beinhospperscount) as `在院人次`,
        cast(max(b.prebednum) as int) as `编制床位`,
        cast(max(b.approvedbed) as int) as `核定床位`,
        cast(max(b.limitbed) as int) as `极限床位`
    from m1.mdr_beinhosp as a
    left join md.dict_bednum as b
        on a.currentwardcode = b.wardid_code
        -- and a.currentmedelement???? = b.????  截图截断，有字段再补
    left join md.tbl_1306_h as c
        on c.ctloc_code = a.currentmedelementcode
    left join md.tbl_1305_h as d
        on d.id = c.ygks
    left join md.dim_ygloctype as e
        on d.depttypeid = e.oid
    where a.iswait in (0, '0')
      -- and c.ctd_status = '1'
      and a.medorgcode = 'HID0101'
      -- and a.currentwardname = '第71护理单元'
      -- and a.rephour in ('07', '16')
    group by
        a.repdate,
        a.rephour,
        a.currentwardname,
        a.currentwardcode,
        a.currentmedelementname,
        a.currentmedelementcode,
        d.code,
        d.name,
        e.ygloctyp_desc
    having sum(a.beinhospperscount) > 0
) t
where t.num = 1;
