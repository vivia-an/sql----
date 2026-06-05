-- 用途：对比「上一自然月」统计口径下，DataX 病理运管任务各源表在 2026-01 vs 2026-02 的量级差异，定位哪张表导致「检查治疗人次」等与预期不符
-- 血缘：对齐 starrocks-hid0101_mssql_hxcs_hxcsrep.biz_exam 中 querySql 的表与主要 WHERE
-- 说明：以下为「按月」对比；若任务用 ${yyyymmdd} 非月初，请以 month_range 与线上一致为准单独跑 ds CTE
--
-- 解读指南：
--   • 人次/项次 仅依赖 t_jcxx（主院区 f_blk 列表 vs 上锦 f_blk 列表）→ 若仅「人次」异常，优先看 t_jcxx 两月行数比
--   • 收入类 依赖 mdr_income / mdr_peisincome → 与「人次」解耦；人次低但收入高 = 口径不同或表不同步
--   • inventory_del_dets 仅影响「领用材料试剂费」，不影响人次
--   • 天府 pathology 仅影响天府院区人次
--
-- ========= 附录：本脚本涉及的「多机构/院区」字典（血缘对照用）=========
-- 1) t_jcxx（hid0101_mssql_bl_rep）同一物理表内用 f_blk 前缀区分单位（非 medorgcode）：
--    • 主院区口径：f_blk 为「普通外检、加快、冰冻…」等无「锦江/上锦」前缀；
--    • 锦江：f_blk 以「锦江」开头；
--    • 上锦：f_blk 以「上锦」开头。
-- 2) mdr_income（m1）病理相关收入：按接收科室名字段区分院区/执业点（示例值见正文 WHERE）：
--    「病理科」本部、「锦江病理科」「温江病理科」「天府病理科」。
-- 3) mdr_peisincome 体检病理（可选注释块）：medorgcode 白名单 —— 含「其他医院/体检点」集成编码：
--      HID0101  四川大学华西医院（主数据 md.dim_hospitals 附录示例）
--      HID0118  武侯体检中心
--      F0017    仓库未展开中文名，请以 mdm / md.dim_hospitals 或 SELECT DISTINCT medorgcode FROM m1.mdr_peisincome 实查为准
--      F0002    仓库未展开；院区维度可参考 md.dim_hosp_areas「YGF0002 温江院区」（medorg 与院区编码体系可能不同，禁止混用）
-- 4) pathology（天府人次）：hid0117_mysql_bl_pis.pathology ↔ 集成前缀 hid0117（华西天府医院，见 dim_hospitals HID0117）

