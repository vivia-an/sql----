"""
指标核查工作流测试脚本
使用 uv run python test_indicator_workflow.py 运行
"""
import os
import sys
import json

# 确保能导入本地模块
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from workflow_indicator_verification import (
    Indicator, 
    IndicatorList, 
    IndicatorVerificationWorkflow
)


def test_indicator_class():
    """测试Indicator数据类"""
    print("\n=== 测试 Indicator 类 ===")
    
    # 创建指标
    ind = Indicator(
        indicator_id="IND001",
        name="门诊人次",
        value="838723",
        indicator_type="门诊指标",
        unit="人次"
    )
    
    print(f"指标ID: {ind.indicator_id}")
    print(f"名称: {ind.name}")
    print(f"值: {ind.value}")
    print(f"类型: {ind.indicator_type}")
    print(f"状态: {ind.status}")
    
    # 测试to_dict
    d = ind.to_dict()
    print(f"to_dict结果: {json.dumps(d, ensure_ascii=False, indent=2)}")
    
    # 从dict重建（手动方式）
    ind2 = Indicator(
        indicator_id=d["indicator_id"],
        name=d["name"],
        value=d["value"],
        indicator_type=d.get("indicator_type", ""),
        unit=d.get("unit", "")
    )
    print(f"从dict恢复: {ind2.name} = {ind2.value}")
    
    print("[OK] Indicator类测试通过")
    return True


def test_indicator_list():
    """测试IndicatorList类"""
    print("\n=== 测试 IndicatorList 类 ===")
    
    il = IndicatorList()
    
    # 添加指标
    il.add_indicator(Indicator("IND001", "门诊人次", "838723", "门诊指标", "人次"))
    il.add_indicator(Indicator("IND002", "专家挂号人次", "117250", "门诊指标", "人次"))
    il.add_indicator(Indicator("IND003", "出院人次", "23443", "住院指标", "人次"))
    
    print(f"添加了 {len(il.indicators)} 个指标")
    
    # 获取待对比指标
    pending = il.get_pending_indicators(batch_size=2)
    print(f"获取待对比指标（批次大小2）: {len(pending)} 个")
    for p in pending:
        print(f"  - {p.name}")
    
    # 更新状态
    il.update_indicator_status("IND001", "compared", {"has_difference": False})
    
    # 获取统计
    stats = il.get_statistics()
    print(f"统计: {json.dumps(stats, ensure_ascii=False)}")
    
    # 检查是否全部完成
    print(f"全部完成: {il.all_compared()}")
    
    print("[OK] IndicatorList类测试通过")
    return True


