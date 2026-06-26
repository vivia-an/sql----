# AGENTS.md

## Cursor Cloud specific instructions

**本仓库就是一个 SQL 库**：核心交付物是 `.sql` 查询与血缘/架构 `.md` 文档。用户明确说明——**不需要搭建或运行任何 dev/service**。工作模式：用户提 SQL 需求，agent 按仓库约定分析血缘并产出可执行的 Presto SQL（必要时帮忙拿结果）。不要去启动静态服务、Python 工具或 `agents/` 工作流，除非用户明确要求。

### 主要工作（SQL 生成）—— 务必遵守
- 详见 `CLAUDE.md` 与 `.cursor/rules/sql-generator.mdc`。要点：
  - 引擎为 **Presto**；大数据平台所有字段均为 **varchar**（含日期/`lastupdatedttm`，注意日期处理）。
  - 所有表加逻辑删除筛选 `isdeleted = '0'`；中文字段名用双引号包围。
  - 库名规则：手术麻醉相关统一为 `hid0101_orcl_operaanesthisa_emrhis`；HIS 查询加 `hid0101_cache_his_dhcapp_sqluser`；datacenter 查询加 `datacenter_db`。
  - **先分析血缘再生成**：优先按血缘查询，查不到再按表结构；字段都要标注准确来源；找不到/有歧义的字段要列出标识，不要臆造。生成前如有不清楚先与用户交互确认。
- 每次功能性修改在根目录 `.trace` 追加时间线条目（功能 + 涉及文件），保持简洁。

### 环境（最小，仅备用）
- Python 3.12 已装；update 脚本 `pip3 install -r requirements.txt`（当前仅 `PyJWT`，供根目录可选工具脚本）。SQL 面向外部引擎执行，本环境无 Presto/StarRocks，**不能直接在此跑 SQL**。
- 可选辅助（默认不用）：根目录 Python 工具（如 `python3 jwt_utils.py`）、静态 HTML 预览（`医保飞检/index.html`、`蓝图/start_preview.sh`）、`agents/` BI 核查工作流（需内网 BI + Selenium + LLM Key，云环境无法端到端运行）。
