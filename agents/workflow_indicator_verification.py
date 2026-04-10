#!/usr/bin/env python3
"""
指标核查工作流 (Indicator Verification Workflow)

入口参数：
1. html_url: BI报表页面URL（通过爬虫获取HTML内容）
2. baseline_list_path: 基准指标清单文件路径（text格式）

工作流程：
- 初始化：爬取HTML，加载基准清单
- 阶段1：从HTML提取指标，生成当前指标清单
- 阶段1-2循环：逐个/批量对比，更新清单状态
- 阶段3：深度分析差异
- 阶段4：写入JSON预警文件
- 阶段5：简短汇报总结

血缘路由：
coordinate_agent -> html_extractor_agent <-> indicator_comparator_agent -> 
difference_analyzer_agent -> alert_agent -> report_agent
"""

import json
import os
import re
from typing import Any, Dict, List, Optional, Tuple
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass, field, asdict

from autogen.agentchat import initiate_group_chat
from autogen.agentchat.group.patterns import DefaultPattern
from autogen import ConversableAgent, UserProxyAgent
from autogen.agentchat.group import (
    ReplyResult,
    ContextVariables,
    AgentTarget,
)
from llm_config import get_llm_config, load_config
from openai import OpenAI

# 导入爬虫模块
from bi_crawler import crawl_bi_report, build_bi_url


@dataclass
class Indicator:
    """指标数据结构"""
    indicator_id: str
    name: str
    value: str
    indicator_type: str = ""
    unit: str = ""
    time_range: str = ""
    status: str = "pending"  # pending, compared, error
    difference: Optional[Dict] = None
    compared_at: Optional[str] = None
    
    def to_dict(self) -> Dict:
        return asdict(self)


@dataclass 
class IndicatorList:
    """指标清单"""
    indicators: List[Indicator] = field(default_factory=list)
    source: str = ""
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    
    def add_indicator(self, indicator: Indicator):
        self.indicators.append(indicator)
    
    def get_pending_indicators(self, batch_size: int = 10) -> List[Indicator]:
        """获取待对比的指标"""
        pending = [i for i in self.indicators if i.status == "pending"]
        return pending[:batch_size]
    
    def update_indicator_status(self, indicator_id: str, status: str, difference: Dict = None):
        """更新指标状态"""
        for indicator in self.indicators:
            if indicator.indicator_id == indicator_id:
                indicator.status = status
                indicator.difference = difference
                indicator.compared_at = datetime.now().isoformat()
                break
    
    def all_compared(self) -> bool:
        """检查是否所有指标都已对比"""
        return all(i.status != "pending" for i in self.indicators)
    
    def get_statistics(self) -> Dict:
        """获取统计信息"""
        total = len(self.indicators)
        pending = sum(1 for i in self.indicators if i.status == "pending")
        compared = sum(1 for i in self.indicators if i.status == "compared")
        with_diff = sum(1 for i in self.indicators if i.difference and i.difference.get("has_difference"))
        
        return {
            "total": total,
            "pending": pending,
            "compared": compared,
            "with_difference": with_diff,
            "progress": f"{compared}/{total}"
        }
    
    def to_dict(self) -> Dict:
        return {
            "indicators": [i.to_dict() for i in self.indicators],
            "source": self.source,
            "created_at": self.created_at,
            "statistics": self.get_statistics()
        }