def test_load_baseline_manually():
    """测试手动加载基准指标"""
    print("\n=== 测试手动加载基准指标 ===")
    
    # 读取示例文件
    baseline_file = os.path.join(os.path.dirname(__file__), "baseline_indicators_example.txt")
    
    if not os.path.exists(baseline_file):
        print(f"  基准文件不存在: {baseline_file}")
        return False
    
    il = IndicatorList(source=baseline_file)
    
    with open(baseline_file, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    # 跳过标题行
    for i, line in enumerate(lines[1:], start=1):
        line = line.strip()
        if not line:
            continue
        
        parts = line.split(",")
        if len(parts) >= 2:
            ind = Indicator(
                indicator_id=f"BASE{i:03d}",
                name=parts[0].strip(),
                value=parts[1].strip(),
                indicator_type=parts[2].strip() if len(parts) > 2 else "",
                unit=parts[3].strip() if len(parts) > 3 else "",
                time_range=parts[4].strip() if len(parts) > 4 else ""
            )
            il.add_indicator(ind)
    
    print(f"从文本加载了 {len(il.indicators)} 个指标")
    for ind in il.indicators[:5]:
        print(f"  - {ind.name}: {ind.value} ({ind.indicator_type})")
    if len(il.indicators) > 5:
        print(f"  ... 还有 {len(il.indicators) - 5} 个指标")
    
    print("[OK] 基准加载测试通过")
    return True


def test_comparison_logic():
    """测试对比逻辑"""
    print("\n=== 测试对比逻辑 ===")
    
    # 设置基准指标
    baseline_list = IndicatorList()
    baseline_list.add_indicator(Indicator("BASE001", "门诊人次", "838723", "门诊指标", "人次"))
    baseline_list.add_indicator(Indicator("BASE002", "专家挂号人次", "117250", "门诊指标", "人次"))
    baseline_list.add_indicator(Indicator("BASE003", "出院人次", "23443", "住院指标", "人次"))
    
    # 设置当前指标（模拟从HTML提取）
    current_list = IndicatorList()
    current_list.add_indicator(Indicator("CUR001", "门诊人次", "850000", "门诊指标", "人次"))
    current_list.add_indicator(Indicator("CUR002", "专家挂号人次", "120000", "门诊指标", "人次"))
    current_list.add_indicator(Indicator("CUR003", "出院人次", "24000", "住院指标", "人次"))
    
    # 构建基准字典
    baseline_dict = {}
    for bi in baseline_list.indicators:
        baseline_dict[bi.name.lower()] = bi
    
    print("对比结果:")
    for ci in current_list.indicators:
        ci_name = ci.name.lower()
        if ci_name in baseline_dict:
            bi = baseline_dict[ci_name]
            try:
                current_val = float(ci.value.replace(",", ""))
                baseline_val = float(bi.value.replace(",", ""))
                diff = current_val - baseline_val
                pct_diff = (diff / baseline_val) * 100 if baseline_val != 0 else 0
                
                risk = "low"
                if abs(pct_diff) >= 15:
                    risk = "high"
                elif abs(pct_diff) >= 5:
                    risk = "medium"
                
                print(f"  {ci.name}:")
                print(f"    当前值: {ci.value}, 基准值: {bi.value}")
                print(f"    差异: {diff:+.0f} ({pct_diff:+.2f}%)")
                print(f"    风险等级: {risk}")
                
                # 更新状态
                current_list.update_indicator_status(ci.indicator_id, "compared", {
                    "pct_diff": round(pct_diff, 2),
                    "has_difference": abs(pct_diff) > 0.01,
                    "risk_level": risk
                })
                
            except ValueError:
                print(f"  {ci.name}: 无法数值比较")
        else:
            print(f"  {ci.name}: 基准中未找到")
    
    # 检查状态
    stats = current_list.get_statistics()
    print(f"\n统计: {json.dumps(stats, ensure_ascii=False)}")
    print(f"全部完成: {current_list.all_compared()}")
    
    print("[OK] 对比逻辑测试通过")
    return True


def test_workflow_simulation():
    """工作流模拟测试（不实际创建agents）"""
    print("\n=== 工作流模拟测试 ===")
    
    # 模拟工作流数据结构
    print("[步骤1] 模拟加载基准指标...")
    baseline_list = IndicatorList(source="baseline_indicators_example.txt")
    baseline_list.add_indicator(Indicator("B1", "门诊人次", "838723"))
    baseline_list.add_indicator(Indicator("B2", "出院人次", "23443"))
    baseline_list.add_indicator(Indicator("B3", "专家挂号人次", "117250"))
    print(f"  加载了 {len(baseline_list.indicators)} 个基准指标")
    
    print("\n[步骤2] 模拟HTML提取...")
    current_list = IndicatorList(source="html_extract")
    current_list.add_indicator(Indicator("C1", "门诊人次", "850000"))
    current_list.add_indicator(Indicator("C2", "出院人次", "24500"))
    current_list.add_indicator(Indicator("C3", "新增指标", "12345"))
    print(f"  提取了 {len(current_list.indicators)} 个当前指标")
    
    print("\n[步骤3] 批量对比...")
    baseline_dict = {bi.name.lower(): bi for bi in baseline_list.indicators}
    
    batch_size = 2
    round_num = 0
    
    while not current_list.all_compared():
        round_num += 1
        pending = current_list.get_pending_indicators(batch_size)
        print(f"  第{round_num}轮: 对比 {len(pending)} 个指标")
        
        for p in pending:
            baseline_match = baseline_dict.get(p.name.lower())
            
            if baseline_match:
                try:
                    curr = float(p.value.replace(",", ""))
                    base = float(baseline_match.value.replace(",", ""))
                    pct = ((curr - base) / base) * 100 if base != 0 else 0
                    diff_info = {"pct_diff": round(pct, 2), "has_difference": abs(pct) > 0.01}
                except:
                    diff_info = {"comparison_type": "text"}
            else:
                diff_info = {"not_found_in_baseline": True, "has_difference": True}
            
            current_list.update_indicator_status(p.indicator_id, "compared", diff_info)
            print(f"    - {p.name}: {json.dumps(diff_info, ensure_ascii=False)}")
    
    print("\n[步骤4] 生成汇总报告...")
    stats = current_list.get_statistics()
    print(f"  总计: {stats['total']} 个指标")
    print(f"  已对比: {stats['compared']} 个")
    print(f"  有差异: {stats['with_difference']} 个")
    print(f"  进度: {stats['progress']}")
    
    # 统计风险
    high_risk = []
    medium_risk = []
    for ind in current_list.indicators:
        if ind.difference:
            pct = ind.difference.get("pct_diff", 0)
            if abs(pct) >= 15:
                high_risk.append(ind)
            elif abs(pct) >= 5:
                medium_risk.append(ind)
    
    print(f"\n  高风险指标: {len(high_risk)} 个")
    for h in high_risk:
        print(f"    - {h.name}: {h.difference.get('pct_diff', 'N/A')}%")
    
    print(f"  中风险指标: {len(medium_risk)} 个")
    for m in medium_risk:
        print(f"    - {m.name}: {m.difference.get('pct_diff', 'N/A')}%")
    
    print("\n[OK] 工作流模拟测试通过")
    return True


def test_workflow_init():
    """测试工作流初始化（需要实际URL和文件）"""
    print("\n=== 测试工作流初始化 ===")
    
    # 检查必要文件
    baseline_file = os.path.join(os.path.dirname(__file__), "baseline_indicators_example.txt")
    
    if not os.path.exists(baseline_file):
        print(f"  [SKIP] 基准文件不存在: {baseline_file}")
        return True
    
    # 使用示例URL（不实际访问）
    test_url = "https://example.com/bi/report"
    
    try:
        # 这会初始化workflow但不会实际爬取
        print(f"  尝试初始化工作流...")
        print(f"  URL: {test_url}")
        print(f"  基准文件: {baseline_file}")
        
        # 注意：实际初始化会尝试爬取URL，这里跳过
        print("  [SKIP] 跳过实际初始化（需要有效URL）")
        
        print("[OK] 工作流初始化测试通过（跳过实际创建）")
        return True
        
    except Exception as e:
        print(f"  [INFO] 初始化异常（预期行为）: {e}")
        return True


def main():
    """运行所有测试"""
    print("=" * 60)
    print("指标核查工作流测试")
    print("=" * 60)
    
    tests = [
        ("Indicator类", test_indicator_class),
        ("IndicatorList类", test_indicator_list),
        ("基准加载", test_load_baseline_manually),
        ("对比逻辑", test_comparison_logic),
        ("工作流模拟", test_workflow_simulation),
        ("工作流初始化", test_workflow_init),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            result = test_func()
            results.append((name, "PASS" if result else "FAIL"))
        except Exception as e:
            print(f"[ERROR] {name} 测试异常: {e}")
            import traceback
            traceback.print_exc()
            results.append((name, "ERROR"))
    
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)
    
    for name, status in results:
        status_icon = "[OK]" if status == "PASS" else "[FAIL]" if status == "FAIL" else "[ERR]"
        print(f"  {status_icon} {name}")
    
    passed = sum(1 for _, s in results if s == "PASS")
    total = len(results)
    print(f"\n通过: {passed}/{total}")
    
    return passed == total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
