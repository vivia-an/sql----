# -*- coding: utf-8 -*-
"""将 输血线上 DataX JSON 内 SQL 的 current_date 改为调度日 $[yyyy-MM-dd] 对应的 biz_date（统计上月逻辑不变，锚点改为 DolphinScheduler 当天）。"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TARGET = ROOT / "输血线上"

def main() -> None:
    text = TARGET.read_text(encoding="utf-8")
    if not text.strip():
        raise SystemExit(
            "输血线上 为空：请先在 Cursor 中保存该文件，再运行本脚本。"
        )
    old = "WITH base_result AS ("
    new = (
        "WITH ds AS (\n"
        "  SELECT CAST(date_parse('$[yyyy-MM-dd]', '%Y-%m-%d') AS DATE) AS biz_date\n"
        "),\n"
        "base_result AS ("
    )
    if old not in text:
        raise SystemExit("未找到 WITH base_result AS (，请确认文件未被改动。")
    text = text.replace(old, new, 1)
    n = text.count("current_date")
    text = text.replace("current_date", "(SELECT biz_date FROM ds)")
    TARGET.write_text(text, encoding="utf-8")
    print(f"已写入。替换 current_date 共 {n} 处；已注入 ds CTE（DolphinScheduler 占位符 $[yyyy-MM-dd]）。")


if __name__ == "__main__":
    main()