class IndicatorVerificationWorkflow:
    """
    指标核查工作流
    
    工作流程：
    1. 初始化阶段：爬取HTML页面，加载基准指标清单
    2. 提取阶段：从HTML提取当前指标
    3. 对比循环：逐批对比指标，更新状态
    4. 分析阶段：深度分析差异
    5. 预警阶段：生成预警JSON
    6. 汇报阶段：生成简短报告
    """
    
    def __init__(
        self,
        html_url: str,
        baseline_list_path: str,
        output_dir: str = ".",
        context_variables: ContextVariables = None
    ):
        """
        初始化工作流
        
        Args:
            html_url: BI报表页面URL
            baseline_list_path: 基准指标清单文件路径（text格式）
            output_dir: 输出目录
        """
        self.html_url = html_url
        self.baseline_list_path = baseline_list_path
        self.output_dir = Path(output_dir)
        
        # 上下文变量
        self.context_variables = context_variables or ContextVariables()
        self.context_variables["html_url"] = html_url
        self.context_variables["baseline_list_path"] = baseline_list_path
        
        # 指标清单
        self.current_indicator_list: Optional[IndicatorList] = None
        self.baseline_indicator_list: Optional[IndicatorList] = None
        
        # HTML内容
        self.html_content: str = ""
        
        # 创建agents
        self._create_agents()
        self.agents = [
            self.coordinate_agent,
            self.html_extractor_agent,
            self.indicator_comparator_agent,
            self.difference_analyzer_agent,
            self.alert_agent,
            self.report_agent
        ]
        
        # 血缘路由
        self._lineage_route = [
            "coordinate_agent",
            "html_extractor_agent",
            "indicator_comparator_agent",
            "difference_analyzer_agent",
            "alert_agent",
            "report_agent"
        ]
        
        print(f"[Workflow] 初始化完成")
        print(f"  HTML URL: {html_url[:60]}...")
        print(f"  基准清单: {baseline_list_path}")
    
    def _create_agents(self):
        """创建所有Agent"""
        
        # 1. 协调者Agent
        self.coordinate_agent = ConversableAgent(
            name="coordinate_agent",
            system_message=self._coordinate_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.1),
            functions=self._create_coordinate_functions(),
        )
        
        # 2. HTML指标提取Agent（阶段1）
        self.html_extractor_agent = ConversableAgent(
            name="html_extractor_agent",
            system_message=self._html_extractor_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.1),
            functions=self._create_extractor_functions(),
        )
        
        # 3. 指标对比Agent（阶段2）
        self.indicator_comparator_agent = ConversableAgent(
            name="indicator_comparator_agent",
            system_message=self._comparator_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.1),
            functions=self._create_comparator_functions(),
        )
        
        # 4. 差异分析Agent（阶段3）
        self.difference_analyzer_agent = ConversableAgent(
            name="difference_analyzer_agent",
            system_message=self._analyzer_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.2),
            functions=self._create_analyzer_functions(),
        )
        
        # 5. 预警输出Agent（阶段4）
        self.alert_agent = ConversableAgent(
            name="alert_agent",
            system_message=self._alert_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.1),
            functions=self._create_alert_functions(),
        )
        
        # 6. 汇报Agent（阶段5）
        self.report_agent = ConversableAgent(
            name="report_agent",
            system_message=self._report_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.2),
            functions=self._create_report_functions(),
        )
        
        # 设置handoff
        self.html_extractor_agent.handoffs.set_after_work(AgentTarget(self.coordinate_agent))
        self.indicator_comparator_agent.handoffs.set_after_work(AgentTarget(self.coordinate_agent))
        self.difference_analyzer_agent.handoffs.set_after_work(AgentTarget(self.coordinate_agent))
        self.alert_agent.handoffs.set_after_work(AgentTarget(self.coordinate_agent))
    
    # ==================== Agent Prompts ====================
    
    def _coordinate_prompt(self) -> str:
        return """你是 coordinate_agent（协调者）

核心任务：管理指标核查工作流的全流程协调。**你必须通过调用函数来推进工作流，不要只回复文字。**

## ⚠️ 关键规则（必须遵守）

**收到任何消息后，你必须立即调用对应的路由函数，不要只回复文字说明！**

## 消息识别与函数调用

| 消息特征 | 立即调用的函数 |
|---------|---------------|
| 刚开始/需要初始化 | `initialize_workflow()` |
| 初始化完成/开始提取 | `go_extractor()` |
| REQUEST_COMPARISON/请求对比 | `go_comparator(indicators_to_compare=...)` |
| 包含"compared_indicators"的JSON | `go_extractor(comparison_results=JSON字符串)` |
| ALL_COMPARED/所有指标对比完成 | `go_analyzer()` |
| 分析完成 | `go_alert()` |
| 预警完成 | `go_report()` |

## 工作流阶段

1. **初始化**: 调用 `initialize_workflow()` 爬取HTML并加载基准清单
2. **提取指标**: 调用 `go_extractor()` 路由到html_extractor_agent
3. **对比循环**: 
   - 收到REQUEST_COMPARISON → 调用 `go_comparator(indicators_to_compare=指标JSON)`
   - 收到对比结果JSON → 调用 `go_extractor(comparison_results=结果JSON)`
4. **深度分析**: ALL_COMPARED后调用 `go_analyzer()`
5. **生成预警**: 调用 `go_alert()`
6. **生成报告**: 调用 `go_report()`

## 禁止行为
❌ 不要只回复"好的，我理解..."而不调用函数
❌ 不要说"请继续处理"而不路由
❌ 收到消息后必须调用函数，不能只解释
"""

    def _html_extractor_prompt(self) -> str:
        return """你是 html_extractor_agent（HTML指标提取专家）

## ⚠️ 关键规则（必须遵守）

**收到消息后，你必须立即调用对应的函数，不要只回复文字说明！**

## 消息识别与函数调用

| 消息特征 | 立即调用的函数 |
|---------|---------------|
| 首次被路由/开始提取 | `extract_indicators_from_html()` |
| 提取完成后 | `request_comparison()` |
| **COMPARISON_RESULTS:** 开头的消息 | `update_indicator_status(提取JSON部分)` |
| 更新完成后 | `request_comparison()` 继续下一批 |

## 工作流程

### 第一阶段：提取指标
1. 收到路由消息 → **立即调用** `extract_indicators_from_html()`
2. 提取完成后 → **立即调用** `request_comparison()` 开始第一批对比

### 第二阶段：对比循环（重复直到完成）
1. 收到 `COMPARISON_RESULTS: {...}` 消息
2. 从消息中提取JSON部分（`{"compared_indicators": [...]}`）
3. **立即调用** `update_indicator_status('{"compared_indicators": [...]}')`
4. 更新完成后 → **立即调用** `request_comparison()` 继续下一批
5. 如果 `request_comparison()` 返回 ALL_COMPARED → 回复 "NEXT_ACTION: ALL_COMPARED"

## 示例

收到消息：
```
COMPARISON_RESULTS: {"compared_indicators": [{"indicator_id": "IND_000", "name": "门诊人次", "status": "compared", ...}], "compared_count": 10}
```

你应该**立即**调用：
```
update_indicator_status('{"compared_indicators": [{"indicator_id": "IND_000", "name": "门诊人次", "status": "compared", ...}], "compared_count": 10}')
```

## 禁止行为
❌ 不要只回复文字解释
❌ 不要说"我收到了结果"然后不调用函数
❌ 必须立即调用函数处理
"""

    def _comparator_prompt(self) -> str:
        return """你是 indicator_comparator_agent（指标对比专家）

## 核心职责
接收待对比的指标JSON，**立即调用 compare_indicators() 函数执行对比**。

## ⚠️ 关键规则（必须遵守）

**当你收到包含指标JSON的消息时，你必须：**
1. 从消息中提取指标JSON数组（格式如 `[{"indicator_id": "IND_000", "name": "...", ...}]`）
2. **立即调用** `compare_indicators(indicators_json)` 函数
3. **不要回复任何文字说明，直接调用函数**

**示例：**
如果收到消息 `route->comparator: [{"indicator_id": "IND_000", "name": "门诊人次", "value": "937949", ...}]`
你应该**立即**调用：
```
compare_indicators('[{"indicator_id": "IND_000", "name": "门诊人次", "value": "937949", ...}]')
```

## 禁止行为
❌ 不要只回复文字说明而不调用函数
❌ 不要说"我将等待"或"我已收到"
❌ 不要解释你要做什么，直接做

## 对比规则

### 差异计算
- 数值差异：计算绝对差和百分比差
- 风险等级：low(<5%), medium(5-15%), high(>=15%)

## 输出格式
compare_indicators函数会自动返回JSON格式的对比结果。
"""

    def _analyzer_prompt(self) -> str:
        return """你是 difference_analyzer_agent（差异分析专家）

## 核心职责
1. 分析所有已对比指标的差异模式
2. 识别异常趋势
3. 评估风险等级
4. 生成分析报告

## 工作流程

1. 调用 analyze_differences() 获取完整指标清单
2. 分析差异模式
3. 生成分析报告

## 分析维度

### 1. 差异模式分析
- 哪些指标类别差异较大
- 是否存在系统性偏差
- 时间趋势分析

### 2. 异常识别
- 突变指标（差异超过阈值）
- 关联指标分析
- 异常原因推断

### 3. 风险评估
- 整体风险等级
- 高风险指标清单
- 影响范围评估

## 输出格式
```json
{
    "summary": {
        "total_indicators": 100,
        "with_difference": 15,
        "high_risk": 2,
        "medium_risk": 8,
        "low_risk": 5
    },
    "patterns": [...],
    "anomalies": [...],
    "recommendations": [...]
}
```
"""

    def _alert_prompt(self) -> str:
        return """你是 alert_agent（预警输出专家）

## 核心职责
1. 接收分析结果
2. 分类预警级别
3. 格式化输出
4. 写入JSON文件

## 工作流程

1. 调用 generate_alerts() 生成预警
2. 调用 write_alert_json() 写入文件

## 预警分类

### 级别
- high: 严重预警，需立即处理
- medium: 一般预警，需关注
- low: 信息提示

### 输出文件
indicator_check_result.json

## 输出格式
```json
{
    "check_time": "2026-01-16T10:00:00",
    "source_url": "...",
    "baseline_file": "...",
    "summary": {...},
    "alerts": [
        {
            "level": "high",
            "indicator_name": "...",
            "current_value": "...",
            "baseline_value": "...",
            "difference_percentage": 15.2,
            "message": "..."
        }
    ]
}
```
"""

    def _report_prompt(self) -> str:
        return """你是 report_agent（汇报总结）

## 核心职责
生成简短的工作流执行报告

## 报告内容

### 1. 执行概要
- 检查时间
- 数据来源
- 基准清单

### 2. 核查结果
- 提取指标总数
- 对比完成情况
- 差异指标统计

### 3. 预警汇总
- 高风险数量
- 中风险数量
- 低风险数量

### 4. 关键发现
- 最大差异指标
- 异常模式

### 5. 建议措施
- 需要关注的指标
- 后续行动建议

## 输出
简短文字报告（不超过500字）

完成后调用 finish_workflow() 结束工作流。
"""

    # ==================== Function Factories ====================
    
    def _create_coordinate_functions(self):
        """创建协调者Agent的函数"""
        workflow = self
        
        def initialize_workflow() -> ReplyResult:
            """初始化工作流：爬取HTML，加载基准清单"""
            context_variables = ContextVariables()
            
            print("[Coordinate] 开始初始化工作流...")
            
            # 1. 爬取HTML
            print(f"[Coordinate] 爬取HTML: {workflow.html_url[:60]}...")
            result = crawl_bi_report(workflow.html_url, full_data=False)
            
            if result.get("success") and result.get("html"):
                workflow.html_content = result["html"]
                context_variables["html_content"] = result["html"][:5000]  # 只存前5000字符
                context_variables["html_loaded"] = True
                print(f"[Coordinate] HTML加载成功，长度: {len(result['html'])} 字符")
            else:
                context_variables["html_loaded"] = False
                print("[Coordinate] HTML加载失败")
                return ReplyResult(
                    message="HTML加载失败，请检查URL和Cookie",
                    context_variables=context_variables
                )
            
            # 2. 加载基准清单
            print(f"[Coordinate] 加载基准清单: {workflow.baseline_list_path}")
            baseline_list = workflow._load_baseline_list(workflow.baseline_list_path)
            
            if baseline_list:
                workflow.baseline_indicator_list = baseline_list
                context_variables["baseline_loaded"] = True
                context_variables["baseline_count"] = len(baseline_list.indicators)
                print(f"[Coordinate] 基准清单加载成功，共 {len(baseline_list.indicators)} 个指标")
            else:
                context_variables["baseline_loaded"] = False
                print("[Coordinate] 基准清单加载失败")
                return ReplyResult(
                    message="基准清单加载失败，请检查文件路径",
                    context_variables=context_variables
                )
            
            context_variables["initialized"] = True
            return ReplyResult(
                message="初始化完成，请路由到 html_extractor_agent 开始提取指标",
                context_variables=context_variables,
                target=AgentTarget(workflow.html_extractor_agent)
            )
        
        def go_extractor(message: str = "", comparison_results: str = "") -> ReplyResult:
            """路由到HTML提取Agent"""
            context_variables = ContextVariables()
            context_variables["html_content_preview"] = workflow.html_content[:3000] if workflow.html_content else ""
            
            # 如果没有显式传入comparison_results，尝试从message中提取
            if not comparison_results and message:
                # 尝试从message中提取JSON格式的对比结果
                json_match = re.search(r'\{[\s\S]*"compared_indicators"[\s\S]*\}', message)
                if json_match:
                    comparison_results = json_match.group()
            
            # 如果有对比结果，放入context_variables
            if comparison_results:
                try:
                    # 尝试解析JSON
                    results = json.loads(comparison_results) if isinstance(comparison_results, str) else comparison_results
                    context_variables["comparison_results"] = json.dumps(results, ensure_ascii=False) if isinstance(results, dict) else comparison_results
                    context_variables["has_comparison_results"] = True
                    print(f"[Coordinate] 提取到对比结果，包含 {len(results.get('compared_indicators', []))} 个指标")
                except Exception as e:
                    # 如果不是JSON，直接放入
                    context_variables["comparison_results"] = comparison_results
                    context_variables["has_comparison_results"] = True
                    print(f"[Coordinate] 对比结果格式异常: {e}")
            
            return ReplyResult(
                message=f"route->html_extractor: {message}",
                context_variables=context_variables,
                target=AgentTarget(workflow.html_extractor_agent)
            )
        
        def go_comparator(indicators_to_compare: str = "") -> ReplyResult:
            """路由到指标对比Agent"""
            context_variables = ContextVariables()
            context_variables["indicators_to_compare"] = indicators_to_compare
            if workflow.baseline_indicator_list:
                context_variables["baseline_indicators"] = json.dumps(
                    [i.to_dict() for i in workflow.baseline_indicator_list.indicators],
                    ensure_ascii=False
                )
            return ReplyResult(
                message=f"route->comparator: {indicators_to_compare}",
                context_variables=context_variables,
                target=AgentTarget(workflow.indicator_comparator_agent)
            )
        
        def go_analyzer() -> ReplyResult:
            """路由到差异分析Agent"""
            context_variables = ContextVariables()
            if workflow.current_indicator_list:
                context_variables["full_indicator_list"] = json.dumps(
                    workflow.current_indicator_list.to_dict(),
                    ensure_ascii=False
                )
            return ReplyResult(
                message="route->analyzer: 开始深度分析",
                context_variables=context_variables,
                target=AgentTarget(workflow.difference_analyzer_agent)
            )
        
        def go_alert() -> ReplyResult:
            """路由到预警Agent"""
            context_variables = ContextVariables()
            return ReplyResult(
                message="route->alert: 生成预警",
                context_variables=context_variables,
                target=AgentTarget(workflow.alert_agent)
            )
        
        def go_report() -> ReplyResult:
            """路由到汇报Agent"""
            context_variables = ContextVariables()
            context_variables["workflow_finished"] = True
            return ReplyResult(
                message="route->report: 生成报告",
                context_variables=context_variables,
                target=AgentTarget(workflow.report_agent)
            )
        
        return [initialize_workflow, go_extractor, go_comparator, go_analyzer, go_alert, go_report]
    
    def _create_extractor_functions(self):
        """创建提取Agent的函数"""
        workflow = self
        
        def extract_indicators_from_html() -> ReplyResult:
            """从HTML提取指标（使用AI解析）"""
            context_variables = ContextVariables()
            
            print("[Extractor] 开始从HTML提取指标（AI模式）...")
            
            # 使用LLM提取指标
            indicators = workflow._extract_indicators_with_llm(workflow.html_content)
            
            # 创建指标清单
            workflow.current_indicator_list = IndicatorList(
                indicators=indicators,
                source=workflow.html_url
            )
            
            context_variables["extracted_count"] = len(indicators)
            context_variables["indicator_list_initialized"] = True
            
            # 同步到workflow实例
            workflow.context_variables["extracted_count"] = len(indicators)
            workflow.context_variables["indicator_list_initialized"] = True
            workflow.context_variables["current_indicator_list"] = workflow.current_indicator_list.to_dict()
            
            print(f"[Extractor] AI提取完成，共 {len(indicators)} 个指标")
            
            # 返回提取结果
            indicator_summary = [
                {"name": i.name, "value": i.value, "indicator_type": i.indicator_type, "unit": i.unit}
                for i in indicators[:15]  # 显示前15个
            ]
            
            return ReplyResult(
                message=f"AI提取完成，共 {len(indicators)} 个指标。\n\n前15个指标：\n{json.dumps(indicator_summary, ensure_ascii=False, indent=2)}",
                context_variables=context_variables
            )
        
        def get_pending_indicators(batch_size: int = 10) -> ReplyResult:
            """获取待对比的指标"""
            context_variables = ContextVariables()
            
            if not workflow.current_indicator_list:
                return ReplyResult(
                    message="错误：指标清单未初始化",
                    context_variables=context_variables
                )
            
            pending = workflow.current_indicator_list.get_pending_indicators(batch_size)
            stats = workflow.current_indicator_list.get_statistics()
            
            context_variables["pending_count"] = len(pending)
            context_variables["progress"] = stats["progress"]
            
            # 同步到workflow实例
            workflow.context_variables["pending_count"] = len(pending)
            workflow.context_variables["progress"] = stats["progress"]
            
            if not pending:
                context_variables["all_compared"] = True
                workflow.context_variables["all_compared"] = True
                return ReplyResult(
                    message=f"所有指标已对比完成！{stats}",
                    context_variables=context_variables
                )
            
            pending_data = [i.to_dict() for i in pending]
            context_variables["indicators_to_compare"] = json.dumps(pending_data, ensure_ascii=False)
            workflow.context_variables["indicators_to_compare"] = pending_data
            
            return ReplyResult(
                message=f"待对比指标（{len(pending)}个）：{json.dumps(pending_data, ensure_ascii=False)}\n进度：{stats['progress']}",
                context_variables=context_variables
            )
        
        def update_indicator_status(comparison_results: str) -> ReplyResult:
            """更新指标状态"""
            context_variables = ContextVariables()
            
            try:
                results = json.loads(comparison_results)
                updated_count = 0
                
                for item in results.get("compared_indicators", []):
                    indicator_id = item.get("indicator_id")
                    status = item.get("status", "compared")
                    difference = item.get("difference")
                    
                    workflow.current_indicator_list.update_indicator_status(
                        indicator_id, status, difference
                    )
                    updated_count += 1
                
                stats = workflow.current_indicator_list.get_statistics()
                context_variables["updated_count"] = updated_count
                context_variables["progress"] = stats["progress"]
                context_variables["all_compared"] = workflow.current_indicator_list.all_compared()
                
                # 同步到workflow实例
                workflow.context_variables["updated_count"] = updated_count
                workflow.context_variables["progress"] = stats["progress"]
                workflow.context_variables["all_compared"] = workflow.current_indicator_list.all_compared()
                
                if context_variables["all_compared"]:
                    print(f"[Extractor] 所有指标对比完成！")
                    return ReplyResult(
                        message=f"NEXT_ACTION: ALL_COMPARED\n统计：{stats}",
                        context_variables=context_variables
                    )
                
                return ReplyResult(
                    message=f"已更新 {updated_count} 个指标，进度：{stats['progress']}",
                    context_variables=context_variables
                )
                
            except Exception as e:
                print(f"[Extractor] 更新状态失败: {e}")
                return ReplyResult(
                    message=f"更新失败: {e}",
                    context_variables=context_variables
                )
        
        def request_comparison() -> ReplyResult:
            """请求对比 - 自动获取待对比指标并路由到comparator"""
            context_variables = ContextVariables()
            
            # 获取待对比指标
            if not workflow.current_indicator_list:
                return ReplyResult(
                    message="错误：指标清单未初始化",
                    context_variables=context_variables
                )
            
            pending = workflow.current_indicator_list.get_pending_indicators(10)
            if not pending:
                context_variables["all_compared"] = True
                return ReplyResult(
                    message="NEXT_ACTION: ALL_COMPARED - 所有指标已对比完成",
                    context_variables=context_variables
                )
            
            # 将待对比指标转为JSON
            pending_json = json.dumps([i.to_dict() for i in pending], ensure_ascii=False)
            
            context_variables["requesting_comparison"] = True
            context_variables["indicators_to_compare"] = pending_json
            workflow.context_variables["requesting_comparison"] = True
            workflow.context_variables["indicators_to_compare"] = pending_json
            
            # 直接路由到comparator，不经过coordinate_agent
            return ReplyResult(
                message=f"REQUEST_COMPARISON: {pending_json}",
                context_variables=context_variables,
                target=AgentTarget(workflow.indicator_comparator_agent)
            )
        
        return [extract_indicators_from_html, get_pending_indicators, update_indicator_status, request_comparison]
    
    def _create_comparator_functions(self):
        """创建对比Agent的函数"""
        workflow = self
        
        def compare_indicators(indicators_json: str) -> ReplyResult:
            """对比指标"""
            context_variables = ContextVariables()
            
            try:
                current_indicators = json.loads(indicators_json)
                baseline_indicators = workflow.baseline_indicator_list.indicators if workflow.baseline_indicator_list else []
                
                # 构建基准指标字典（按名称索引，用于降级匹配）
                baseline_dict = {}
                for bi in baseline_indicators:
                    name_normalized = bi.name.strip().lower()
                    baseline_dict[name_normalized] = bi
                
                # 对比结果
                compared_results = []
                
                for ci in current_indicators:
                    ci_name = ci.get("name", "")
                    ci_name_normalized = ci_name.strip().lower()
                    ci_value = ci.get("value", "")
                    
                    result = {
                        "indicator_id": ci.get("indicator_id"),
                        "name": ci_name,
                        "current_value": ci_value,
                        "status": "compared",
                        "difference": None,
                        "match_method": None,
                        "match_confidence": None
                    }
                    
                    # 策略1: 使用AI语义匹配
                    matched_result = workflow._find_best_match_with_llm(ci_name, baseline_indicators)
                    
                    if matched_result:
                        bi, confidence = matched_result
                        result["match_method"] = "ai_semantic"
                        result["match_confidence"] = confidence
                    else:
                        # 策略2: 降级到字符串完全匹配
                        if ci_name_normalized in baseline_dict:
                            bi = baseline_dict[ci_name_normalized]
                            result["match_method"] = "exact_string"
                            result["match_confidence"] = 1.0
                        else:
                            bi = None
                    
                    # 如果找到匹配的基准指标
                    if bi:
                        
                        # 计算差异
                        try:
                            current_num = float(str(ci_value).replace(",", "").replace("%", ""))
                            baseline_num = float(str(bi.value).replace(",", "").replace("%", ""))
                            
                            abs_diff = current_num - baseline_num
                            if baseline_num != 0:
                                rel_diff = abs_diff / baseline_num
                                pct_diff = rel_diff * 100
                            else:
                                rel_diff = 0
                                pct_diff = 0
                            
                            has_diff = abs(pct_diff) > 0.01
                            threshold_exceeded = abs(pct_diff) > 5
                            
                            if abs(pct_diff) >= 15:
                                risk_level = "high"
                            elif abs(pct_diff) >= 5:
                                risk_level = "medium"
                            else:
                                risk_level = "low"
                            
                            result["difference"] = {
                                "baseline_value": bi.value,
                                "current_value": ci_value,
                                "absolute_diff": round(abs_diff, 2),
                                "relative_diff": round(rel_diff, 4),
                                "percentage_diff": round(pct_diff, 2),
                                "has_difference": has_diff,
                                "threshold_exceeded": threshold_exceeded,
                                "risk_level": risk_level
                            }
                        except (ValueError, TypeError):
                            # 非数值比较
                            has_diff = str(ci_value) != str(bi.value)
                            result["difference"] = {
                                "baseline_value": bi.value,
                                "current_value": ci_value,
                                "has_difference": has_diff,
                                "comparison_type": "text"
                            }
                    else:
                        # 未找到匹配的基准指标
                        result["match_method"] = "not_found"
                        result["match_confidence"] = 0.0
                        result["difference"] = {
                            "has_difference": True,
                            "message": "基准清单中未找到语义相似的指标"
                        }
                    
                    compared_results.append(result)
                
                comparison_output = {
                    "compared_indicators": compared_results,
                    "compared_count": len(compared_results)
                }
                
                comparison_json = json.dumps(comparison_output, ensure_ascii=False)
                context_variables["comparison_result"] = comparison_json
                context_variables["comparison_results"] = comparison_json  # 供html_extractor_agent识别
                
                # 同步到workflow实例
                workflow.context_variables["comparison_result"] = comparison_output
                workflow.context_variables["last_compared_count"] = len(compared_results)
                
                print(f"[Comparator] 对比完成，共 {len(compared_results)} 个指标，直接返回给html_extractor_agent")
                
                # 直接路由回html_extractor_agent
                return ReplyResult(
                    message=f"COMPARISON_RESULTS: {comparison_json}",
                    context_variables=context_variables,
                    target=AgentTarget(workflow.html_extractor_agent)
                )
                
            except Exception as e:
                print(f"[Comparator] 对比失败: {e}")
                return ReplyResult(
                    message=f"对比失败: {e}",
                    context_variables=context_variables
                )
        
        return [compare_indicators]
    
    def _find_best_match_with_llm(self, current_name: str, baseline_indicators: List[Indicator]) -> Optional[Tuple[Indicator, float]]:
        """使用AI找到语义最相似的基准指标
        
        Returns:
            Tuple[Indicator, confidence_score] 或 None
            confidence_score: 0-1之间的相似度分数
        """
        if not baseline_indicators:
            return None
        
        print(f"[Comparator] 使用AI匹配指标: {current_name}")
        
        # 构建基准指标列表（名称和值）
        baseline_list = []
        for i, bi in enumerate(baseline_indicators):
            baseline_list.append({
                "index": i,
                "name": bi.name,
                "value": bi.value,
                "type": bi.indicator_type
            })
        
        # 构建匹配prompt
        match_prompt = f"""你是一个指标匹配专家。请从基准指标清单中找到与当前指标语义最相似的指标。

## 当前指标
名称: {current_name}

## 基准指标清单
{json.dumps(baseline_list, ensure_ascii=False, indent=2)}

## 匹配要求
1. **理解指标名称的语义含义**，不要只看字面匹配
2. **忽略括号内的说明**（如"线上+线下"、"同比"、"环比"等修饰词）
3. **识别同义词**：
   - "互联网" ≈ "在线" ≈ "线上"
   - "完成" ≈ "人次"（在特定上下文中）
   - "门诊人次" = "门诊人次(线上+线下)"（忽略括号内容）
4. **找到最相似的基准指标**，并给出相似度分数（0-1）

## 输出格式（JSON）
```json
{{
    "matched_index": 0,
    "matched_name": "门诊人次",
    "confidence": 0.95,
    "reason": "当前指标'门诊人次(线上+线下)'与基准指标'门诊人次'语义相同，括号内容只是说明"
}}
```

如果没有匹配的（相似度<0.6），返回：
```json
{{
    "matched_index": null,
    "matched_name": null,
    "confidence": 0.0,
    "reason": "未找到语义相似的指标"
}}
```

只输出JSON，不要有其他文字。
"""
        
        try:
            # 获取LLM配置
            config = load_config()
            model_config = config.get_model("data_extraction")
            
            # 创建OpenAI客户端
            client = OpenAI(
                api_key=model_config.api_key,
                base_url=model_config.base_url
            )
            
            # 调用LLM
            response = client.chat.completions.create(
                model=model_config.model,
                messages=[
                    {"role": "system", "content": "你是一个专业的指标匹配专家，擅长理解医疗指标的语义含义。"},
                    {"role": "user", "content": match_prompt}
                ],
                temperature=0.1,
                max_tokens=2000
            )
            
            # 解析响应
            result_text = response.choices[0].message.content.strip()
            
            # 提取JSON
            json_match = re.search(r'\{[\s\S]*\}', result_text)
            if json_match:
                json_str = json_match.group()
                match_result = json.loads(json_str)
            else:
                match_result = json.loads(result_text)
            
            matched_index = match_result.get("matched_index")
            confidence = match_result.get("confidence", 0.0)
            
            # 如果相似度太低，返回None
            if matched_index is None or confidence < 0.6:
                print(f"[Comparator] 未找到匹配（相似度: {confidence:.2f}）")
                return None
            
            # 返回匹配的指标和相似度
            matched_indicator = baseline_indicators[matched_index]
            print(f"[Comparator] 匹配成功: {current_name} → {matched_indicator.name} (相似度: {confidence:.2f})")
            
            return (matched_indicator, confidence)
            
        except Exception as e:
            print(f"[Comparator] AI匹配失败: {e}，降级到字符串匹配")
            import traceback
            traceback.print_exc()
            return None
    
    def _create_analyzer_functions(self):
        """创建分析Agent的函数"""
        workflow = self
        
        def analyze_differences() -> ReplyResult:
            """分析差异"""
            context_variables = ContextVariables()
            
            if not workflow.current_indicator_list:
                return ReplyResult(
                    message="错误：指标清单未初始化",
                    context_variables=context_variables
                )
            
            indicators = workflow.current_indicator_list.indicators
            stats = workflow.current_indicator_list.get_statistics()
            
            # 统计分析
            high_risk = []
            medium_risk = []
            low_risk = []
            
            for ind in indicators:
                if ind.difference:
                    risk = ind.difference.get("risk_level", "low")
                    if risk == "high":
                        high_risk.append(ind)
                    elif risk == "medium":
                        medium_risk.append(ind)
                    else:
                        low_risk.append(ind)
            
            analysis_result = {
                "summary": {
                    "total_indicators": stats["total"],
                    "with_difference": stats["with_difference"],
                    "high_risk_count": len(high_risk),
                    "medium_risk_count": len(medium_risk),
                    "low_risk_count": len(low_risk)
                },
                "high_risk_indicators": [
                    {"name": i.name, "value": i.value, "difference": i.difference}
                    for i in high_risk
                ],
                "medium_risk_indicators": [
                    {"name": i.name, "value": i.value, "difference": i.difference}
                    for i in medium_risk[:5]  # 只取前5个
                ],
                "recommendations": []
            }
            
            # 添加建议
            if len(high_risk) > 0:
                analysis_result["recommendations"].append("存在高风险差异指标，需立即核查")
            if len(medium_risk) > 5:
                analysis_result["recommendations"].append("中风险差异指标较多，建议系统性审查")
            
            context_variables["analysis_result"] = json.dumps(analysis_result, ensure_ascii=False)
            workflow.context_variables["analysis_result"] = analysis_result
            
            return ReplyResult(
                message=json.dumps(analysis_result, ensure_ascii=False, indent=2),
                context_variables=context_variables
            )
        
        return [analyze_differences]
    
    def _create_alert_functions(self):
        """创建预警Agent的函数"""
        workflow = self
        
        def generate_alerts() -> ReplyResult:
            """生成预警"""
            context_variables = ContextVariables()
            
            analysis = workflow.context_variables.get("analysis_result", {})
            
            alerts = []
            
            # 高风险预警
            for item in analysis.get("high_risk_indicators", []):
                diff = item.get("difference", {})
                alerts.append({
                    "level": "high",
                    "indicator_name": item.get("name"),
                    "current_value": item.get("value"),
                    "baseline_value": diff.get("baseline_value"),
                    "difference_percentage": diff.get("percentage_diff"),
                    "message": f"指标 {item.get('name')} 差异超过15%，需立即核查"
                })
            
            # 中风险预警
            for item in analysis.get("medium_risk_indicators", []):
                diff = item.get("difference", {})
                alerts.append({
                    "level": "medium",
                    "indicator_name": item.get("name"),
                    "current_value": item.get("value"),
                    "baseline_value": diff.get("baseline_value"),
                    "difference_percentage": diff.get("percentage_diff"),
                    "message": f"指标 {item.get('name')} 存在中等差异，需关注"
                })
            
            alert_result = {
                "check_time": datetime.now().isoformat(),
                "source_url": workflow.html_url,
                "baseline_file": workflow.baseline_list_path,
                "summary": analysis.get("summary", {}),
                "alerts": alerts,
                "total_alerts": len(alerts)
            }
            
            context_variables["alert_result"] = json.dumps(alert_result, ensure_ascii=False)
            workflow.context_variables["alert_result"] = alert_result
            
            return ReplyResult(
                message=f"生成 {len(alerts)} 条预警",
                context_variables=context_variables
            )
        
        def write_alert_json() -> ReplyResult:
            """写入预警JSON文件"""
            context_variables = ContextVariables()
            
            alert_result = workflow.context_variables.get("alert_result", {})
            output_file = workflow.output_dir / "indicator_check_result.json"
            
            try:
                with open(output_file, 'w', encoding='utf-8') as f:
                    json.dump(alert_result, f, ensure_ascii=False, indent=2)
                
                context_variables["alert_file"] = str(output_file)
                print(f"[Alert] 预警结果已保存: {output_file}")
                
                return ReplyResult(
                    message=f"预警已保存到: {output_file}",
                    context_variables=context_variables
                )
            except Exception as e:
                return ReplyResult(
                    message=f"写入失败: {e}",
                    context_variables=context_variables
                )
        
        return [generate_alerts, write_alert_json]
    
    def _create_report_functions(self):
        """创建汇报Agent的函数"""
        workflow = self
        
        def generate_report() -> ReplyResult:
            """生成报告"""
            context_variables = ContextVariables()
            
            analysis = workflow.context_variables.get("analysis_result", {})
            alert = workflow.context_variables.get("alert_result", {})
            stats = analysis.get("summary", {})
            
            report = f"""
## 指标核查报告

### 执行概要
- 检查时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
- 数据来源: {workflow.html_url[:50]}...
- 基准清单: {workflow.baseline_list_path}

### 核查结果
- 提取指标总数: {stats.get('total_indicators', 0)}
- 存在差异: {stats.get('with_difference', 0)} 个

### 预警汇总
- 🔴 高风险: {stats.get('high_risk_count', 0)} 个
- 🟡 中风险: {stats.get('medium_risk_count', 0)} 个  
- 🟢 低风险: {stats.get('low_risk_count', 0)} 个

### 关键发现
"""
            high_risk = analysis.get("high_risk_indicators", [])
            if high_risk:
                report += "高风险指标:\n"
                for item in high_risk[:3]:
                    diff = item.get("difference", {})
                    report += f"- {item.get('name')}: 差异 {diff.get('percentage_diff', 0):.1f}%\n"
            else:
                report += "无高风险指标\n"
            
            report += "\n### 建议措施\n"
            for rec in analysis.get("recommendations", ["暂无特殊建议"]):
                report += f"- {rec}\n"
            
            context_variables["report_content"] = report
            
            return ReplyResult(
                message=report,
                context_variables=context_variables
            )
        
        def finish_workflow() -> ReplyResult:
            """完成工作流"""
            context_variables = ContextVariables()
            context_variables["workflow_finished"] = True
            
            print("[Report] 工作流执行完成")
            
            return ReplyResult(
                message="workflow_finished=True",
                context_variables=context_variables
            )
        
        return [generate_report, finish_workflow]
    
    # ==================== Helper Methods ====================
    
    def _load_baseline_list(self, file_path: str) -> Optional[IndicatorList]:
        """加载基准指标清单（text格式）"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            indicators = []
            lines = content.strip().split('\n')
            
            # 跳过标题行
            data_lines = lines[1:] if lines else []
            
            for i, line in enumerate(data_lines):
                if not line.strip():
                    continue
                
                parts = line.split(',')
                if len(parts) >= 2:
                    name = parts[0].strip()
                    value = parts[1].strip()
                    ind_type = parts[2].strip() if len(parts) > 2 else ""
                    unit = parts[3].strip() if len(parts) > 3 else ""
                    time_range = parts[4].strip() if len(parts) > 4 else ""
                    
                    indicator = Indicator(
                        indicator_id=f"BASE_{i:03d}",
                        name=name,
                        value=value,
                        indicator_type=ind_type,
                        unit=unit,
                        time_range=time_range,
                        status="baseline"
                    )
                    indicators.append(indicator)
            
            return IndicatorList(
                indicators=indicators,
                source=file_path
            )
            
        except Exception as e:
            print(f"[Error] 加载基准清单失败: {e}")
            return None
    
    def _extract_indicators_with_llm(self, html_content: str) -> List[Indicator]:
        """使用LLM从HTML提取指标"""
        from bs4 import BeautifulSoup
        
        print("[Extractor] 使用AI解析HTML提取指标...")
        
        # 简化HTML：移除脚本、样式，只保留文本内容
        soup = BeautifulSoup(html_content, 'html.parser')
        
        # 移除script和style标签
        for tag in soup(['script', 'style', 'meta', 'link', 'noscript']):
            tag.decompose()
        
        # 提取文本内容，保留结构
        text_content = soup.get_text(separator='\n', strip=True)
        
        # 截取前60000字符避免超长
        if len(text_content) > 60000:
            text_content = text_content[:60000] + "\n...(内容已截断)"
        
        print(f"[Extractor] 简化后文本长度: {len(text_content)} 字符")
        
        # 构建提取指标的prompt
        extraction_prompt = f"""你是一个专业的数据提取专家。请从以下BI报表HTML内容中提取所有指标数据。

