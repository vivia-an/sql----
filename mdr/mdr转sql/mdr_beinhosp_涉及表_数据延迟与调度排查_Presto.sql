-- starrocks-be-inhospital / mdr_beinhosp 涉及表延迟 + 调度排查（单条 Presto）
-- 对照：DataX querySql = Datacenter/在院/在院.sql（sql 分支 HID0123 拆院区版）
--      落表 m1.mdr_beinhosp；writer 无 preSql/postSql
--
-- 现象：任务跑完「数据没变化」
-- 根因优先级（先看本结果再查调度）：
--   A) 01/02 在院口径 lastupdatedttm / hoodie 已停 → DC 源没刷新，快照业务字段必然重复
--   B) 10~13 主口径 visitid 集合与「近1小时有更新」差很大 → 在院人没变，或出院/转科未回写 status
--   C) StarRocks 当天无新 rephour（文末 SR 段）→ 任务没写入或看错 newest/旧小时
--   D) 字典/ct_loc 延迟只影响院区拆分和运管科室名，不改变在院人数
--
-- 未找到、勿编造：
--   visit_record 的 HIS 源表（PA_Adm / Visit_IPReg / 多院区 cache）仓库无 DC 集成脚本
--   md.* 无 lastupdatedttm 证据，时效用 __dictionary_id / __changeindex
--   ct_loc.lastupdatedttm 按 HIS cache 惯例；00 无此列则注释 04
--   _hoodie_commit_time：00 有列再解开文末 02 段；未证实不进主查询
--
-- 调度异常点（SQL 外核对）：
--   1) session hoodie_incremental_table_config='' = 关增量、读当前快照，不是「增量空结果」
--   2) 本任务必须在 visit_record DC/Hudi commit 之后；无依赖则永远吃旧快照
--   3) newest 恒='1'，不把旧行改 0；看数必须当天 max(rephour)，不要只 newest='1'
--   4) PK=(uuid,repdate,rephour) 且 uuid() 每次新值 → 追加分区；同小时重跑覆盖看引擎，不覆盖则像没变
--   5) 原 PySpark 是 insert_overwrite(repdate,rephour)；当前 DataX 无 truncate

SELECT
    "排查段",
    "优先级",
    "表名",
    "时效字段",
    "最新值",
    "延迟分钟",
    "延迟天",
    "行数",
    "distinct_计数",
    "判定"
