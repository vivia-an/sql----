#!/usr/bin/env python3
"""
测试AI语义匹配功能
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from workflow_indicator_verification import IndicatorVerificationWorkflow, Indicator

def test_ai_matching():
    """测试AI语义匹配"""
    print("=" * 60)
    print("测试AI语义匹配功能")
    print("=" * 60)
    
    # 创建workflow实例
    workflow = IndicatorVerificationWorkflow(
        html_url="test",
        baseline_list_path="baseline_indicators_example.txt"
    )
    
    # 加载基准指标
    baseline_file = os.path.join(os.path.dirname(__file__), "baseline_indicators_example.txt")
    workflow.baseline_indicator_list = workflow._load_baseline_list(baseline_file)
    
    if not workflow.baseline_indicator_list:
        print("无法加载基准清单")
        return
    
    print(f"\n基准指标数量: {len(workflow.baseline_indicator_list.indicators)}")
    print("基准指标示例:")
    for ind in workflow.baseline_indicator_list.indicators[:5]:
        print(f"  - {ind.name}: {ind.value}")
    
    # 测试用例
    test_cases = [
        "门诊人次(线上+线下)",  # 应该匹配 "门诊人次"
        "互联网门诊完成人次",      # 应该匹配 "互联网门诊完成人次" 或类似
        "在线门诊人次",           # 应该匹配 "互联网门诊完成人次" 或类似
        "出院人次",              # 应该匹配 "出院人次"
        "不存在的指标名称",        # 应该返回None
    ]
    
    print("\n" + "=" * 60)
    print("测试AI匹配")
    print("=" * 60)
    
    for test_name in test_cases:
        print(f"\n测试指标: {test_name}")
        result = workflow._find_best_match_with_llm(
            test_name, 
            workflow.baseline_indicator_list.indicators
        )
        
        if result:
            matched_indicator, confidence = result
            print(f"  ✅ 匹配成功:")
            print(f"     基准指标: {matched_indicator.name}")
            print(f"     相似度: {confidence:.2f}")
        else:
            print(f"  ❌ 未找到匹配")


if __name__ == "__main__":
    test_ai_matching()
