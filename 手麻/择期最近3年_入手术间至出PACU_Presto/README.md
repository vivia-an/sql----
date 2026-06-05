# 择期最近3年 · 入手术间至出 PACU · Presto 转换包

## 1. 转换源 → 目标
| 源（Oracle） | 目标（Presto） | 说明 |
|---|---|---|
| `手麻原始sql/需求1-手术信息查询报表(1).sql` | `01_手术信息查询报表_Presto.sql` | 100+ 字段宽表，按需求口径补强 |
| `手麻原始sql/生命体征(1).txt`               | `02_生命体征_Presto.sql`         | **一张可直接执行的大表（无占位符）**。原 5 段模板内联，监护数据聚合到「每台手术 × 每个监护项目」一行（count/first_time/last_time/min/max/avg） |
| `手麻原始sql/用药(1).txt`                   | `03_用药_Presto.sql`             | **一张可直接执行的大表（无占位符）**。去掉 `${ipi}` 限定，每条麻醉用药事件一行，并入患者/手术/科室元数据 |

> 02/03 不再需要 `${id}/${ipi}/${t1}/${t2}/${crmin}/${crmax}/${start}/${end}` 等参数，复制粘贴即可执行。

## 2. 范围口径（统一应用于 3 份 SQL）
1. **择期**：`coalesce(reg.is_emergency, sam_apply.is_emergency) IS DISTINCT FROM '1'`
2. **入手术间到出 PACU 数据齐全**：`sam_anar.in_oproom_date` 与 `sam_anar.rec_out_date` 均非空，且前 10 位为合法日期串
3. **最近 3 年**：按 `sam_apply.scheduled_date` 滚动 3 年
   - 时间窗：`2023-05-14 00:00:00` ~ `2026-05-14 23:59:59`
   - 如需按日动态滚动，可把字面量替换为：
     - `date_format(date_add('year', -3, current_date), '%Y-%m-%d') || ' 00:00:00'`
     - `date_format(current_date, '%Y-%m-%d') || ' 23:59:59'`

## 3. 业务过滤（保留与原 Oracle SQL 一致）
- `health_service_org_id = 'HXSSMZK'`
- `sam_room_id NOT IN ('73')`
- `oper_type = 'ROOM_OPER' OR (oper_type IN ('NJ_OPER','QZJ_OPER') AND patient_source = '03')`

> 在 `02/03` 两个模板里这套硬编码不出现（原 SQL 也没写），仅靠 cohort 三条件（择期 + 入室/出 PACU + 时间窗）筛 cohort。

## 4. 库与逻辑删除
- 手术麻醉表：`hid0101_orcl_operaanesthisa_emrhis.*`
- 派单接送人员：`hid0101_orcl_operaanesthisa_cdxtboot.sys_user`（与本部线上一致）
- 全部表加 `isdeleted = '0'`（`information_schema.tables` 例外）

## 5. Oracle → Presto 关键替换
| Oracle | Presto |
|---|---|
| `nvl(a,b)` / `nvl(a,b,c)` | `coalesce(a,b)` / `IF(a IS NOT NULL, b, c)` 或 `CASE WHEN` |
| `listagg(x, sep) within group(order by y)` | `array_join(array_agg(x ORDER BY y), sep)` |
| `to_date(s,'yyyy-mm-dd hh24:mi:ss')` | `date_parse(s, '%Y-%m-%d %H:%i:%s')` 或 `try(date_parse(...))` |
| `to_char(d,'yyyy-mm-dd hh24:mi:ss')` | `date_format(d, '%Y-%m-%d %H:%i:%s')` |
| `instr(x, s)` | `strpos(x, s)` |
| `(d2 - d1) * 24` 小时差 | `date_diff('second', d1, d2) / 3600.0` |
| `d + 1` 日期加天 | `date_add('day', 1, d)` |
| `\|\|` 拼接 | `concat(...)` 或 `\|\|`（注意 NULL：用 `coalesce(x,'')`） |
| `sysdate` | `current_timestamp` |
| `f_j_getage(refDate, birthday)` | 入室年 − 出生年（与报表明细 Presto 版一致） |
| `nvl2(x, a, b)` | `IF(x IS NOT NULL, a, b)` |
| `user_tables` | `information_schema.tables`（按 `table_schema` 过滤） |
| 中文别名 | 用双引号 `"病案号"` |

