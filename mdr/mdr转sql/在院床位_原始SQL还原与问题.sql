-- 在院床位：按截图还原的原始 SQL（StarRocks/MySQL 风格）
-- 截图2 第24行在 a.CURRENTMEDELEMENT 处截断
-- 仓库无 mdv.DICT_BEDNUM 表结构，b 侧后半关联未补全，勿当可执行定稿

--床位
SELECT *
FROM (
    SELECT
        CAST(repdate AS DATE) AS "日期",
        REPHOUR AS "时刻",
        CURRENTWARDNAME AS "护理单元",
        CURRENTWARDCODE AS "护理单元编码",
        CURRENTMEDELEMENTNAME AS "医疗单元",
        CURRENTMEDELEMENTCODE AS "医疗单元编码",
        -- c.CODE,
        -- c.NAME,
        d.code AS "运管科室编码",
        d.Name AS "运管科室名称",
        e.ygloctyp_desc AS "运管医疗单元分类",
        ROW_NUMBER() OVER (
            PARTITION BY
                repdate,
                CURRENTWARDNAME,
                CURRENTWARDCODE,
                CURRENTMEDELEMENTNAME,
                CURRENTMEDELEMENTCODE,
                d.code,
                d.Name,
                e.ygloctyp_desc
            ORDER BY REPHOUR DESC
        ) AS num,
        SUM(BEINHOSPPERSCOUNT) AS "在院人次",
        CAST(MAX(PREBEDNUM) AS INT) AS "编制床位",
        CAST(MAX(APPROVEDBED) AS INT) AS "核定床位",
        CAST(MAX(LIMITBED) AS INT) AS "极限床位"
    FROM m1.MDR_BEINHOSP AS a
    LEFT JOIN mdv.DICT_BEDNUM AS b
        ON a.CURRENTWARDCODE = b.wardId_Code
       AND a.CURRENTMEDELEMENT   -- 【截断未找到】截图到此为止；b 侧字段仓库无证据
    LEFT JOIN mdv.tbl_1306_h AS c
        ON c.ctloc_code = a.CURRENTMEDELEMENTCODE
    LEFT JOIN mdv.tbl_1305_h AS d
        ON d.id = c.ygks
    LEFT JOIN md.dim_ygloctype AS e
        ON d.depttypeid = e.oid
    WHERE a.iswait = 0
      -- AND c.CTD_Status = '1'
      AND a.medorgcode = 'HID0101'
      -- AND CURRENTWARDNAME = '第71护理单元'
      -- AND REPHOUR IN ('07', '16')
    GROUP BY
        repdate,
        REPHOUR,
        CURRENTWARDNAME,
        CURRENTWARDCODE,
        CURRENTMEDELEMENTNAME,
        -- 截图 GROUP BY 未写 CURRENTMEDELEMENTCODE，SELECT 却有该列
        d.code,
        d.Name,
        e.ygloctyp_desc
    HAVING SUM(BEINHOSPPERSCOUNT) > 0
) t    -- 截图无派生表别名；MySQL/StarRocks 一般要别名
WHERE num = 1;
