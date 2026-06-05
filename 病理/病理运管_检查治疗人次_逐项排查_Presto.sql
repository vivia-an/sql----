-- =============================================================================
-- 仅「检查治疗人次/项次」指标 — 与 DataX 任务 main_count / sj_count / tf_count 对齐，分步排查
-- 血缘：hid0101_mssql_bl_rep.t_jcxx（主院区+锦江、上锦）| hid0117_mysql_bl_pis.pathology（天府）
-- 用法：按「步骤」整段复制到 Presto 执行；先改 ds.biz_date（= 调度 ${yyyymmdd}）再跑步骤 1～3
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 步骤 0：确认「业务日」对应的统计月与时间窗（与 DataX month_range 一致）
-- 说明：传入 2 月任意一天 → month_label 为 1 月；统计的是「上一自然月」整月
-- -----------------------------------------------------------------------------
/*
WITH ds AS (
  SELECT CAST(date_parse('2026-02-10', '%Y-%m-%d') AS DATE) AS biz_date   -- 改成实际调度传入的 yyyymmdd
),
month_range AS (
  SELECT
    date_format(date_add('month', -1, (SELECT biz_date FROM ds)), '%Y-%m') AS month_label,
    date_format(date_trunc('month', date_add('month', -1, (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 00:00:00' AS start_date,
    date_format(date_add('day', -1, date_trunc('month', (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 23:59:59' AS end_date
)
SELECT * FROM month_range;
*/