## 6. 字段血缘标注
每一列后均就近以 `-- 注释` 标注来源表/字段；详见每份 SQL 头部与脚注。

## 7. 未实现 / 占位列清单（与原 Oracle SQL 一致，保持空字符串）
来自 `01_手术信息查询报表_Presto.sql`：

- 急诊手术分级
- 首台 / 末台 / 周末
- 到达手术室时间（接）
- 建立人工气道 / 拆除人工气道
- 小恢复室事件时间 / 入小恢复室时间
- 变更手术间
- 术前抗菌药物使用时间 / 术中抗菌药物追加时间
- 术前抗菌药物医嘱名称 / 术中抗菌药物医嘱名称

## 8. 已知歧义/取值差异（已在 SQL 内就近 -- 标注）
1. `ASA分级` 与 `切口等级` 输出为「代码值」（源 Oracle SQL 即如此），如需中文：
   - `pub_asamzfj.s_asamzfj_cmc`、`pub_ssqk_dj.s_ssqk_dj_cmc`
2. `手术预计时长` 在源 SQL 中映射的是 `max(a.blood_loss)`（疑似 Oracle 侧别名错位），本版**沿用同名同值**；若需真实预计时长，请改为 `max(a.op_time)`
3. `麻醉助手2工号` 在源 SQL 中误写为 `mzem2.employee_name`，本版**已按业务含义改为 `mzem2.id`**
4. `生命体征` 段⑤的分区表 `${t1}/${t2}` 是「动态表名」，Presto 本身不支持 SQL 内变量切表，需要应用层把段③的结果回拼到 FROM 子句
5. `生命体征` 段③用 `information_schema.tables` 替代 Oracle 的 `user_tables`，要求线上 catalog/schema 命名与库名一致；若不一致请在 `ut1/ut2` 关联里追加 `table_catalog = '<catalog>'`

## 9. 字段未找到（暂无可对齐源表，留空待补）
- `急诊手术分级`：未在血缘中找到字段；保留 `''`
- `首台/末台/周末`：业务派生类，需要外层按日聚合后计算
- `建立/拆除人工气道`、`抗菌药物 4 列`：sam_anar_enent 的特定 `s_mzsj_dm` 取值未在文档中给出明确字典码，留空

## 10. 运行建议
1. 三份 SQL 均可直接复制到 Presto 客户端执行，无需任何参数渲染
2. 推荐执行顺序与用途：
   - `01_手术信息查询报表_Presto.sql`：cohort 全字段宽表（≈ 每台手术 1 行）
   - `02_生命体征_Presto.sql`：cohort × 监护项目（≈ 每台手术 5~15 行；监护数据下推到设备 ID 集合，再按入室/出室时间段裁切）
   - `03_用药_Presto.sql`：cohort × 麻醉用药事件（≈ 每台手术若干行）
3. 02 数据量风险：`sam_anar_vs_dev` 是高频时间序列，3 年量级可能很大。本版已用 `cohort_devices` 把设备 ID 集合先收敛，并对 `time_point` 做 cohort 全局时间窗 + 单台手术入室/出室窗 双重裁剪；若引擎仍跑不动可：
   - 把 `cohort_devices` 物化为 staging 表后再 JOIN
   - 或在大数据侧按 `time_point` 做分区，line-level 推到 `sam_anar_vs_dev`
4. 若 cohort 行数偏少，按以下顺序排查：
   - `scheduled_date` 时间窗格式是否与平台一致（含 `00:00:00` 后缀）
   - `in_oproom_date / rec_out_date` 是否真有非空数据，可用 `length(trim(...)) >= 10` 单独打捞
   - 业务三件套（`HXSSMZK / NOT IN '73' / oper_type+patient_source`）是否过严，可参考 `择期入手术间至出PACU_默认版_Presto.sql` 的宽口径
5. 02/03 中 cohort 定义完全一致（择期 + 入室/出 PACU + 最近 3 年），可用于横向对照