WITH
-- 固定对比两个月（按需改年月）
m AS (
    SELECT '2026-01' AS ym, '2026-01-01 00:00:00' AS start_dt, '2026-01-31 23:59:59' AS end_dt
    UNION ALL
    SELECT '2026-02', '2026-02-01 00:00:00', '2026-02-28 23:59:59'
),
-- ---------- 1) 检查治疗人次源表：t_jcxx（主院区口径）----------
main_jcxx AS (
    SELECT
        SUBSTRING(CAST(t.f_sdrq AS VARCHAR), 1, 7) AS ym,
        COUNT(1) AS cnt
    FROM hid0101_mssql_bl_rep.t_jcxx t
    WHERE t.isdeleted = '0'
      AND t.f_bgzt = '已审核'
      AND t.f_blk IN (
        '普通外检','加快','冰冻','术后石蜡','尸解','细胞学','细针','体检','外院会诊','肝穿','肾穿','骨髓','淋巴结','眼科','肌肉','前列腺','ESD','电镜','心肌','普通会诊加急','普通会诊常规',
        '锦江普通外检','锦江加快','锦江冰冻','锦江术后石蜡','锦江尸解','锦江细胞学','锦江细针','锦江体检','锦江外院会诊','锦江肝穿','锦江肾穿','锦江骨髓','锦江淋巴结','锦江眼科','锦江肌肉','锦江前列腺','锦江ESD','锦江电镜','锦江心肌','锦江普通会诊加急','锦江普通会诊常规'
      )
      AND SUBSTRING(CAST(t.f_sdrq AS VARCHAR), 1, 7) IN ('2026-01', '2026-02')
    GROUP BY 1
),
-- ---------- 2) 上锦：同表不同 f_blk ----------
sj_jcxx AS (
    SELECT
        SUBSTRING(CAST(t.f_sdrq AS VARCHAR), 1, 7) AS ym,
        COUNT(1) AS cnt
    FROM hid0101_mssql_bl_rep.t_jcxx t
    WHERE t.isdeleted = '0'
      AND t.f_bgzt = '已审核'
      AND t.f_blk IN (
        '上锦普通外检','上锦加快','上锦冰冻','上锦术后石蜡','上锦尸解','上锦细胞学','上锦细针','上锦体检','上锦外院会诊','上锦肝穿','上锦肾穿','上锦骨髓','上锦淋巴结','上锦眼科','上锦肌肉','上锦前列腺','上锦ESD','上锦电镜','上锦心肌','上锦普通会诊加急','上锦普通会诊常规'
      )
      AND SUBSTRING(CAST(t.f_sdrq AS VARCHAR), 1, 7) IN ('2026-01', '2026-02')
    GROUP BY 1
),
-- ---------- 3) 病理收入（主院区多科室）----------
inc_main AS (
    SELECT SUBSTRING(chargedttm, 1, 7) AS ym, COUNT(1) AS row_cnt, SUM(TotalFee) AS sum_fee
    FROM m1.mdr_income
    WHERE RecDeptName IN ('病理科','锦江病理科','温江病理科','天府病理科')
      AND SUBSTRING(chargedttm, 1, 7) IN ('2026-01', '2026-02')
    GROUP BY 1
),
-- ---------- 4) 穿刺收入子集（行数参考）----------
inc_puncture AS (
    SELECT SUBSTRING(chargedttm, 1, 7) AS ym, COUNT(1) AS row_cnt, SUM(TotalFee) AS sum_fee
    FROM m1.mdr_income
    WHERE RecDeptName IN ('穿刺诊疗中心', '锦江穿刺诊疗中心')
      AND OrderName IN (
        '淋巴结细针穿刺检查','皮下包块细针穿刺检查','乳腺肿物穿刺活检术(细针)',
        '脱落细胞学检查与诊断(涂片)','细针穿刺细胞学检查与诊断(细胞块)','细针穿刺细胞学检查与诊断(涂片)'
      )
      AND SUBSTRING(chargedttm, 1, 7) IN ('2026-01', '2026-02')
    GROUP BY 1
),
-- ---------- 5) 天府 pathology 人次相关 ----------
tf_path AS (
    SELECT
        SUBSTRING(CAST(receive_at AS VARCHAR), 1, 7) AS ym,
        COUNT(1) AS cnt
    FROM hid0117_mysql_bl_pis.pathology
    WHERE deleted_at IS NULL
      AND library_id NOT IN ('39', '40', '41', '60', '67', '68', '69', '77', '18')
      AND SUBSTRING(CAST(receive_at AS VARCHAR), 1, 7) IN ('2026-01', '2026-02')
    GROUP BY 1
)
SELECT 't_jcxx_主院区+锦江类型' AS src_table, ym, CAST(cnt AS VARCHAR) AS metric_value, 'count' AS metric_type
FROM main_jcxx
UNION ALL
SELECT 't_jcxx_上锦类型', ym, CAST(cnt AS VARCHAR), 'count' FROM sj_jcxx
UNION ALL
SELECT 'mdr_income_病理科等', ym, CAST(row_cnt AS VARCHAR) || ' | sum=' || CAST(COALESCE(sum_fee, 0) AS VARCHAR), 'rows|sum' FROM inc_main
UNION ALL
SELECT 'mdr_income_穿刺子集', ym, CAST(row_cnt AS VARCHAR) || ' | sum=' || CAST(COALESCE(sum_fee, 0) AS VARCHAR), 'rows|sum' FROM inc_puncture
UNION ALL
SELECT 'pathology_天府', ym, CAST(cnt AS VARCHAR), 'count' FROM tf_path
ORDER BY src_table, ym;

/*
======== 可选：体检 mdr_peisincome 行数（与任务 examfeeitem 条件一致，仅行量对比）========
SELECT SUBSTRING(dateregister, 1, 7) AS ym, COUNT(1) AS cnt
FROM m1.mdr_peisincome
WHERE f_feecharged IN ('AQ==','true','1')
  AND (f_regreturned = 'false' OR f_regreturned = 'AA==' OR f_regreturned IS NULL)
  AND f_registered IN ('AQ==','true','ARRIVED')
  AND examfeeitem_name IN (
    '宫颈刮片病理细胞学检查','宫颈刮片病理细胞学检查【HPV】','液基薄层细胞学检查',
    '液基薄层细胞学检查【加HPV】','尿液基细胞学检测','液基薄层细胞制片术',
    '肠癌无创脱落细胞多靶点基因检测','液基薄层细胞学检查【加HPV，加白带常规】',
    '两癌筛查【HPV+白带】','两癌筛查液基薄层细胞制片术','两癌筛查组织病理学检查',
    '两癌筛查妇科','两癌筛查妇科【HPV+白带】','两癌筛查妇科【液基】',
    '两癌筛查组织病理学检查【需取组织检查才用条码】','液基薄层细胞学检查【加白带常规】',
    '体检液基薄层细胞制片术','液基薄层细胞制片术','液基薄层细胞学检查（HPV）（体检）'
  )
  AND medorgcode IN ('HID0101','HID0118','F0017','F0002')
  AND SUBSTRING(dateregister, 1, 7) IN ('2026-01', '2026-02')
GROUP BY 1;

======== 可选：领用材料 inventory_del_dets（仅费用占比，与人次无关）========
SELECT SUBSTRING("del_date", 1, 7) AS ym, COUNT(1) AS cnt
FROM datacenter_db.inventory_del_dets
WHERE "hosp_code" = 'HID0101' AND "dept_name" LIKE '%病理科%' AND isdeleted = '0'
  AND SUBSTRING("del_date", 1, 7) IN ('2026-01', '2026-02')
GROUP BY 1;
*/
