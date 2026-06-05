-- =============================================================================
-- 需求：统计指定年度 1、2、3 月 ——「手术并发症例数」「择期手术例数」（按月一行）
-- =============================================================================
-- 【IRIS / Caché】hxbi.mr_ops；勿在 Presto 执行。
-- 【时间】按出院日期 MROPS_FOutDate 所在自然月统计（改年度请改 WHERE 中字面量）。
-- 【并发症】ZPack.testWyl5_BFZFLAG(MROPS_PAADMDR)=1 视为有并发症（若现场为 0/非零，请改 CASE）。
-- 【择期】COALESCE(MROPS_SurgType,'') NOT LIKE '%急诊%' 视为择期（与手麻 is_emergency 口径不同，需业务确认）。
-- 【与手麻一致】请用 Presto：《手麻_1至3月_并发症例数与择期例数_Presto.sql》（入室月+sam_reg_op）。
-- 【语法】IRIS 对 EXTRACT(MONTH FROM x) 常报 bad SQL grammar；请用 MONTH(x)。中文别名建议双引号。
-- 【JDBC】若工具自动加 SELECT TOP 100 且仍报错，用下面「子查询」版本或关闭 TOP。
-- =============================================================================

-- ---------- 主查询：1～3 月两指标（先跑这个）----------
SELECT
  MONTH(MROPS_FOutDate) AS "月份",
  COUNT(DISTINCT CASE WHEN ZPack.testWyl5_BFZFLAG(MROPS_PAADMDR) = 1 THEN MROPS_PAADMDR END) AS "手术并发症例数",
  COUNT(DISTINCT CASE
    WHEN COALESCE(MROPS_SurgType, '') NOT LIKE '%急诊%'
    THEN MROPS_PAADMDR
  END) AS "择期手术例数"
FROM hxbi.mr_ops
WHERE MROPS_MRBaseID->MRB_CheckItem2 = '医院'
  AND MROPS_FOutDate >= '2026-01-01'
  AND MROPS_FOutDate <= '2026-03-31 23:59:59'
GROUP BY MONTH(MROPS_FOutDate)
ORDER BY MONTH(MROPS_FOutDate)
;

-- ---------- 若 Spring/JDBC 强行 TOP 100 导致语法错误，改用子查询包一层 ----------
/*
SELECT TOP 100
  mth AS "月份",
  bfz_cnt AS "手术并发症例数",
  ele_cnt AS "择期手术例数"
FROM (
  SELECT
    MONTH(MROPS_FOutDate) AS mth,
    COUNT(DISTINCT CASE WHEN ZPack.testWyl5_BFZFLAG(MROPS_PAADMDR) = 1 THEN MROPS_PAADMDR END) AS bfz_cnt,
    COUNT(DISTINCT CASE
      WHEN COALESCE(MROPS_SurgType, '') NOT LIKE '%急诊%'
      THEN MROPS_PAADMDR
    END) AS ele_cnt
  FROM hxbi.mr_ops
  WHERE MROPS_MRBaseID->MRB_CheckItem2 = '医院'
    AND MROPS_FOutDate >= '2026-01-01'
    AND MROPS_FOutDate <= '2026-03-31 23:59:59'
  GROUP BY MONTH(MROPS_FOutDate)
) x
ORDER BY mth
*/

-- ---------- 可选：同条件明细（需下钻时取消注释；与上面勿同时执行）----------
/*
SELECT
  MROPS_PAADMDR AS 患者ADM,
  MROPS_PAPMINO AS 登记号,
  MROPS_PADMNO AS 病案号,
  MROPS_MRBaseID->MRB_PAName AS 姓名,
  MROPS_MRBaseID->MRB_PANationDesc AS 民族,
  MROPS_MRBaseID->MRB_PASexDR->DicG_BDesc AS 性别,
  MROPS_MRBaseID->MRB_PAAgeYear AS 年龄,
  MROPS_MRBaseID->MRB_PADInDate AS 入院时期,
  MROPS_FOutDate AS 出院日期,
  MROPS_MRBaseID->MRB_PAInLocDesc AS 入院科室,
  MROPS_MRBaseID->MRB_PAOutLocDesc AS 出院科室,
  MROPS_MainOPSFlag AS 主手术标志,
  MROPS_OPFirstCode AS 手术编码,
  MROPS_OPFirstName AS 手术名称,
  MROPS_AssistantFirst AS 手术一助,
  MROPS_AssistantSecond AS 手术二助,
  MROPS_OPDocDesc AS 手术医师,
  MROPS_NarcosisDocName AS 麻醉医师,
  MROPS_SurgType AS 手术类型,
  MROPS_NarcosisName AS 麻醉方式名称,
  MROPS_OPSDate AS 手术日期,
  ZPack."testLR_GetBaseDiagData"(MROPS_PAADMDR) AS 编目所有诊断与编码拼接,
  ZPack."testLR_GetFPDiag"(MROPS_PAADMDR) AS 首页所有诊断,
  ZPack."testLR_WYLGetOpsFromAdmv2"(MROPS_PAADMDR) AS 编目所有手术名称与编码拼接,
  ZPack."testLR_GetFPOPS"(MROPS_PAADMDR) AS 首页所有手术名称,
  ZPack."yhwork_GetFPSX"(MROPS_PAADMDR) AS 输血拼接,
  ZPack."testLR_GetFPLYFS"(MROPS_PAADMDR) AS 首页离院方式,
  MROPS_MRBaseID->MRB_PAOutHealDR AS 出院情况为4代表死亡,
  ZPack.testWyl5_BFZFLAG(MROPS_PAADMDR) AS 并发症
FROM hxbi.mr_ops
WHERE MROPS_MRBaseID->MRB_CheckItem2 = '医院'
  AND MROPS_FOutDate >= '2026-01-01'
  AND MROPS_FOutDate <= '2026-03-31 23:59:59'
;
*/
