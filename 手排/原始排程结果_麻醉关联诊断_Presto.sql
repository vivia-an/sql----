-- 原始排程 · 麻醉医生/助手为空 · 诊断 SQL（Presto/Trino）
-- 用途：判断是 OPMSSchedule 关联失败，还是源表 HocusDoc/HocusDocAss 本身无值
-- 时间窗：2019-08-01 ~ 2026-04-30

WITH p_range AS (
    SELECT
        '2019-08-01' AS dt_start,
        '2026-05-01' AS dt_end
),

base_apply AS (
    SELECT a.*
    FROM hid0101_cache_his_dhcapp_userssgl.OPMSApply a
    WHERE coalesce(a.isdeleted, '0') = '0'
      AND a.patname NOT LIKE '%测试%'
      AND substr(cast(a.opdate AS varchar), 1, 10) >= (SELECT dt_start FROM p_range)
      AND substr(cast(a.opdate AS varchar), 1, 10) <  (SELECT dt_end   FROM p_range)
      AND a.prostatus IN ('H', 'J', 'K', 'I', 'L')
)

-- ========== 1) 汇总：关联命中率 vs 麻醉字段有值率 ==========
SELECT
    '1_汇总' AS "诊断项",
    count(*) AS "申请总数",
    count(s_old.oproomid) AS "旧关联命中数_oproomid",
    count(nullif(trim(s_old.HocusDoc), '')) AS "旧关联有麻醉医生",
    count(nullif(trim(s_old.HocusDocAss), '')) AS "旧关联有麻醉助手",
    count(s_new.oproomid) AS "新关联命中数_coalesce+日期",
    count(nullif(trim(s_new.HocusDoc), '')) AS "新关联有麻醉医生",
    count(nullif(trim(s_new.HocusDocAss), '')) AS "新关联有麻醉助手",
    count(CASE WHEN a.oproomid IS NULL OR trim(cast(a.oproomid AS varchar)) = '' THEN 1 END) AS "oproomid为空",
    count(CASE WHEN a.OpRoomID IS NULL OR trim(cast(a.OpRoomID AS varchar)) = '' THEN 1 END) AS "OpRoomID为空",
    count(
        CASE
            WHEN coalesce(cast(a.oproomid AS varchar), '') != coalesce(cast(a.OpRoomID AS varchar), '')
            THEN 1
        END
    ) AS "oproomid与OpRoomID不一致"
FROM base_apply a
LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSSchedule s_old
    ON s_old.oproomid = a.oproomid
   AND s_old.useingdate = a.opdate
LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSSchedule s_new
    ON cast(s_new.oproomid AS varchar) = cast(coalesce(a.oproomid, a.OpRoomID) AS varchar)
   AND substr(cast(s_new.useingdate AS varchar), 1, 10) = substr(cast(a.opdate AS varchar), 1, 10);

-- ========== 2) 抽样：旧关联未命中、新关联命中的样例（单独执行本段） ==========
/*
SELECT
    substr(cast(a.opdate AS varchar), 1, 10) AS "排程日期",
    a.OPNo AS "手术单号",
    cast(a.oproomid AS varchar) AS "oproomid",
    cast(a.OpRoomID AS varchar) AS "OpRoomID",
    room.RoomName AS "手术间",
    s_old.HocusDoc AS "旧_麻醉医生",
    s_new.HocusDoc AS "新_麻醉医生",
    s_old.HocusDocAss AS "旧_麻醉助手",
    s_new.HocusDocAss AS "新_麻醉助手"
FROM base_apply a
LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSRoomManage room
    ON a.OpRoomID = room.opms_rowid
LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSSchedule s_old
    ON s_old.oproomid = a.oproomid
   AND s_old.useingdate = a.opdate
LEFT JOIN hid0101_cache_his_dhcapp_userssgl.OPMSSchedule s_new
    ON cast(s_new.oproomid AS varchar) = cast(coalesce(a.oproomid, a.OpRoomID) AS varchar)
   AND substr(cast(s_new.useingdate AS varchar), 1, 10) = substr(cast(a.opdate AS varchar), 1, 10)
WHERE s_old.oproomid IS NULL
  AND s_new.oproomid IS NOT NULL
LIMIT 50;
*/

-- ========== 3) OPMSSchedule 源表本身是否有麻醉医护（单独执行本段） ==========
/*
SELECT
    count(*) AS "排班记录总数",
    count(nullif(trim(HocusDoc), '')) AS "有麻醉医生",
    count(nullif(trim(HocusDocAss), '')) AS "有麻醉助手",
    count(nullif(trim(HandNurse1), '')) AS "有洗手护士1",
    count(nullif(trim(ItinerantNurse1), '')) AS "有巡回护士1"
FROM hid0101_cache_his_dhcapp_userssgl.OPMSSchedule
WHERE substr(cast(useingdate AS varchar), 1, 10) >= '2019-08-01'
  AND substr(cast(useingdate AS varchar), 1, 10) <  '2026-05-01';
*/

-- ========== 4) Plan_OPSSchedule 层麻醉字段填充率（单独执行本段） ==========
/*
SELECT
    count(*) AS "排程总数",
    count(nullif(trim("Plan_OPSSchedule_NarcosisDoctName"), '')) AS "有麻醉医生",
    count(nullif(trim("Plan_OPSSchedule_NarcosisAssistantName"), '')) AS "有麻醉助手",
    count(nullif(trim("Plan_OPSSchedule_ScrubNursName"), '')) AS "有洗手护士",
    count(nullif(trim("Plan_OPSSchedule_CruiseNursName"), '')) AS "有巡回护士"
FROM datacenter_db."Plan_OPSSchedule"
WHERE "Plan_OPSSchedule_IsDeleted" = '0'
  AND substr("Plan_OPSSchedule_OPSPlanBeginDtTm", 1, 10) >= '2019-08-01'
  AND substr("Plan_OPSSchedule_OPSPlanBeginDtTm", 1, 10) <  '2026-05-01';
*/

-- 判读：
-- · 旧关联命中低、新关联命中高 → 关联键问题（oproomid/日期格式）
-- · 新旧都命中低 → OPMSSchedule 与申请单键对不上
-- · 关联命中高但 HocusDoc 仍为 0 → 源表未维护麻醉医护
-- · OPMS 有值、Plan_OPSSchedule 无值 → DC 入仓未映射麻醉字段