## 提取要求
1. 识别所有数值型指标（门诊人次、住院人次、费用、比例等）
2. 提取指标名称和对应的数值
3. 识别指标的类型（门诊指标、住院指标、费用指标等）
4. 识别数值的单位（人次、元、天、%等）

## 输出格式
请以JSON数组格式输出，每个指标包含以下字段：
- name: 指标名称（必填）
- value: 指标数值（必填，保持原始格式）
- indicator_type: 指标类型（门诊指标/住院指标/费用指标/其他）
- unit: 单位（人次/元/天/%等）

## 示例输出
```json
[
    {{"name": "门诊人次", "value": "838723", "indicator_type": "门诊指标", "unit": "人次"}},
    {{"name": "出院人次", "value": "23443", "indicator_type": "住院指标", "unit": "人次"}},
    {{"name": "平均住院日", "value": "6.32", "indicator_type": "住院指标", "unit": "天"}}
]
```

## 注意事项
1. 只提取有明确数值的指标，不要提取标题、说明等非数据内容
2. 忽略"查询"、"开始月份"、"结束月份"等操作按钮
3. 如果同一指标有多个数值（如同比、环比），分别提取
4. 保持数值的原始格式（包括逗号、百分号等）

## HTML内容
{text_content}

请只输出JSON数组，不要有其他文字说明。
"""
        
        try:
            # 获取LLM配置
            config = load_config()
            model_config = config.get_model("data_extraction")
            
            # 创建OpenAI客户端
            client = OpenAI(
                api_key=model_config.api_key,
                base_url=model_config.base_url
            )
            
            print(f"[Extractor] 调用LLM: {model_config.model}")
            
            # 调用LLM
            response = client.chat.completions.create(
                model=model_config.model,
                messages=[
                    {"role": "system", "content": "你是一个专业的数据提取专家，擅长从HTML中提取结构化数据。"},
                    {"role": "user", "content": extraction_prompt}
                ],
                temperature=0.1,
                max_tokens=8000
            )
            
            # 解析响应
            result_text = response.choices[0].message.content.strip()
            print(f"[Extractor] LLM响应长度: {len(result_text)} 字符")
            
            # 提取JSON部分
            json_match = re.search(r'\[[\s\S]*\]', result_text)
            if json_match:
                json_str = json_match.group()
                extracted_data = json.loads(json_str)
            else:
                print(f"[Extractor] 未找到JSON数组，尝试直接解析")
                extracted_data = json.loads(result_text)
            
            # 转换为Indicator对象
            indicators = []
            for i, item in enumerate(extracted_data):
                if isinstance(item, dict) and 'name' in item and 'value' in item:
                    ind = Indicator(
                        indicator_id=f"IND_{i:03d}",
                        name=item.get('name', ''),
                        value=str(item.get('value', '')),
                        indicator_type=item.get('indicator_type', ''),
                        unit=item.get('unit', '')
                    )
                    indicators.append(ind)
            
            print(f"[Extractor] AI提取完成，共 {len(indicators)} 个指标")
            
            # 打印前10个指标
            for ind in indicators[:10]:
                print(f"  - {ind.name}: {ind.value} ({ind.indicator_type})")
            if len(indicators) > 10:
                print(f"  ... 还有 {len(indicators) - 10} 个指标")
            
            return indicators
            
        except Exception as e:
            print(f"[Extractor] LLM提取失败: {e}")
            import traceback
            traceback.print_exc()
            # 降级到规则解析
            print("[Extractor] 降级到规则解析...")
            return self._parse_html_indicators(html_content)
    
    def _parse_html_indicators(self, html_content: str) -> List[Indicator]:
        """从HTML解析指标"""
        from bs4 import BeautifulSoup
        
        indicators = []
        soup = BeautifulSoup(html_content, 'html.parser')
        
        print(f"[Extractor] HTML内容长度: {len(html_content)} 字符")
        
        # 策略1: 查找表格
        tables = soup.find_all('table')
        print(f"[Extractor] 发现 {len(tables)} 个表格")
        for table in tables:
            rows = table.find_all('tr')
            for i, row in enumerate(rows):
                cells = row.find_all(['td', 'th'])
                if len(cells) >= 2:
                    name = cells[0].get_text(strip=True)
                    value = cells[1].get_text(strip=True)
                    
                    if name and value and self._looks_like_indicator(name, value):
                        indicator = Indicator(
                            indicator_id=f"IND_{len(indicators):03d}",
                            name=name,
                            value=value
                        )
                        indicators.append(indicator)
        
        # 策略2: 查找绝对定位的div（BI报表常见结构）
        divs_with_pos = soup.find_all('div', style=re.compile(r'position.*absolute'))
        print(f"[Extractor] 发现 {len(divs_with_pos)} 个绝对定位div")
        
        if divs_with_pos:
            # 按top位置分组
            groups = {}
            for div in divs_with_pos:
                style = div.get('style', '')
                top_match = re.search(r'top:\s*(\d+)', style)
                left_match = re.search(r'left:\s*(\d+)', style)
                
                if top_match:
                    top = int(top_match.group(1))
                    left = int(left_match.group(1)) if left_match else 0
                    content = div.get_text(strip=True)
                    
                    # 过滤掉太长的内容（可能是标题或说明）
                    if content and len(content) < 200 and content not in ['查询', '开始月份', '结束月份']:
                        if top not in groups:
                            groups[top] = []
                        groups[top].append((left, content))
            
            # 处理每一行，尝试配对指标名和值
            for top, items in sorted(groups.items()):
                if len(items) < 2:
                    continue
                
                # 按left位置排序
                items_sorted = sorted(items, key=lambda x: x[0])
                texts = [item[1] for item in items_sorted]
                
                # 尝试识别指标名和值
                # 通常指标名在左，数值在右
                for i in range(len(texts) - 1):
                    name_candidate = texts[i]
                    value_candidate = texts[i + 1]
                    
                    # 跳过明显不是指标名的内容
                    if (not re.search(r'[\u4e00-\u9fa5]', name_candidate) or 
                        len(name_candidate) < 2 or len(name_candidate) > 50 or
                        re.match(r'^\d+\.?\d*$', name_candidate) or  # 纯数字
                        name_candidate in ['查询', '开始月份', '结束月份', '重置', '导出']):
                        continue
                    
                    # 检查值是否像数值
                    if not re.search(r'\d', value_candidate):
                        continue
                    
                    # 清理数值（移除逗号、空格等）
                    value_clean = re.sub(r'[,\s]', '', value_candidate)
                    
                    # 如果值看起来像序号（1.1, 2.2等），跳过
                    if re.match(r'^\d+\.\d+$', value_clean) and float(value_clean) < 10:
                        continue
                    
                    if self._looks_like_indicator(name_candidate, value_clean):
                        indicator = Indicator(
                            indicator_id=f"IND_{len(indicators):03d}",
                            name=name_candidate,
                            value=value_clean
                        )
                        indicators.append(indicator)
        
        # 策略3: 查找key-value结构（文本模式）
        divs = soup.find_all('div')
        for div in divs:
            text = div.get_text(strip=True)
            # 匹配 "指标名：数值" 或 "指标名: 数值" 模式
            match = re.match(r'(.+?)[：:]\s*([0-9,.%]+)', text)
            if match:
                name = match.group(1).strip()
                value = match.group(2).strip()
                
                if name and value and len(name) < 50:
                    indicator = Indicator(
                        indicator_id=f"IND_{len(indicators):03d}",
                        name=name,
                        value=value
                    )
                    indicators.append(indicator)
        
        # 策略4: 查找包含数字的span或div，尝试与相邻文本配对
        spans = soup.find_all(['span', 'div'])
        for elem in spans:
            text = elem.get_text(strip=True)
            # 如果包含数字，可能是指标值
            if re.search(r'^\d+[.,\d]*%?$', text) or re.search(r'^\d+[.,\d]+$', text):
                # 查找父元素或前一个兄弟元素中的文本作为指标名
                parent = elem.parent
                if parent:
                    parent_text = parent.get_text(strip=True)
                    # 尝试提取指标名（在数值之前的部分）
                    parts = parent_text.split(text)
                    if len(parts) > 0:
                        name_part = parts[0].strip()
                        # 清理名称（移除冒号、空格等）
                        name_part = re.sub(r'[：:\s]+$', '', name_part)
                        if name_part and len(name_part) < 50 and re.search(r'[\u4e00-\u9fa5]', name_part):
                            value_clean = re.sub(r'[,\s]', '', text)
                            if self._looks_like_indicator(name_part, value_clean):
                                indicator = Indicator(
                                    indicator_id=f"IND_{len(indicators):03d}",
                                    name=name_part,
                                    value=value_clean
                                )
                                indicators.append(indicator)
        
        # 去重
        seen = set()
        unique_indicators = []
        for ind in indicators:
            key = f"{ind.name}|{ind.value}"
            if key not in seen:
                seen.add(key)
                unique_indicators.append(ind)
        
        print(f"[Extractor] 最终提取 {len(unique_indicators)} 个唯一指标")
        return unique_indicators
    
    def _looks_like_indicator(self, name: str, value: str) -> bool:
        """判断是否像一个指标"""
        # 名称长度合理
        if len(name) < 2 or len(name) > 100:
            return False
        
        # 排除明显的非指标文本
        exclude_keywords = ['查询', '开始月份', '结束月份', '四川大学', '科室', '医院', 
                           '查询', '重置', '导出', '打印', '刷新', '设置']
        if any(kw in name for kw in exclude_keywords):
            return False
        
        # 值包含数字
        if not re.search(r'\d', value):
            return False
        
        # 值应该是数字格式（可能包含小数点、百分号、逗号）
        value_clean = re.sub(r'[,\s%]', '', value)
        try:
            float(value_clean)
        except ValueError:
            return False
        
        return True
    
    # ==================== Public API ====================
    
    def run(self, task: str = "") -> Dict:
        """运行指标核查工作流"""
        print("\n" + "=" * 60)
        print("[Workflow] 开始指标核查工作流")
        print(f"  HTML URL: {self.html_url[:60]}...")
        print(f"  基准清单: {self.baseline_list_path}")
        print("=" * 60)
        
        # 创建user agent
        user = UserProxyAgent(
            name="user",
            llm_config=False,
            code_execution_config=False,
            is_termination_msg=lambda m: "workflow_finished" in str(m.get("content", ""))
        )
        
        # 初始化任务
        seed = f"""
