# AGENTS.md

## Cursor Cloud specific instructions

本仓库本质是「医疗数据分析 SQL + 文档知识库」，没有统一可部署的应用。核心交付物是 `.sql` 查询、血缘/架构 `.md` 文档，以及若干可选的 Python 辅助脚本与静态 HTML 页面。SQL 面向外部 Presto / StarRocks / Cache 引擎执行（本环境无这些引擎，无法直接跑 SQL）。

### 依赖与运行环境
- 系统已装 Python 3.12。启动时 update 脚本执行 `pip3 install -r requirements.txt`（当前仅 `PyJWT`），用于根目录的 Python 工具脚本。
- `pip3 install` 默认装到用户目录（`--user`），无需 sudo；这是预期行为。

### 可运行的部分（按可靠度）
- 根目录 Python 工具：例如 `python3 jwt_utils.py` 直接生成并打印 JWT token，是最稳定的「hello world」。
- 静态 HTML 页面（自包含，无外部 CDN），用本地静态服务器查看即可：
  - `cd 医保飞检 && python3 -m http.server <port>`，浏览 `index.html`（交互式思维导图）。
  - `蓝图/start_preview.sh`（固定端口 8766，serve `新一代大数据平台_1234蓝图.html`）。
- `agents/`：基于 AutoGen + Selenium 的 BI 指标核查工作流（`uv` 项目，见 `agents/pyproject.toml` 与 `agents/README_indicator_verification.md`）。**无法在本云环境端到端运行**：它依赖医院内网 BI 地址（`hxdmc.wchscu.cn`）、Selenium 浏览器以及 LLM API Key。如需开发该模块，单独 `uv sync`（`agents/` 目录）并提供相应密钥/内网访问。

### Lint / Test / Build
- 无统一 build。无根级测试框架；`agents/test_*.py` 依赖 autogen 等重型库且需密钥，默认不在最小环境内运行。
- `agents/pyproject.toml` 配置了 ruff（仅作用于 `agents/`）。
- 对独立脚本做基本检查：`python3 -m py_compile <file.py>`。

### 项目约定（重要）
- 见 `CLAUDE.md` 与 `.cursor/rules/sql-generator.mdc`：所有 SQL 适配 Presto，字段均为 varchar，需加 `isdeleted = '0'`，中文字段名用双引号；手术麻醉库名统一为 `hid0101_orcl_operaanesthisa_emrhis`。
- 每次功能性修改需在根目录 `.trace` 追加时间线条目（功能 + 涉及文件），保持简洁。