-- -----------------------------------------------------------------------------
-- 步骤 1：主院区 + 锦江 — t_jcxx（与任务 main_count 同条件，按「时间窗」）
-- 若与「步骤 1b」数字不一致 → 重点查 f_sdrq 字符串与 start_date/end_date 比较
-- -----------------------------------------------------------------------------
WITH ds AS (
  SELECT CAST(date_parse('2026-02-10', '%Y-%m-%d') AS DATE) AS biz_date
),
month_range AS (
  SELECT
    date_format(date_add('month', -1, (SELECT biz_date FROM ds)), '%Y-%m') AS month_label,
    date_format(date_trunc('month', date_add('month', -1, (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 00:00:00' AS start_date,
    date_format(date_add('day', -1, date_trunc('month', (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 23:59:59' AS end_date
)
SELECT
  '主院区+锦江_检查治疗人次(时间窗)' AS step_name,
  (SELECT month_label FROM month_range) AS stat_month,
  COUNT(1) AS cnt
FROM hid0101_mssql_bl_rep.t_jcxx, month_range
WHERE f_blk IN (
  '普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规',
  '锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规'
)
  AND f_bgzt = '已审核'
  AND f_sdrq >= (SELECT start_date FROM month_range)
  AND f_sdrq <= (SELECT end_date FROM month_range)
  AND isdeleted = '0';

-- 步骤 1b：同上口径，但按「自然月 substr」计数（与步骤 1 对照）
/*
WITH ds AS (SELECT CAST(date_parse('2026-02-10', '%Y-%m-%d') AS DATE) AS biz_date),
month_range AS (
  SELECT date_format(date_add('month', -1, (SELECT biz_date FROM ds)), '%Y-%m') AS month_label
)
SELECT
  '主院区+锦江_检查治疗人次(substr月)' AS step_name,
  (SELECT month_label FROM month_range) AS stat_month,
  COUNT(1) AS cnt
FROM hid0101_mssql_bl_rep.t_jcxx
WHERE isdeleted = '0'
  AND f_bgzt = '已审核'
  AND f_blk IN (
    '普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规',
    '锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规'
  )
  AND SUBSTRING(CAST(f_sdrq AS VARCHAR), 1, 7) = (SELECT month_label FROM month_range);
*/

-- -----------------------------------------------------------------------------
-- 步骤 2：上锦院区 — t_jcxx（与任务 sj_count 同条件）【整段复制单独执行】
-- -----------------------------------------------------------------------------
/*
WITH ds AS (
  SELECT CAST(date_parse('2026-02-10', '%Y-%m-%d') AS DATE) AS biz_date
),
month_range AS (
  SELECT
    date_format(date_add('month', -1, (SELECT biz_date FROM ds)), '%Y-%m') AS month_label,
    date_format(date_trunc('month', date_add('month', -1, (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 00:00:00' AS start_date,
    date_format(date_add('day', -1, date_trunc('month', (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 23:59:59' AS end_date
)
SELECT
  '上锦_检查治疗人次(时间窗)' AS step_name,
  (SELECT month_label FROM month_range) AS stat_month,
  COUNT(1) AS cnt
FROM hid0101_mssql_bl_rep.t_jcxx, month_range
WHERE f_blk IN (
  '上锦普通外检','上锦加快','上锦冰冻','上锦术后石蜡','上锦尸解','上锦细胞学','上锦细针','上锦体检','上锦外院会诊','上锦肝穿','上锦肾穿','上锦骨髓','上锦淋巴结','上锦眼科','上锦肌肉','上锦前列腺','上锦ESD','上锦电镜','上锦心肌','上锦普通会诊加急','上锦普通会诊常规'
)
  AND f_bgzt = '已审核'
  AND f_sdrq >= (SELECT start_date FROM month_range)
  AND f_sdrq <= (SELECT end_date FROM month_range)
  AND isdeleted = '0';
*/

-- -----------------------------------------------------------------------------
-- 步骤 3：天府院区 — pathology（与任务 tf_count 同条件）【整段复制单独执行】
-- -----------------------------------------------------------------------------
/*
WITH ds AS (
  SELECT CAST(date_parse('2026-02-10', '%Y-%m-%d') AS DATE) AS biz_date
),
month_range AS (
  SELECT
    date_format(date_add('month', -1, (SELECT biz_date FROM ds)), '%Y-%m') AS month_label,
    date_format(date_trunc('month', date_add('month', -1, (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 00:00:00' AS start_date,
    date_format(date_add('day', -1, date_trunc('month', (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 23:59:59' AS end_date
)
SELECT
  '天府_检查治疗人次' AS step_name,
  (SELECT month_label FROM month_range) AS stat_month,
  COUNT(1) AS cnt
FROM hid0117_mysql_bl_pis.pathology, month_range
WHERE deleted_at IS NULL
  AND library_id NOT IN ('39', '40', '41', '60', '67', '68', '69', '77', '18')
  AND receive_at >= (SELECT start_date FROM month_range)
  AND receive_at <= (SELECT end_date FROM month_range);
*/

-- -----------------------------------------------------------------------------
-- 步骤 4：主院区 t_jcxx — 按日拆开（看是否某几天为 0 或异常低）
-- 将 month_label 换成步骤 0 查出的月份，或改 ds 后改用下面子查询中的月
-- -----------------------------------------------------------------------------
/*
WITH ds AS (SELECT CAST(date_parse('2026-02-10', '%Y-%m-%d') AS DATE) AS biz_date),
mr AS (
  SELECT date_format(date_add('month', -1, (SELECT biz_date FROM ds)), '%Y-%m') AS ym
)
SELECT
  SUBSTRING(CAST(f_sdrq AS VARCHAR), 1, 10) AS sdrq_day,
  COUNT(1) AS daily_cnt
FROM hid0101_mssql_bl_rep.t_jcxx
WHERE isdeleted = '0'
  AND f_bgzt = '已审核'
  AND f_blk IN (
    '普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规',
    '锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规'
  )
  AND SUBSTRING(CAST(f_sdrq AS VARCHAR), 1, 7) = (SELECT ym FROM mr)
GROUP BY 1
ORDER BY 1;
*/

-- -----------------------------------------------------------------------------
-- 步骤 5：过滤条件敏感度 — 主院区同月，分别看「仅删 isdeleted」「仅删 f_bgzt」差多少
-- -----------------------------------------------------------------------------
/*
WITH ds AS (SELECT CAST(date_parse('2026-02-10', '%Y-%m-%d') AS DATE) AS biz_date),
mr AS (
  SELECT date_format(date_add('month', -1, (SELECT biz_date FROM ds)), '%Y-%m') AS ym
)
SELECT 'all_rows' AS layer, COUNT(1) AS cnt
FROM hid0101_mssql_bl_rep.t_jcxx
WHERE SUBSTRING(CAST(f_sdrq AS VARCHAR), 1, 7) = (SELECT ym FROM mr)
  AND f_blk IN ('普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规','锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规')
UNION ALL
SELECT 'isdeleted_0', COUNT(1)
FROM hid0101_mssql_bl_rep.t_jcxx
WHERE SUBSTRING(CAST(f_sdrq AS VARCHAR), 1, 7) = (SELECT ym FROM mr)
  AND isdeleted = '0'
  AND f_blk IN ('普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规','锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规')
UNION ALL
SELECT 'isdeleted_0_and_已审核', COUNT(1)
FROM hid0101_mssql_bl_rep.t_jcxx
WHERE SUBSTRING(CAST(f_sdrq AS VARCHAR), 1, 7) = (SELECT ym FROM mr)
  AND isdeleted = '0'
  AND f_bgzt = '已审核'
  AND f_blk IN ('普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规','锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规');
*/

-- -----------------------------------------------------------------------------
-- 步骤 6：一行汇总 — 与报表「检查治疗人次」三行（主院区/上锦/天府）对照用
-- 注意：报表里「主院区」块的人次是 main_count；「上锦」「天府」各自独立；合计行是另一段 SQL
-- -----------------------------------------------------------------------------
/*
WITH ds AS (SELECT CAST(date_parse('2026-02-10', '%Y-%m-%d') AS DATE) AS biz_date),
month_range AS (
  SELECT
    date_format(date_add('month', -1, (SELECT biz_date FROM ds)), '%Y-%m') AS month_label,
    date_format(date_trunc('month', date_add('month', -1, (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 00:00:00' AS start_date,
    date_format(date_add('day', -1, date_trunc('month', (SELECT biz_date FROM ds))), '%Y-%m-%d') || ' 23:59:59' AS end_date
)
SELECT '主院区' AS unit, '检查治疗人次/项次' AS item, COUNT(1) AS cnt
FROM hid0101_mssql_bl_rep.t_jcxx, month_range
WHERE f_blk IN (
  '普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规',
  '锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规'
)
  AND f_bgzt = '已审核' AND f_sdrq >= (SELECT start_date FROM month_range) AND f_sdrq <= (SELECT end_date FROM month_range) AND isdeleted = '0'
UNION ALL
SELECT '上锦院区', '检查治疗人次/项次', COUNT(1)
FROM hid0101_mssql_bl_rep.t_jcxx, month_range
WHERE f_blk IN (
  '上锦普通外检','上锦加快','上锦冰冻','上锦术后石蜡','上锦尸解','上锦细胞学','上锦细针','上锦体检','上锦外院会诊','上锦肝穿','上锦肾穿','上锦骨髓','上锦淋巴结','上锦眼科','上锦肌肉','上锦前列腺','上锦ESD','上锦电镜','上锦心肌','上锦普通会诊加急','上锦普通会诊常规'
)
  AND f_bgzt = '已审核' AND f_sdrq >= (SELECT start_date FROM month_range) AND f_sdrq <= (SELECT end_date FROM month_range) AND isdeleted = '0'
UNION ALL
SELECT '天府院区', '检查治疗人次/项次', COUNT(1)
FROM hid0117_mysql_bl_pis.pathology, month_range
WHERE deleted_at IS NULL
  AND library_id NOT IN ('39', '40', '41', '60', '67', '68', '69', '77', '18')
  AND receive_at >= (SELECT start_date FROM month_range)
  AND receive_at <= (SELECT end_date FROM month_range);
*/
