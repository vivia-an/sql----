-- 原始排程结果明细（DC 层备选）
-- 血缘：Datacenter/datacenter Plan_OPSSchedule + HIS/术前讨论计划手术一致率指标（按月统计）.sql
-- 适用：环境可直接查 datacenter_db，不依赖 OPMS cache 表时
-- 时间窗：2019-08-01 ~ 2026-04-30

WITH p_range AS (
    SELECT
        '2019-08-01' AS dt_start,
        '2026-05-01' AS dt_end
)

SELECT
    substr(p."Plan_OPSSchedule_OPSPlanBeginDtTm", 1, 10) AS "排程日期",
    p."Plan_OPSSchedule_OPSRoomName"                     AS "手术间",
    p."Plan_OPSSchedule_OPSSeqNo"                        AS "台次",
    row_number() OVER (
        PARTITION BY
            substr(p."Plan_OPSSchedule_OPSPlanBeginDtTm", 1, 10),
            p."Plan_OPSSchedule_OPSRoomName"
        ORDER BY
            p."Plan_OPSSchedule_OPSPlanBeginDtTm",
            p."Plan_OPSSchedule_OPSSeqNo",
            p."Plan_OPSSchedule_OPSScheduleID"
    )                                                    AS "序号",
    p."Plan_OPSSchedule_OPSPlanBeginDtTm"                AS "时间",
    p."Plan_OPSSchedule_VisitNo"                         AS "住院号",
    p."Plan_OPSSchedule_ApplyDeptName"                   AS "申请科室",
    p."Plan_OPSSchedule_PersName"                        AS "姓名",
    cast(p."Plan_OPSSchedule_CurrentAge" AS varchar)     AS "年龄",
    p."Plan_OPSSchedule_OperateDoctName"                 AS "主刀医生",
    p."Plan_OPSSchedule_NarcosisDoctName"                AS "麻醉医生",
    p."Plan_OPSSchedule_NarcosisModeName"                AS "麻醉方式",
    p."Plan_OPSSchedule_OPSName"                         AS "手术名称",
    p."Plan_OPSSchedule_FirstAssistant"                  AS "一助",
    p."Plan_OPSSchedule_SecondAssistant"                 AS "二助",
    p."Plan_OPSSchedule_ThirdAssistant"                  AS "三助",
    p."Plan_OPSSchedule_FourthOPS"                       AS "其他助手",
    p."Plan_OPSSchedule_ScrubNursName"                   AS "洗手护士",
    p."Plan_OPSSchedule_CruiseNursName"                  AS "巡回护士",
    p."Plan_OPSSchedule_NarcosisAssistantName"           AS "麻醉助手",
    p."Plan_OPSSchedule_OPSScheduleID"                     AS "手术排程ID"
FROM datacenter_db."Plan_OPSSchedule" p
WHERE p."Plan_OPSSchedule_IsDeleted" = '0'
  AND p."Plan_OPSSchedule_OPSPlanBeginDtTm" IS NOT NULL
  AND p."Plan_OPSSchedule_OPSPlanBeginDtTm" != ''
  AND substr(p."Plan_OPSSchedule_OPSPlanBeginDtTm", 1, 10) >= (SELECT dt_start FROM p_range)
  AND substr(p."Plan_OPSSchedule_OPSPlanBeginDtTm", 1, 10) <  (SELECT dt_end   FROM p_range)
ORDER BY
    "排程日期",
    "手术间",
    "序号";