开始指标核查工作流：

1. HTML页面URL: {self.html_url}
2. 基准指标清单: {self.baseline_list_path}

请 coordinate_agent 调用 initialize_workflow() 开始初始化。
"""
        
        pattern = DefaultPattern(
            initial_agent=self.coordinate_agent,
            agents=self.agents,
            context_variables=self.context_variables,
            user_agent=user,
        )
        
        chat_result, final_context, last_agent = initiate_group_chat(
            pattern=pattern,
            messages=seed,
            max_rounds=1000
        )
        
        print("\n" + "=" * 60)
        print("[Workflow] 指标核查工作流完成")
        print("=" * 60)
        
        return {
            "success": final_context.get("workflow_finished", False),
            "report": final_context.get("report_content", ""),
            "alert_file": final_context.get("alert_file", ""),
            "statistics": self.current_indicator_list.get_statistics() if self.current_indicator_list else {}
        }


def main():
    """主函数示例"""
    import sys
    
    # 解析命令行参数
    if len(sys.argv) < 3:
        print("用法: python workflow_indicator_verification.py <html_url> <baseline_list_path>")
        print("")
        print("参数:")
        print("  html_url           - BI报表页面URL或db路径")
        print("  baseline_list_path - 基准指标清单文件路径（text格式）")
        print("")
        print("示例:")
        print('  python workflow_indicator_verification.py "https://..." "baseline.txt"')
        return
    
    html_url = sys.argv[1]
    baseline_list_path = sys.argv[2]
    
    # 创建工作流
    workflow = IndicatorVerificationWorkflow(
        html_url=html_url,
        baseline_list_path=baseline_list_path,
        output_dir="."
    )
    
    # 运行
    result = workflow.run()
    
    print("\n=== 执行结果 ===")
    print(f"成功: {result['success']}")
    print(f"报告:\n{result['report']}")
    print(f"预警文件: {result['alert_file']}")
    print(f"统计: {result['statistics']}")


if __name__ == "__main__":
    main()
