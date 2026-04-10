#!/usr/bin/env python3
"""
指标核查工作流运行脚本
用法: uv run python run_indicator_verification.py [报表URL]
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from workflow_indicator_verification import IndicatorVerificationWorkflow

# 默认报表URL
DEFAULT_URL = "https://hxdmc.wchscu.cn/bi/sso?proc=1&action=viewer&hback=true&db=!28!01!29!!534e!!897f!!62a5!!8868!!95e8!!6237!!2f!!8fd0!!8425!!7ba1!!7406!!90e8!!2f!!8fd0!!7ba1!!8fd0!!884c!!5206!!6790!_!79d1!!5ba4!!53ca!!533b!!751f!!2f!!8fd0!!7ba1!!6708!!62a5!_!5927!!8868!_!5171!!6027!_20250613_!5171!!6027!!5927!!8868!.db"

# 基准指标清单
BASELINE_FILE = "baseline_indicators_example.txt"


def main():
    # 获取URL参数
    if len(sys.argv) > 1:
        url = sys.argv[1]
    else:
        url = DEFAULT_URL
    
    # 基准文件路径
    baseline_path = os.path.join(os.path.dirname(__file__), BASELINE_FILE)
    
    print("=" * 60)
    print("指标核查工作流")
    print("=" * 60)
    print(f"报表URL: {url[:80]}...")
    print(f"基准文件: {baseline_path}")
    print("=" * 60)
    
    # 创建并运行工作流
    workflow = IndicatorVerificationWorkflow(url, baseline_path)
    workflow.run()


if __name__ == "__main__":
    main()
