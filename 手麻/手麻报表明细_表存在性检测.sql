-- 用途：检测《手麻报表明细_Oracle转Presto.sql》涉及基表是否存在
-- 前置：在 Presto/Trino 选中「同时包含手麻 schema 与 cdxt_boot（若有）」的 catalog 后执行；
--       仅手麻在 hive、sys_user 在别 catalog 时：sys_user 行会显示缺失，需用文件末尾「跨 catalog」语句单独查。
-- 手麻逻辑库名与主 SQL 一致：hid0101_orcl_operaanesthisa_emrhis；派运用户表：cdxt_boot.sys_user

WITH expected AS (
    SELECT schema_name, table_name
    FROM (
        VALUES
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'gb_t_2261_1_2003'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'hra00_department'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'hrm_employee'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'ipi_registration'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'opc_registration'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'pro_send_order'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'pub_jldw'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'pub_sssyzt'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_anar'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_anar_enent'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_apply'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_apply_op'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_emr_rec'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_emr_rec_nv'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_reg'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_reg_op'),
            ROW ('hid0101_orcl_operaanesthisa_emrhis', 'sam_room'),
            ROW ('cdxt_boot', 'sys_user')
    ) AS t (schema_name, table_name)
)
SELECT
    e.schema_name AS "schema",
    e.table_name AS "逻辑表名",
    CASE WHEN t.table_name IS NOT NULL THEN '存在' ELSE '缺失' END AS "status",
    t.table_type AS "元数据类型",
    t.table_catalog AS "table_catalog"
FROM expected e
LEFT JOIN information_schema.tables t
    ON lower(t.table_schema) = lower(e.schema_name)
    AND lower(t.table_name) = lower(e.table_name)
ORDER BY
    e.schema_name,
    CASE WHEN t.table_name IS NULL THEN 0 ELSE 1 END,
    e.table_name;

-- ---------------------------------------------------------------------------
-- 缺失数量汇总（可选，与上面二选一或复制 expected 定义）
-- ---------------------------------------------------------------------------
-- WITH expected AS ( ... 同上 VALUES ... )
-- SELECT
--   count(*) AS "应检测表数",
--   count(t.table_name) AS "已存在数",
--   count(*) - count(t.table_name) AS "缺失数"
-- FROM expected e
-- LEFT JOIN information_schema.tables t
--   ON lower(t.table_schema) = lower(e.schema_name)
--   AND lower(t.table_name) = lower(e.table_name);

-- ---------------------------------------------------------------------------
-- sys_user 在其它 catalog 时（将 my_catalog 换成实际名，如 hive、iceberg）
-- SELECT table_catalog, table_schema, table_name, table_type
-- FROM my_catalog.information_schema.tables
-- WHERE lower(table_schema) = 'cdxt_boot'
--   AND lower(table_name) = 'sys_user';
-- ---------------------------------------------------------------------------
-- 仅手麻 17 张、不含 cdxt：从 expected 中删除最后两行 cdxt_boot/sys_user 即可
-- ---------------------------------------------------------------------------