FROM (
    -- 00 时效字段是否存在（md 不用 lastupdatedttm；hoodie/ct_loc 以本段为准）
    SELECT
        '00_字段存在性' AS "排查段",
        'P0' AS "优先级",
        table_schema || '.' || table_name AS "表名",
        column_name AS "时效字段",
        CAST(NULL AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        CAST(NULL AS bigint) AS "行数",
        CAST(NULL AS bigint) AS "distinct_计数",
        '有行=字段在当前 catalog 可见' AS "判定"
    FROM information_schema.columns
    WHERE lower(table_schema) IN (
            'datacenter_db',
            'md',
            'hid0123_cache_his_dhcapp_sqluser'
        )
      AND lower(table_name) IN (
            'visit_record',
            'dict_loc8',
            'tbl_1308_h',
            'tbl_1305_h',
            'tbl_1306_h',
            'tbl_1307_h',
            'mappingmember',
            'ct_loc'
        )
      AND lower(column_name) IN (
            'lastupdatedttm',
            'visit_record_lastupdatedttm',
            '_hoodie_commit_time',
            '__changeindex',
            '__dictionary_id',
            'datacreatedttm',
            'visit_record_datacreatedttm'
        )

    UNION ALL

    -- 01 P0 源表：在院口径 lastupdatedttm（决定业务字段变不变）
    SELECT
        '01_源表延迟_在院口径' AS "排查段",
        'P0' AS "优先级",
        'datacenter_db.visit_record' AS "表名",
        'visit_record_lastupdatedttm' AS "时效字段",
        CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar) AS "最新值",
        date_diff(
            'minute',
            try(CAST(MAX(vr.visit_record_lastupdatedttm) AS timestamp)),
            current_timestamp
        ) AS "延迟分钟",
        date_diff(
            'day',
            try(date_parse(substr(CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar), 1, 10), '%Y-%m-%d')),
            current_date
        ) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        CASE
            WHEN MAX(vr.visit_record_lastupdatedttm) IS NULL
              OR length(trim(CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar))) < 10
                THEN '字段空/格式异常'
            WHEN date_diff('minute', try(CAST(MAX(vr.visit_record_lastupdatedttm) AS timestamp)), current_timestamp) <= 30
                THEN '正常(<=30min)'
            WHEN date_diff('minute', try(CAST(MAX(vr.visit_record_lastupdatedttm) AS timestamp)), current_timestamp) <= 120
                THEN '预警(30-120min) 本任务可能吃到旧在院'
            ELSE '异常(>120min) 优先查 visit_record DC/Hudi 调度'
        END AS "判定"
    FROM datacenter_db.visit_record vr
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
      AND vr.visit_record_visitwardcode IS NOT NULL
      AND cast(vr.visit_record_visitrecordstatuscode AS varchar) = 'A'
      AND cast(vr.visit_record_visittypecode AS varchar) = 'I'

    UNION ALL

    -- 03 P0 全表 lastupdatedttm（对照：全表新、在院口径旧 = 出院/门诊在刷，在院行卡住）
    SELECT
        '03_源表延迟_全表对照' AS "排查段",
        'P0' AS "优先级",
        'datacenter_db.visit_record' AS "表名",
        'visit_record_lastupdatedttm' AS "时效字段",
        CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar) AS "最新值",
        date_diff(
            'minute',
            try(CAST(MAX(vr.visit_record_lastupdatedttm) AS timestamp)),
            current_timestamp
        ) AS "延迟分钟",
        date_diff(
            'day',
            try(date_parse(substr(CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar), 1, 10), '%Y-%m-%d')),
            current_date
        ) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        CASE
            WHEN date_diff('minute', try(CAST(MAX(vr.visit_record_lastupdatedttm) AS timestamp)), current_timestamp) <= 30
                THEN '全表新鲜；再对比01，01旧则在院子集未更新'
            ELSE '全表也旧 → DC 整表调度/增量停'
        END AS "判定"
    FROM datacenter_db.visit_record vr
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'

    UNION ALL

    -- 04 P1 HID0123/0124 拆院区，只影响 medorgcode 改写
    SELECT
        '04_拆院区_ct_loc' AS "排查段",
        'P1' AS "优先级",
        'hid0123_cache_his_dhcapp_sqluser.ct_loc' AS "表名",
        'lastupdatedttm' AS "时效字段",
        CAST(MAX(loc.lastupdatedttm) AS varchar) AS "最新值",
        date_diff('minute', try(CAST(MAX(loc.lastupdatedttm) AS timestamp)), current_timestamp) AS "延迟分钟",
        date_diff(
            'day',
            try(date_parse(substr(CAST(MAX(loc.lastupdatedttm) AS varchar), 1, 10), '%Y-%m-%d')),
            current_date
        ) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT loc.ctloc_rowid) AS "distinct_计数",
        CASE
            WHEN MAX(loc.lastupdatedttm) IS NULL THEN '无lastupdatedttm，看00'
            WHEN date_diff('day', try(date_parse(substr(CAST(MAX(loc.lastupdatedttm) AS varchar), 1, 10), '%Y-%m-%d')), current_date) > 1
                THEN '科室字典隔日未刷，仅HID0123/0124拆分可能错'
            ELSE '拆院区字典可用'
        END AS "判定"
    FROM hid0123_cache_his_dhcapp_sqluser.ct_loc loc
    WHERE coalesce(cast(loc.isdeleted AS varchar), '0') = '0'

    UNION ALL

    SELECT
        '05_字典_dict_loc8' AS "排查段",
        'P2' AS "优先级",
        'md.dict_loc8' AS "表名",
        '__dictionary_id/__changeindex' AS "时效字段",
        CAST(MAX(d."__dictionary_id") AS varchar) || '/' || CAST(MAX(d."__changeindex") AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT d.code) AS "distinct_计数",
        '无lastupdatedttm；版本号长期不变属字典常态，只影响HID0101院区名' AS "判定"
    FROM md.dict_loc8 d
    WHERE d."__dictionary_id" = (SELECT MAX(x."__dictionary_id") FROM md.dict_loc8 x)

    UNION ALL

    SELECT
        '06_字典_tbl_1308_h' AS "排查段",
        'P2' AS "优先级",
        'md.tbl_1308_h' AS "表名",
        'isdeleted(无lastupdatedttm证据)' AS "时效字段",
        CAST(NULL AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT h.hoscode) AS "distinct_计数",
        '非HID0101三级院区；行数骤降才查字典任务' AS "判定"
    FROM md.tbl_1308_h h
    WHERE coalesce(cast(h.isdeleted AS varchar), '0') = '0'

    UNION ALL

    SELECT
        '07_字典_mappingmember' AS "排查段",
        'P2' AS "优先级",
        'md.mappingmember' AS "表名",
        'isdeleted+dictionaryname' AS "时效字段",
        CAST(NULL AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT m.code) AS "distinct_计数",
        '运管院区映射；0行则三级院区全走默认YGF9997' AS "判定"
    FROM md.mappingmember m
    WHERE coalesce(cast(m.isdeleted AS varchar), '0') = '0'
      AND m.dictionaryname LIKE '%三级院区%'

    UNION ALL

    SELECT
        '08_字典_tbl_1305_h' AS "排查段",
        'P2' AS "优先级",
        'md.tbl_1305_h' AS "表名",
        '__dictionary_id' AS "时效字段",
        CAST(MAX(y."__dictionary_id") AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT y.code) AS "distinct_计数",
        '运管科室主数据' AS "判定"
    FROM md.tbl_1305_h y
    WHERE y."__dictionary_id" = (SELECT MAX(x."__dictionary_id") FROM md.tbl_1305_h x)
      AND coalesce(cast(y.isdeleted AS varchar), '0') = '0'

    UNION ALL

    SELECT
        '08_字典_tbl_1306_h' AS "排查段",
        'P2' AS "优先级",
        'md.tbl_1306_h' AS "表名",
        '__dictionary_id' AS "时效字段",
        CAST(MAX(y."__dictionary_id") AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT y.ctloc_code) AS "distinct_计数",
        '科室→运管科室；只影响omdept' AS "判定"
    FROM md.tbl_1306_h y
    WHERE y."__dictionary_id" = (SELECT MAX(x."__dictionary_id") FROM md.tbl_1306_h x)
      AND coalesce(cast(y.isdeleted AS varchar), '0') = '0'

    UNION ALL

    SELECT
        '08_字典_tbl_1307_h' AS "排查段",
        'P2' AS "优先级",
        'md.tbl_1307_h' AS "表名",
        '__dictionary_id' AS "时效字段",
        CAST(MAX(y."__dictionary_id") AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT y.code) AS "distinct_计数",
        '医生→运管科室优先于1306' AS "判定"
    FROM md.tbl_1307_h y
    WHERE y."__dictionary_id" = (SELECT MAX(x."__dictionary_id") FROM md.tbl_1307_h x)
      AND coalesce(cast(y.isdeleted AS varchar), '0') = '0'

    UNION ALL

    -- 10~13 量阶梯：哪条过滤把「有更新」滤没
    SELECT
        '10_量_全表未删' AS "排查段",
        'P0' AS "优先级",
        'datacenter_db.visit_record' AS "表名",
        'visit_record_lastupdatedttm' AS "时效字段",
        CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        '总量上限' AS "判定"
    FROM datacenter_db.visit_record vr
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'

    UNION ALL

    SELECT
        '11_量_+住院I' AS "排查段",
        'P0' AS "优先级",
        'datacenter_db.visit_record' AS "表名",
        'visit_record_lastupdatedttm' AS "时效字段",
        CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        '住院类型' AS "判定"
    FROM datacenter_db.visit_record vr
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
      AND cast(vr.visit_record_visittypecode AS varchar) = 'I'

    UNION ALL

    SELECT
        '12_量_+状态A' AS "排查段",
        'P0' AS "优先级",
        'datacenter_db.visit_record' AS "表名",
        'visit_record_lastupdatedttm' AS "时效字段",
        CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        '在院有效；出院未改A会虚高且名单冻住' AS "判定"
    FROM datacenter_db.visit_record vr
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
      AND cast(vr.visit_record_visittypecode AS varchar) = 'I'
      AND cast(vr.visit_record_visitrecordstatuscode AS varchar) = 'A'

    UNION ALL

    SELECT
        '13_量_主SQL在院口径' AS "排查段",
        'P0' AS "优先级",
        'datacenter_db.visit_record' AS "表名",
        'visit_record_lastupdatedttm' AS "时效字段",
        CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar) AS "最新值",
        date_diff('minute', try(CAST(MAX(vr.visit_record_lastupdatedttm) AS timestamp)), current_timestamp) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        '与DataX源一致；和上次快照人数接近则业务面像没变' AS "判定"
    FROM datacenter_db.visit_record vr
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
      AND vr.visit_record_visitwardcode IS NOT NULL
      AND cast(vr.visit_record_visitrecordstatuscode AS varchar) = 'A'
      AND cast(vr.visit_record_visittypecode AS varchar) = 'I'

    UNION ALL

    SELECT
        '14_量_主口径近1小时有更新' AS "排查段",
        'P0' AS "优先级",
        'datacenter_db.visit_record' AS "表名",
        'visit_record_lastupdatedttm>=now-1h' AS "时效字段",
        CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        CASE
            WHEN count(*) = 0 THEN '近1小时在院0更新 → 跑任务也是旧名单'
            ELSE '有增量；若SR仍旧，查写入/看数口径'
        END AS "判定"
    FROM datacenter_db.visit_record vr
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
      AND vr.visit_record_visitwardcode IS NOT NULL
      AND cast(vr.visit_record_visitrecordstatuscode AS varchar) = 'A'
      AND cast(vr.visit_record_visittypecode AS varchar) = 'I'
      AND try(CAST(vr.visit_record_lastupdatedttm AS timestamp)) >= date_add('hour', -1, current_timestamp)

    UNION ALL

    SELECT
        '15_量_主口径今日有更新' AS "排查段",
        'P0' AS "优先级",
        'datacenter_db.visit_record' AS "表名",
        'visit_record_lastupdatedttm当天' AS "时效字段",
        CAST(MAX(vr.visit_record_lastupdatedttm) AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        CASE
            WHEN count(*) = 0 THEN '今日在院0更新 → DC日调度未到或增量漏在院'
            ELSE '今日有更新行'
        END AS "判定"
    FROM datacenter_db.visit_record vr
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
      AND vr.visit_record_visitwardcode IS NOT NULL
      AND cast(vr.visit_record_visitrecordstatuscode AS varchar) = 'A'
      AND cast(vr.visit_record_visittypecode AS varchar) = 'I'
      AND substr(cast(vr.visit_record_lastupdatedttm AS varchar), 1, 10) = date_format(current_date, '%Y-%m-%d')

    UNION ALL

    -- HID0123 能拆出 0124 的行数（拆院区是否空转）
    SELECT
        '16_量_HID0123待拆' AS "排查段",
        'P1' AS "优先级",
        'visit_record+ct_loc' AS "表名",
        'ctloc_hospital_dr' AS "时效字段",
        CAST(NULL AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        'HID0123且科室能关联ct_loc'
    FROM datacenter_db.visit_record vr
    LEFT JOIN hid0123_cache_his_dhcapp_sqluser.ct_loc loc0123
        ON cast(vr.visit_record_medorgcode AS varchar) = 'HID0123'
       AND cast(loc0123.ctloc_rowid AS varchar) = cast(vr.visit_record_visitdeptid AS varchar)
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
      AND vr.visit_record_visitwardcode IS NOT NULL
      AND cast(vr.visit_record_visitrecordstatuscode AS varchar) = 'A'
      AND cast(vr.visit_record_visittypecode AS varchar) = 'I'
      AND cast(vr.visit_record_medorgcode AS varchar) = 'HID0123'

    UNION ALL

    SELECT
        '17_量_拆成HID0124' AS "排查段",
        'P1' AS "优先级",
        'visit_record+ct_loc' AS "表名",
        'ctloc_hospital_dr=12' AS "时效字段",
        CAST(NULL AS varchar) AS "最新值",
        CAST(NULL AS bigint) AS "延迟分钟",
        CAST(NULL AS bigint) AS "延迟天",
        count(*) AS "行数",
        count(DISTINCT vr.rowkey) AS "distinct_计数",
        CASE
            WHEN count(*) = 0 THEN '0124=0：ct_loc未关联或hospital_dr不是12'
            ELSE '拆院区生效'
        END AS "判定"
    FROM datacenter_db.visit_record vr
    LEFT JOIN hid0123_cache_his_dhcapp_sqluser.ct_loc loc0123
        ON cast(vr.visit_record_medorgcode AS varchar) = 'HID0123'
       AND cast(loc0123.ctloc_rowid AS varchar) = cast(vr.visit_record_visitdeptid AS varchar)
    WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
      AND vr.visit_record_visitwardcode IS NOT NULL
      AND cast(vr.visit_record_visitrecordstatuscode AS varchar) = 'A'
      AND cast(vr.visit_record_visittypecode AS varchar) = 'I'
      AND cast(vr.visit_record_medorgcode AS varchar) = 'HID0123'
      AND cast(loc0123.ctloc_hospital_dr AS varchar) = '12'
) t
ORDER BY "排查段";

-- ========== StarRocks m1.mdr_beinhosp（连 9030，不在 Presto）==========
-- SELECT
--   max(repdate) AS max_repdate,
--   max(rephour) AS max_rephour,
--   max(repdttm) AS max_repdttm,
--   max(datacreatedttm) AS max_datacreatedttm,
--   max(lastupdatedttm) AS max_src_lastupdatedttm,
--   count(*) AS cnt,
--   count(DISTINCT visitid) AS visit_cnt
-- FROM m1.mdr_beinhosp
-- WHERE repdate = date_format(now(), '%Y-%m-%d');
--
-- SELECT repdate, rephour, count(*) cnt, count(DISTINCT visitid) visits,
--        max(repdttm) max_repdttm, max(lastupdatedttm) max_src_upd
-- FROM m1.mdr_beinhosp
-- WHERE repdate >= date_format(date_sub(now(), INTERVAL 2 DAY), '%Y-%m-%d')
-- GROUP BY repdate, rephour
-- ORDER BY repdate DESC, rephour DESC;
--
-- 判读：
--   无今日新 rephour           → 任务未写入 / 看错表
--   有新 rephour 但 lastupdatedttm 停、visitid 与上小时一致 → 源 DC 延迟（A）
--   只按 newest='1' 看全历史   → 调度口径问题（newest 从未翻 0）
--
-- ========== 02 hoodie（仅当 00 出现 visit_record._hoodie_commit_time）==========
-- SELECT
--   '02_源表延迟_hoodie' AS "排查段", 'P0',
--   'datacenter_db.visit_record', '_hoodie_commit_time',
--   CAST(MAX(vr."_hoodie_commit_time") AS varchar),
--   CAST(NULL AS bigint), CAST(NULL AS bigint),
--   count(*), count(DISTINCT vr.rowkey),
--   '空增量session读的就是这个commit快照'
-- FROM datacenter_db.visit_record vr
-- WHERE coalesce(cast(vr.visit_record_isdeleted AS varchar), '0') = '0'
--   AND vr.visit_record_visitwardcode IS NOT NULL
--   AND cast(vr.visit_record_visitrecordstatuscode AS varchar) = 'A'
--   AND cast(vr.visit_record_visittypecode AS varchar) = 'I';
