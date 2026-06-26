# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview
This is a healthcare data analytics project (not a deployable application). It consists of:
- **SQL queries** (~87 `.sql` files) targeting Presto for hospital reporting (手麻, 输血, LIS, 病理, 体检, 医保飞检)
- **Python utility scripts** (root-level): JWT generation (`jwt_utils.py`), date manipulation (`update_dates.py`)
- **AI agents** (`agents/`): BI report crawling, indicator verification using `pyautogen` + OpenAI

### Environment Setup
- **Python 3.12** is used. `uv` is the package manager for `agents/`.
- Root-level dependencies: `pip install -r requirements.txt` (only `PyJWT`)
- Agents dependencies: `cd agents && uv sync` (creates `.venv` with all deps)
- Linter: `ruff` (installed via `uv tool install ruff`), configured in `agents/pyproject.toml`

### Running Services
There are no long-running services to start. All SQL queries target a remote Presto cluster on hospital infrastructure (not available in the cloud VM). Python scripts are run individually.

### Lint
```bash
ruff check .                    # from repo root (checks all Python files)
ruff check --no-fix .           # check without auto-fixing
```

### Running Python Scripts
- Root-level scripts use system Python: `python3 jwt_utils.py`
- Agent scripts use the agents venv: `cd agents && .venv/bin/python <script>.py`
- Agent scripts require `OPENAI_API_KEY` (or compatible LLM API key) and `agents/llm_config.yaml` to be configured

### Key Caveats
- `ruff check` with `fix = true` in `pyproject.toml` will auto-fix files; use `--no-fix` flag if you want check-only mode
- `agents/bi_crawler.py` sets a hardcoded proxy (`127.0.0.1:7897`) on import; this is expected for the hospital network environment
- All database fields are VARCHAR type in the big data platform; date handling requires explicit casting in Presto SQL
