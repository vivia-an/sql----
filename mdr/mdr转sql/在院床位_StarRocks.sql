-- 在院床位：Kylin/Hive → StarRocks（逻辑与截图一致）
-- 字典库 mdv → md：DICT_BEDNUM / tbl_1306_h / tbl_1305_h；dim_ygloctype 原本就是 md
-- 事实表：m1.mdr_beinhosp
--
-- 仅引擎差异：
--   1) 派生表必须有别名 t
--   2) 中文列名用反引号
--   3) GROUP BY 补 CURRENTMEDELEMENTCODE（SELECT/PARTITION 已有；Hive 可省略，SR 不能）
--   4) iswait 落表是字符串，SR 用 in (0,'0') 对齐 Hive 隐式转换
--
-- DICT_BEDNUM：截图可见 CURRENTWARDCODE = wardId_Code；
--   AND a.CURRENTMEDELEMENT 后半被截断，仓库无表结构，未编造 b 侧字段

SELECT
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
FROM (
    SELECT
        CAST(a.repdate AS DATE) AS `日期`,
        a.REPHOUR AS `时刻`,
        a.CURRENTWARDNAME AS `护理单元`,
        a.CURRENTWARDCODE AS `护理单元编码`,
        a.CURRENTMEDELEMENTNAME AS `医疗单元`,
        a.CURRENTMEDELEMENTCODE AS `医疗单元编码`,
        d.code AS `运管科室编码`,
        d.Name AS `运管科室名称`,
        e.ygloctyp_desc AS `运管医疗单元分类`,
        ROW_NUMBER() OVER (
            PARTITION BY
                a.repdate,
                a.CURRENTWARDNAME,
                a.CURRENTWARDCODE,
                a.CURRENTMEDELEMENTNAME,
                a.CURRENTMEDELEMENTCODE,
                d.code,
                d.Name,
                e.ygloctyp_desc
            ORDER BY a.REPHOUR DESC
        ) AS num,
        SUM(a.BEINHOSPPERSCOUNT) AS `在院人次`,
        CAST(MAX(b.PREBEDNUM) AS INT) AS `编制床位`,
        CAST(MAX(b.APPROVEDBED) AS INT) AS `核定床位`,
        CAST(MAX(b.LIMITBED) AS INT) AS `极限床位`
    FROM m1.mdr_beinhosp AS a
    LEFT JOIN md.DICT_BEDNUM AS b
        ON a.CURRENTWARDCODE = b.wardId_Code
        -- AND a.CURRENTMEDELEMENT???? = b.????  截图截断，有字段再补
    LEFT JOIN md.tbl_1306_h AS c
        ON c.ctloc_code = a.CURRENTMEDELEMENTCODE
    LEFT JOIN md.tbl_1305_h AS d
        ON d.id = c.ygks
    LEFT JOIN md.dim_ygloctype AS e
        ON d.depttypeid = e.oid
    WHERE a.iswait IN (0, '0')
      -- AND c.CTD_Status = '1'
      AND a.medorgcode = 'HID0101'
      -- AND a.CURRENTWARDNAME = '第71护理单元'
      -- AND a.REPHOUR IN ('07', '16')
    GROUP BY
        a.repdate,
        a.REPHOUR,
        a.CURRENTWARDNAME,
        a.CURRENTWARDCODE,
        a.CURRENTMEDELEMENTNAME,
        a.CURRENTMEDELEMENTCODE,
        d.code,
        d.Name,
        e.ygloctyp_desc
    HAVING SUM(a.BEINHOSPPERSCOUNT) > 0
) t
WHERE t.num = 1;
