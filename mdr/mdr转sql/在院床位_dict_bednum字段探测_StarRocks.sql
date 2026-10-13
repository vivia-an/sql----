-- md.dict_bednum 字段清单（StarRocks）
-- approvedbed 已报 cannot be resolved，仓库无该表结构，不编造列名
-- 把本结果发回后再把编制/核定/极限三列映射进在院床位_StarRocks.sql

select
    table_schema as `库`,
    table_name as `表`,
    column_name as `字段`,
    data_type as `类型`,
    ordinal_position as `序号`
from information_schema.columns
where table_schema = 'md'
  and lower(table_name) = 'dict_bednum'
order by ordinal_position;

-- 或：desc md.dict_bednum;
