#!/usr/bin/env python3
"""
BI报表空值检查 - 运行入口
血缘: bi_null_checker.py -> run_null_check.py

用法:
  # 检测本地HTML文件
  python run_null_check.py --html bi_report.html

  # 检测JSON数据文件
  python run_null_check.py --json bi_report_data.json

  # 用Selenium实时抓取(需要cookies.txt中有效cookie)
  python run_null_check.py --url "https://hxdmc.wchscu.cn/bi/sso?..."

  # 同时检测零值
  python run_null_check.py --html bi_report.html --zero

  # 指定URL的简写 (运管指标每日推送)
  python run_null_check.py --daily
"""
import sys
import os

# 确保可以导入同目录模块
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from bi_null_checker import run_null_check

# 预定义报表URL
REPORT_URLS = {
    "daily": (
        "https://hxdmc.wchscu.cn/bi/sso?proc=1&action=viewer&hback=true"
        "&db=!28!01!29!!534e!!897f!!62a5!!8868!!95e8!!6237!!2f!!8fd0!!8425"
        "!!7ba1!!7406!!90e8!!2f!!8fd0!!7ba1!!53ef!!89c6!!5316!!5206!!6790!"
        "-!52ff!!52a8!!2f!!6bcf!!65e5!!63a8!!9001!!2f!!8fd0!!7ba1!!6307"
        "!!6807!!6bcf!!65e5!!63a8!!9001!!28!!4e0a!!5348!!29!.db"
    ),
}


def main():
    args = sys.argv[1:]
    include_zero = "--zero" in args
    if "--zero" in args:
        args.remove("--zero")

    output_dir = os.path.dirname(os.path.abspath(__file__))
    kwargs = {"include_zero": include_zero, "output_dir": output_dir}

    if "--html" in args:
        idx = args.index("--html")
        kwargs["html_file"] = args[idx + 1] if idx + 1 < len(args) else "bi_report.html"
    elif "--json" in args:
        idx = args.index("--json")
        kwargs["json_file"] = args[idx + 1] if idx + 1 < len(args) else "bi_report_data.json"
    elif "--url" in args:
        idx = args.index("--url")
        kwargs["url"] = args[idx + 1] if idx + 1 < len(args) else REPORT_URLS["daily"]
    elif "--daily" in args:
        kwargs["url"] = REPORT_URLS["daily"]
    else:
        # 自动检测
        if os.path.exists(os.path.join(output_dir, "bi_report.html")):
            kwargs["html_file"] = os.path.join(output_dir, "bi_report.html")
            print("[AUTO] 检测到 bi_report.html，使用本地HTML模式")
        elif os.path.exists(os.path.join(output_dir, "bi_report_data.json")):
            kwargs["json_file"] = os.path.join(output_dir, "bi_report_data.json")
            print("[AUTO] 检测到 bi_report_data.json，使用JSON模式")
        else:
            kwargs["url"] = REPORT_URLS["daily"]
            print("[AUTO] 无本地文件，使用Selenium实时抓取")

    result = run_null_check(**kwargs)

    if result.get("error"):
        print(f"\n检查失败: {result['error']}")
        sys.exit(1)

    # 返回码: 有空值返回1, 无空值返回0
    null_count = result.get("null_count", 0)
    if null_count > 0:
        print(f"\n发现 {null_count} 个空值，请检查报告")
        sys.exit(2)
    else:
        print("\n检查通过，无空值")
        sys.exit(0)


if __name__ == "__main__":
    main()
