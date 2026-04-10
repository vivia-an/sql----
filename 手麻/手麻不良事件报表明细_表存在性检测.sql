-- 用途：检测《手麻不良事件报表明细_Oracle转Presto.sql》涉及基表是否存在（含 pub_sssyzt，与 需求2-不良事件管理 一致）
-- 前置：在 Presto/Trino 客户端先选中「手麻表所在 catalog」（如 hive），再执行；information_schema 只反映当前 catalog。
-- 修改：将 v_schema 改为与你环境一致（与 SQL 中 hid0101_orcl_operaanesthisa_emrhis 段一致；若实为 catalog.schema 且 schema=default 则改为 default）。

WITH v AS (
    SELECT CAST('hid0101_orcl_operaanesthisa_emrhis' AS VARCHAR) AS v_schema
),
expected AS (
    SELECT table_name
    FROM (
        VALUES
            ROW ('sam_apply'),
            ROW ('sam_reg'),
            ROW ('ipi_registration'),
            ROW ('opc_registration'),
            ROW ('sam_reg_op'),
            ROW ('sam_apply_op'),
            ROW ('sam_anar'),
            ROW ('hra00_department'),
            ROW ('sam_room'),
            ROW ('hrm_employee'),
            ROW ('gb_t_2261_1_2003'),
            ROW ('sam_adverse_event'),
            ROW ('sam_adverse'),
            ROW ('sam_adverse_factor'),
            ROW ('sam_adverse_reason'),
            ROW ('pub_smzd'),
            ROW ('pub_sssyzt')
    ) AS t (table_name)
)
SELECT
    e.table_name AS "逻辑表名",
    CASE WHEN t.table_name IS NOT NULL THEN '存在' ELSE '缺失' END AS "status",
    t.table_type AS "元数据类型",
    t.table_catalog AS "table_catalog",
    t.table_schema AS "table_schema"
FROM expected e
CROSS JOIN v
LEFT JOIN information_schema.tables t
    ON lower(t.table_schema) = lower(v.v_schema)
    AND lower(t.table_name) = lower(e.table_name)
ORDER BY
    CASE WHEN t.table_name IS NULL THEN 0 ELSE 1 END,
    e.table_name;

-- 汇总：应存在 17 张基表；缺失行数 >0 需改 catalog/schema 或建表
-- SELECT count(*) FILTER (WHERE t.table_name IS NULL) AS "缺失表数量" FROM ... （可自行包一层）

-- ---------------------------------------------------------------------------
-- 跨 catalog 显式写法（Trino：把 hive 换成实际 catalog 名）
-- LEFT JOIN hive.information_schema.tables t
--   ON lower(t.table_schema) = lower('hid0101_orcl_operaanesthisa_emrhis')
--   AND lower(t.table_name) = lower(e.table_name)
-- ---------------------------------------------------------------------------
-- 手工：SHOW TABLES FROM "hive".hid0101_orcl_operaanesthisa_emrhis;
-- ---------------------------------------------------------------------------
