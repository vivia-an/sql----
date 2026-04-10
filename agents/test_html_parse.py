#!/usr/bin/env python3
"""
测试HTML解析功能
支持两种模式：规则解析和AI解析
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from workflow_indicator_verification import IndicatorVerificationWorkflow

def test_html_parse_rules():
    """测试规则解析"""
    print("\n" + "=" * 60)
    print("测试规则解析")
    print("=" * 60)
    
    html_file = "bi_selenium_result.html"
    
    if not os.path.exists(html_file):
        print(f"HTML文件不存在: {html_file}")
        return
    
    print(f"读取HTML文件: {html_file}")
    with open(html_file, "r", encoding="utf-8") as f:
        html_content = f.read()
    
    print(f"HTML内容长度: {len(html_content)} 字符")
    
    # 创建临时workflow实例
    workflow = IndicatorVerificationWorkflow(
        html_url="test",
        baseline_list_path="baseline_indicators_example.txt"
    )
    
    # 使用规则解析
    indicators = workflow._parse_html_indicators(html_content)
    
    print(f"\n规则解析提取到 {len(indicators)} 个指标:")
    for i, ind in enumerate(indicators[:10], 1):
        print(f"{i:3d}. {ind.name:30s} = {ind.value}")
    
    if len(indicators) > 10:
        print(f"... 还有 {len(indicators) - 10} 个指标")


def test_html_parse_ai():
    """测试AI解析"""
    print("\n" + "=" * 60)
    print("测试AI解析（LLM）")
    print("=" * 60)
    
    html_file = "bi_selenium_result.html"
    
    if not os.path.exists(html_file):
        print(f"HTML文件不存在: {html_file}")
        return
    
    print(f"读取HTML文件: {html_file}")
    with open(html_file, "r", encoding="utf-8") as f:
        html_content = f.read()
    
    print(f"HTML内容长度: {len(html_content)} 字符")
    
    # 创建临时workflow实例
    workflow = IndicatorVerificationWorkflow(
        html_url="test",
        baseline_list_path="baseline_indicators_example.txt"
    )
    
    # 使用AI解析
    indicators = workflow._extract_indicators_with_llm(html_content)
    
    print(f"\nAI解析提取到 {len(indicators)} 个指标:")
    for i, ind in enumerate(indicators[:20], 1):
        type_info = f"({ind.indicator_type})" if ind.indicator_type else ""
        unit_info = ind.unit if ind.unit else ""
        print(f"{i:3d}. {ind.name:30s} = {ind.value} {unit_info} {type_info}")
    
    if len(indicators) > 20:
        print(f"... 还有 {len(indicators) - 20} 个指标")
    
    print("=" * 60)
    print(f"总计: {len(indicators)} 个指标")


def main():
    """主函数"""
    import argparse
    parser = argparse.ArgumentParser(description="测试HTML解析")
    parser.add_argument("--mode", choices=["rules", "ai", "both"], default="ai",
                       help="解析模式: rules=规则, ai=AI, both=两者都测试")
    args = parser.parse_args()
    
    if args.mode in ["rules", "both"]:
        test_html_parse_rules()
    
    if args.mode in ["ai", "both"]:
        test_html_parse_ai()


if __name__ == "__main__":
    main()
