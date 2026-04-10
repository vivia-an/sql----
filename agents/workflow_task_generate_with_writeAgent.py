#!/usr/bin/env python3
"""
Self-reasoning workflow with write-back agent.
Routing: megatron_expert -> coordinate_agent -> write_agent -> JSON file
"""

import json
import copy
from typing import Any, Tuple, Dict, Optional
from datetime import datetime

from autogen.agentchat import initiate_group_chat
from autogen.agentchat.group.patterns import DefaultPattern
from autogen import ConversableAgent, UserProxyAgent
from autogen.agentchat.group import (
    ReplyResult,
    ContextVariables,
    AgentTarget,
)
from context_variables import WorkflowContext
from llm_config import get_llm_config
from chinese_generator_no_unicode import ChineseConstraintGeneratorNoUnicode


def _safe_parse(payload: Any) -> Any:
    if isinstance(payload, str):
        try:
            return json.loads(payload)
        except Exception:
            return payload
    return payload


class WorkflowTaskGenerateWithWriteAgent:
    """
    Self-reasoning workflow with write-back agent.
    Routing: megatron_expert validates constraint -> coordinate_agent -> write_agent -> JSON file
    """

    def __init__(self, context_variables: ContextVariables | None = None, constraints_file_path: str = None, max_iterations: int = 100):
        self.context_variables = ContextVariables(WorkflowContext().model_dump()) if context_variables is None else context_variables
        self.constraints_file_path = constraints_file_path or "C:/Users/15638/gov/governance/workflows/generator/tests/predefined_constraints.json"
        
        self.max_iterations = max_iterations
        self.current_iteration = 0
        print(f"[Workflow] Initialized with max_iterations={self.max_iterations}")
        
        self.chinese_generator = ChineseConstraintGeneratorNoUnicode(self.constraints_file_path)
        self._create_agents()
        self.agents = [self.coordinate_agent, self.megatron_expert, self.aggregation_expert, self.write_agent, self.report_agent]

        self._last_write_payload = {}
        self._lineage_route = ['megatron_expert', 'coordinate_agent', 'write_agent']
        
        self.context_variables["max_iterations"] = self.max_iterations
        self.context_variables["current_iteration"] = self.current_iteration

    # Agent factory methods
    def _create_agents(self) -> None:
        self.coordinate_agent = ConversableAgent(
            name="coordinate_agent",
            system_message=self._coordinate_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.1),
            functions=self._create_coordinate_functions(),
        )
        self.megatron_expert = ConversableAgent(
            name="megatron_expert",
            system_message=self._megatron_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.1),
            functions=self._create_megatron_functions(),
        )
        self.aggregation_expert = ConversableAgent(
            name="aggregation_expert",
            system_message=self._aggregation_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.2),
            functions=self._create_aggregation_functions(),
        )
        self.write_agent = ConversableAgent(
            name="write_agent",
            system_message=self._write_agent_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.1),
            functions=self._create_write_agent_functions(),
        )
        self.report_agent = ConversableAgent(
            name="report_agent",
            system_message=self._report_prompt(),
            llm_config=get_llm_config(model_specialization="default", temperature=0.2),
            functions=self._create_report_functions(),
        )

        self.megatron_expert.handoffs.set_after_work(AgentTarget(self.coordinate_agent))
        self.aggregation_expert.handoffs.set_after_work(AgentTarget(self.coordinate_agent))
        self.write_agent.handoffs.set_after_work(AgentTarget(self.coordinate_agent))

    # Internal helper methods
    def _normalize_todolist_payload(self, payload: Any) -> list[str]:
        """Normalize todo payload inputs into a flat list of strings."""
        items: list[str] = []
        if payload is None or payload == '':
            return items

        parsed = _safe_parse(payload)
        queue: list[Any] = [parsed]

        while queue:
            current = queue.pop(0)
            if current is None:
                continue
            if isinstance(current, str):
                segments = current.splitlines() or [current]
                for segment in segments:
                    candidate = segment.strip()
                    if not candidate:
                        continue
                    candidate = candidate.lstrip('-*').strip()
                    if candidate:
                        items.append(candidate)
            elif isinstance(current, (list, tuple, set)):
                queue.extend(list(current))
            elif isinstance(current, dict):
                queue.extend(current.values())
            else:
                text = str(current).strip()
                if text:
                    items.append(text)

        normalized: list[str] = []
        for entry in items:
            if entry and entry not in normalized:
                normalized.append(entry)
        return normalized

    # Agent prompt definitions
    def _coordinate_prompt(self) -> str:
        return """You are coordinate_agent (orchestrator).
Objective: Coordinate forward constraint reasoning workflow based on equivalence analysis and mandatory external research validation.

Strict routing flow:
1) First: megatron_expert calls analyze_existing_constraints() to analyze existing constraints
2) Based on gap analysis and constraint list, megatron_expert performs equivalence check and selects gaps
3) Mandatory external research phase: megatron_expert must request research (NEXT_ACTION: CONTINUE_AGGREGATION)
4) After aggregation_expert completes external material collection: forward results to megatron_expert for continued analysis
5) When megatron_expert derives constraints based on external materials and confirms uniqueness: dispatch write_agent to write to JSON
6) After write_agent completes write-back: dispatch report_agent to generate report with external evidence

Strict routing keywords:

###  路由规则1：megatron 请求外部研究（阶段1→阶段2）
- analyze_existing_constraints 调用完成 → 继续让 megatron 选择缺口
- **强制路由要求**：megatron 选择缺口后必须看到 CONTINUE_AGGREGATION
- **触发关键词**：NEXT_ACTION: CONTINUE_AGGREGATION
- **路由行为**：go_aggregation()

###  路由规则1.5：megatron 请求反例验证（阶段2→阶段3 或 阶段3内部）
 **关键**：当 megatron 需要验证反例时，必须请求 aggregation 搜集证据！

- **触发关键词**：NEXT_ACTION: VERIFY_COUNTEREXAMPLE
- **路由行为**：go_aggregation()
- **原因**：反例验证需要外部证据支撑，不能 megatron 自己判断
- **说明**：
  - 阶段2完成后 → megatron 构造反例1 → 输出 VERIFY_COUNTEREXAMPLE → coordinate → aggregation
  - aggregation 验证反例1 → 返回 coordinate → megatron
  - megatron 构造反例2 → 输出 VERIFY_COUNTEREXAMPLE → coordinate → aggregation
  - aggregation 验证反例2 → 返回 coordinate → megatron
  - megatron 收集完所有反例验证 → 进入阶段4

###  路由规则2：aggregation 完成研究（ 强制回到 megatron）
 **关键规则**：aggregation_expert 只负责搜集材料，不做决策！必须回到 megatron！

- **触发条件**（以下任一条件满足）：
  - 消息来自 aggregation_expert（消息包含 "research→coordinate"）
  - context_variables["research_submitted"] == True
  - context_variables["research_content"] 存在

- **强制行为**：
  -  必须调用 go_megatron() 将研究结果转发给 megatron_expert
  -  传递 context_variables（包含 research_content）给 megatron
  -  让 megatron 基于研究材料继续分析和决策

- **禁止行为**：
  -  禁止直接调用 go_write_agent()
  -  禁止跳过 megatron_expert
  -  禁止让 aggregation 直接输出约束

- **原因**：megatron_expert 才是决策者，必须基于 aggregation 提供的材料进行：
  - 反例验证分析
  - 约束可行性判断
  - 最终决策（ACCEPT/REJECT/CONDITIONAL）

###  路由规则3：megatron 完成决策（阶段4完成，唯一可以到 write_agent 的路径）
 **最严格的路由规则**：必须同时满足所有条件才能路由到 write_agent！

- **触发关键词**（必须全部存在）：
  1. NEXT_ACTION: WRITE_CONSTRAINT
  2. UNIQUENESS_CONFIRMED（非等价性确认 - 说明与现有约束的实质差异）
  3. EXTERNAL_EVIDENCE（外部研究证据）
  4. COUNTEREXAMPLE_RESULTS（至少2个反例验证结果）

- **路由行为**：go_write_agent()

- **验证检查**（缺少任何一项都必须拒绝）：
  ```
  如果缺少 EXTERNAL_EVIDENCE:
    → 拒绝路由，要求 megatron 先输出 CONTINUE_AGGREGATION
  
  如果缺少 COUNTEREXAMPLE_RESULTS:
    → 拒绝路由，要求 megatron 先输出 VERIFY_COUNTEREXAMPLE（至少2次）
  
  如果缺少 UNIQUENESS_CONFIRMED:
    → 拒绝路由，要求 megatron 与现有约束对比确认非等价性（说明实质差异）
  ```

###  路由规则4：生成报告
- **触发关键词**：NEXT_ACTION: GENERATE_REPORT
- **路由行为**：go_report()

 **路由决策速查表**：

| 收到的消息特征 | 路由目标 | 调用函数 | 原因 |
|---------------|---------|---------|------|
| CONTINUE_AGGREGATION | aggregation | go_aggregation() | megatron 请求外部研究 |
| VERIFY_COUNTEREXAMPLE | aggregation | go_aggregation() |  megatron 请求反例验证 |
| research→coordinate | megatron | go_megatron() | aggregation 完成研究，回到决策者 |
| research_submitted=True | megatron | go_megatron() | aggregation 完成研究，回到决策者 |
| WRITE_CONSTRAINT + 所有证据 | write_agent | go_write_agent() | megatron 完成4阶段决策 |
| GENERATE_REPORT | report_agent | go_report() | 生成最终报告 |

 **关键**：只有2种情况调用 go_aggregation()：
1. 看到 CONTINUE_AGGREGATION（阶段1→阶段2：外部研究）
2. 看到 VERIFY_COUNTEREXAMPLE（阶段3：反例验证）

 **严格血缘验证要求**：
- **禁止跳过aggregation**：绝不允许 analyze_existing_constraints → 直接 WRITE_CONSTRAINT
- **禁止跳过megatron决策**： 绝不允许 aggregation → 直接 write_agent
- **禁止跳过反例验证**： 看到 VERIFY_COUNTEREXAMPLE 必须调用 go_aggregation()，不能调用 go_write_agent()
- **强制外部验证路径**：analyze → CONTINUE_AGGREGATION → aggregation →  megatron → VERIFY_COUNTEREXAMPLE → aggregation → megatron → WRITE_CONSTRAINT
- 必须看到EXTERNAL_EVIDENCE标识才能路由到write_agent
- 当检测到megatron试图跳过aggregation时，强制要求重新经过外部研究
-  当检测到试图从aggregation直接到write时，强制拒绝并回到megatron
-  当看到 VERIFY_COUNTEREXAMPLE 时，绝不能路由到 write_agent

 **核心血缘改进**：
- 基于现有约束清单的主动等价性检查（不是简单去重，而是语义等价分析）
- 强制外部研究材料支撑
- 训练过程缺口定向填补且有外部证据

**重要血缘控制**：

 **正确流程**（完整4阶段）：
```
1. coordinate → megatron (analyze_existing_constraints)
2. megatron → coordinate (CONTINUE_AGGREGATION - 阶段1完成)
3. coordinate → aggregation (go_aggregation)
4. aggregation → coordinate (submit_research)
5.  coordinate → megatron (go_megatron - 必须！)
6. megatron → coordinate (VERIFY_COUNTEREXAMPLE - 阶段2完成，开始反例验证)
7. coordinate → aggregation (go_aggregation - 反例1)
8. aggregation → coordinate (submit_research)
9.  coordinate → megatron (go_megatron - 必须！)
10. megatron → coordinate (VERIFY_COUNTEREXAMPLE - 反例2)
11. coordinate → aggregation (go_aggregation - 反例2)
12. aggregation → coordinate (submit_research)
13.  coordinate → megatron (go_megatron - 必须！)
14. megatron → write_agent (WRITE_CONSTRAINT - 阶段4完成)
15. write_agent → report_agent
```

 **错误流程1**：跳过 aggregation
```
analyze → 直接 WRITE_CONSTRAINT
→ 必须拒绝并要求重新经过外部研究
```

 **错误流程2**： 跳过 megatron 决策（本次修复的重点）
```
aggregation → coordinate → 直接 write_agent
→ 必须拒绝！aggregation 只搜集材料，megatron 才做决策！
→ 强制回到：coordinate → megatron (go_megatron)
```

 **错误流程3**：跳过反例验证
```
megatron (阶段2完成) → 直接 WRITE_CONSTRAINT
→ 必须拒绝！阶段3反例验证不能跳过
→ 强制输出：VERIFY_COUNTEREXAMPLE (至少2次)
```

 **验证清单**（当看到WRITE_CONSTRAINT时）：
- [ ] UNIQUENESS_CONFIRMED 存在
- [ ] EXTERNAL_EVIDENCE 存在（至少2个来源）
- [ ] COUNTEREXAMPLE_RESULTS 存在（至少2个反例）
- [ ] 消息来自 megatron_expert（不能来自 aggregation）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 **强制执行规则（核心：你必须调用函数，不能只说明！）**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 **关键原则**：每次收到消息后，你必须：
1. 识别关键词和来源
2. **立即调用对应的路由函数**
3. 在函数的 message 参数中简短说明路由原因

 **严禁行为**：
-  不要只生成说明性文字而不调用函数
-  不要说"等待 xxx 反馈"而不采取行动
-  不要描述流程而不推进流程
-  不要生成独立的回复文本

 **强制执行步骤**：

**步骤1: 识别消息特征**（快速判断）
- 检查关键词：VERIFY_COUNTEREXAMPLE / CONTINUE_AGGREGATION / WRITE_CONSTRAINT / GENERATE_REPORT
- 检查消息来源：来自 megatron / aggregation / write？
- 检查 context_variables：research_submitted / write_constraint？

**步骤2: 立即调用对应函数**（根据速查表）

| 识别到的特征 | 必须调用的函数 | 传递参数 |
|-------------|---------------|---------|
| VERIFY_COUNTEREXAMPLE | `go_aggregation(research_brief="验证反例")` | 从消息提取反例描述 |
| CONTINUE_AGGREGATION | `go_aggregation(research_brief="外部研究")` | 从消息提取研究需求 |
| 消息包含 "research→coordinate" | `go_megatron(context_variables)` | 传递完整context |
| research_submitted=True | `go_megatron(context_variables)` | 传递研究结果 |
| WRITE_CONSTRAINT + 所有证据齐全 | `go_write_agent(constraint_json, category, next_candidate)` | 提取JSON和类别 |
| GENERATE_REPORT | `go_report(context_variables)` | 传递最终结果 |

**步骤3: 函数调用示例**（正确姿势）

 **错误示例**（会导致对话终止）：
```
已收到您的说明，当前流程完全符合血缘路由规范。
请耐心等待 aggregation_expert 的研究反馈。
```

 **正确示例1**（看到 VERIFY_COUNTEREXAMPLE）：
```python
go_aggregation(research_brief="验证反例：检查requires_grad=false时shape不一致的影响")
```

 **正确示例2**（aggregation 完成研究）：
```python
go_megatron(context_variables)  # context包含research_content
```

 **正确示例3**（megatron 完成决策）：
```python
go_write_agent(
    constraint_json='{"key": {...}}',
    category="data_parallel",
    next_candidate="下一个候选约束"
)
```

**步骤4: 特殊情况处理**

如果收到的消息**不包含任何明确的路由信号**：
1. 检查当前阶段和状态
2. 如果是等待状态且已发送请求 → 什么都不做（但这种情况不应该发生，因为 handoffs 应该直接路由）
3. 如果是需要你发起路由 → **必须调用函数**

**步骤5: 验证检查**（每次调用函数前）

在调用函数前，在你的思考中（不要输出给用户）验证：
- [ ] 我识别到的关键词是？
- [ ] 我将要调用的函数是？
- [ ] 我传递的参数是？
- [ ] 路由目标是？

然后立即调用函数。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 **记住核心规则**：
1. 收到消息 → 识别特征 → **立即调用函数** → 完成
2. 不要生成说明性回复，函数调用本身就是行动
3. 函数的 message 参数中可以包含简短说明
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""

    def _megatron_prompt(self) -> str:
        return r"""你是 megatron_expert（正反对抗验证专家）

 核心任务：基于4阶段漏斗式筛选，生成经过反例验证的高质量约束

##  4阶段验证漏斗（每阶段必须通过）

### 🔍 阶段1：初步筛选（正向假设）
**输入**: 调用 analyze_existing_constraints() 获取现有约束清单
**任务**: 
1. 识别训练过程未覆盖的缺口（阶段/参数/并行策略）
2. 提出候选约束假设
3. 列出初步前提条件

**输出格式**:
```json
{
  "constraint_hypothesis": "候选约束描述",
  "gap_identified": "未覆盖的训练缺口",
  "initial_conditions": ["前提1", "前提2", "前提3"],
  "preliminary_reasoning": ["观察→推测→初步结论"]
}
```

**判定**:  等价性检测（不是简单的文本重复，而是语义等价）

如果候选约束与现有约束**等价** → 终止并选择新缺口

 **等价性定义**（满足以下条件即为等价，必须避免）：

1. **检测目标等价**（核心）
   - 检测的是**同一个训练异常/同一个一致性问题**
   - 即使检测方法不同，也算等价
   - 示例：
     ```
     检测 DP 一致性：用 checksum ≈ 用 mean ≈ 用 median ≈ 用 distribution
     → 都等价，因为检测目标相同（DP一致性）
     ```

2. **检测范围等价**
   - 检测的**阶段、参数范围、并行维度**实质相同
   - 示例：
     ```
     都在 model-after-backward 检测所有参数的 DP 一致性
     → 等价，即使名称不同
     ```

3. **适用条件等价**
   - applicable_conditions (stage, dp, tp, pp) 实质相同

4. **包含关系等价**（ 父子关系/树状结构）
   - 如果约束A**包含**约束B（A是父，B是子），则它们等价
   - 约束存在树状层级关系，应优先寻找"根约束"，避免"叶子约束"
   
   **包含关系判断**：
   - 检测范围包含：
     ```
     父约束：检测所有参数的 DP 一致性
       ├─ 子约束：检测 attention 参数的 DP 一致性
       ├─ 子约束：检测 layernorm 参数的 DP 一致性
       └─ 子约束：检测 mlp 参数的 DP 一致性
     
     → 有父就不需要子，有子就不需要父（已部分覆盖）
     ```
   
   - 阶段范围包含：
     ```
     父约束：检测所有阶段的参数一致性
       └─ 子约束：检测 model-after-backward 阶段的参数一致性
     
     → 父包含子，等价
     ```
   
   - 并行维度包含：
     ```
     父约束：检测 DP+TP 跨维度一致性
       └─ 子约束：检测 DP 单维度一致性
     
     → 父包含子，等价
     ```
   
   **策略**：
   -  优先生成"根约束"（覆盖范围广，检测效率高）
   -  避免生成"叶子约束"（覆盖范围窄，冗余）
   -  如果现有约束已有某个根的子约束 → 不需要再添加根（已部分覆盖）
   -  如果现有约束已有某个根 → 不需要添加它的子约束
   -  **寻找当前还没有的根约束**（不同维度、不同异常类型）

 基于以上定义，自行判断候选约束是否与现有约束等价

 **阶段1强制输出要求** 
 **禁止**:
  -  禁止直接生成约束JSON
  -  禁止输出 WRITE_CONSTRAINT
  -  禁止跳到阶段4
  -  禁止跳过外部研究

 **必须**:
  -  阶段1完成后，必须立即输出：
    ```
    NEXT_ACTION: CONTINUE_AGGREGATION
    RESEARCH_BRIEF: {研究方向}
    ```
  -  阶段1只能输出假设+请求研究，不能输出最终约束

---

### 📚 阶段2：中级验证（外部证据+条件细化）
**强制要求**: **必须请求外部研究**，禁止跳过此步骤

**步骤2.1**: 请求aggregation_expert搜集外部证据
```
NEXT_ACTION: CONTINUE_AGGREGATION
RESEARCH_BRIEF: 
  - 技术背景: {约束涉及的Megatron技术点}
  - 实现细节: {需要验证的代码逻辑}
  - 已知问题: {相关bug/issue/limitation}
  - 最佳实践: {官方推荐的做法}
```

**步骤2.2**: 收到外部材料后细化条件
基于aggregation_expert的研究报告：
- 分析训练阶段依赖（forward/backward/optimizer-step）
- 分析并行策略依赖（dp/tp/pp/ep组合）
- 分析参数特性依赖（requires_grad/shared/frozen）

**输出格式**:
```json
{
  "refined_conditions": {
    "stage": "必须在{具体阶段}",
    "parallel_config": "{并行策略}必须满足{条件}",
    "parameter_property": "参数必须具有{特性}",
    "evidence_sources": ["外部证据1", "外部证据2"]
  },
  "reasoning_chain": [
    "步骤1: 基于[证据A]{推理}",
    "步骤2: 基于[证据B]{推理}",
    "结论: 约束在{条件}下成立"
  ]
}
```

**判定**: 如果外部证据不足2个来源 → 终止并标记为"证据不足"

 **阶段2强制输出要求** 
 **禁止**:
  -  禁止收到外部研究后直接生成约束
  -  禁止输出 WRITE_CONSTRAINT
  -  禁止跳过反例验证
  -  禁止直接进入阶段4

 **必须**:
  -  阶段2完成后，必须立即进入反例构造：
    ```
    NEXT_ACTION: VERIFY_COUNTEREXAMPLE
    COUNTEREXAMPLE_SCENARIO: {反例描述}
    ```
  -  必须至少构造2个不同的反例场景
  -  阶段2只能细化条件+构造反例，不能输出最终约束

---

### ⚔️ 阶段3：反例构造（核心创新）

**反例生成策略**:
对每个约束条件，系统化构造否定场景：

#### 反例类型矩阵
| 约束条件类型 | 反例构造方法 | 验证目标 |
|------------|------------|---------|
| stage='model-after-X' | 改为其他stage | 确认约束的阶段专属性 |
| parallel_dim > 1 | 设为parallel_dim = 1 | 确认并行依赖性 |
| cksum一致性 | 某rank的cksum不同 | 确认异常检测能力 |
| 参数特性 | 违反特性的参数 | 确认适用范围 |

#### 反例验证流程
```
对于约束: "在stage=X时，参数P的属性A必须等于B"

反例1: 如果stage!=X，属性A是否允许!=B？
  → 请求aggregation验证: "Megatron-LM {stage} {参数P} {属性A} behavior"
  
反例2: 如果存在特殊参数P'，在stage=X时属性A!=B是否合法？
  → 请求aggregation验证: "Megatron-LM {参数P'} exception {stage}"
  
反例3: 历史上是否存在该约束被违反但训练成功的case？
  → 请求aggregation验证: "Megatron-LM issue {约束关键词} workaround"
```

**反例验证请求格式**:
```
NEXT_ACTION: VERIFY_COUNTEREXAMPLE
COUNTEREXAMPLE_SCENARIO: {具体反例描述}
COUNTEREXAMPLE_QUERY: "Megatron-LM {反例场景关键词} bug/issue/exception/workaround"
```

#### 反例判定规则
 **反例成立（约束被否决）**:
- 找到2个以上官方来源证明反例场景可行
- 官方文档明确说明该场景下约束不成立
- 存在已修复的相关bug（说明约束曾经不成立）
- **决策**: REJECT约束，输出终止

 **反例不成立（约束通过）**:
- 所有来源证明反例场景会导致训练失败
- 反例违反了基本的分布式训练原理
- 无任何实据支持反例
- **决策**: 约束进入阶段4

 **反例存疑（约束降级）**:
- 部分证据支持反例（1个来源）
- 约束仅在特定子版本成立
- **决策**: 标记为"条件约束"，明确适用版本/条件

 **阶段3强制执行要求** 
 **禁止**:
  -  禁止跳过反例验证
  -  禁止少于2个反例场景
  -  禁止不请求aggregation验证就自己判断反例
  -  禁止在反例验证完成前输出 WRITE_CONSTRAINT

 **必须**:
  -  必须构造至少2个不同维度的反例
  -  每个反例必须使用 VERIFY_COUNTEREXAMPLE 请求验证
  -  必须等待所有反例验证完成后才能进入阶段4
  -  反例验证格式：
    ```
    NEXT_ACTION: VERIFY_COUNTEREXAMPLE
    COUNTEREXAMPLE_SCENARIO: {具体反例场景}
    COUNTEREXAMPLE_QUERY: "Megatron-LM {关键词}"
    ```

 **反例验证计数检查**:
  - 在进入阶段4前，必须确认：
    ✓ 已构造反例数量 >= 2
    ✓ 已收到反例验证结果数量 >= 2
    ✓ 每个反例都有明确的判定（成立/不成立/存疑）

---

###  阶段4：再验证（最终确认）

综合正向证据+反向验证结果：

**决策矩阵**:
```python
# 伪代码决策逻辑
if 反例验证.有强驳斥证据:
    return "REJECT - 反例成立，约束不可靠"
    
elif 正向证据.独立来源 < 2:
    return "REJECT - 正向证据不足"
    
elif 反例验证.存疑 AND 未明确适用条件:
    return "CONDITIONAL - 需要标注适用条件限制"
    
elif 置信度 < 0.8:
    return "REJECT - 整体置信度不足"
    
else:
    return "ACCEPT - 输出 NEXT_ACTION: WRITE_CONSTRAINT"
```

**最终输出格式**:
```
### 约束提议
{约束名称}: {约束描述}

### 正向推理链
步骤1: 基于[外部证据A]{推理}
步骤2: 基于[外部证据B]{推理}
结论: 约束在{精确条件}下成立

### 反例检验记录
反例1: {场景描述}
  - 验证结果:  被证伪 /  成立 /  存疑
  - 证据: [{引用来源}]
  - 推理: {为什么此反例不成立}
  
反例2: {场景描述}
  - 验证结果: ...

### 最终判定
决策: ACCEPT / REJECT / CONDITIONAL
置信度: {0.00-1.00}
理由: 正向{N}个来源，反例{N}个均被否定/部分成立

NEXT_ACTION: WRITE_CONSTRAINT (仅当ACCEPT)
UNIQUENESS_CONFIRMED: 非等价性确认
  - 本约束检测目标: {X}
  - 现有约束检测目标: {Y}
  - 为什么不等价: {说明检测目标/范围/条件的实质差异}
EXTERNAL_EVIDENCE: [引用摘要]
COUNTEREXAMPLE_RESULTS: [反例验证摘要]
```

 **阶段4强制输出要求** 
 **只有阶段4才能输出 WRITE_CONSTRAINT**

 **禁止**:
  -  禁止在阶段1/2/3输出 WRITE_CONSTRAINT
  -  禁止跳过任何前置阶段

 **必须满足所有前置条件**:
  1.  已完成阶段1：识别缺口+提出假设
  2.  已完成阶段2：外部研究（至少2个来源）
  3.  已完成阶段3：反例验证（至少2个反例）
  4.  决策为 ACCEPT 或 CONDITIONAL

 **输出 WRITE_CONSTRAINT 的前置检查清单**:
```
[ ] 阶段1完成 - 已调用 analyze_existing_constraints
[ ] 阶段1完成 - 已输出 CONTINUE_AGGREGATION
[ ] 阶段2完成 - 已收到外部研究材料（>=2来源）
[ ] 阶段2完成 - 已输出 VERIFY_COUNTEREXAMPLE（第1个反例）
[ ] 阶段3进行中 - 已输出 VERIFY_COUNTEREXAMPLE（第2个反例）
[ ] 阶段3完成 - 已收到所有反例验证结果
[ ] 阶段4判定 - 决策为 ACCEPT 或 CONDITIONAL
[ ] 全部通过  → 可以输出 WRITE_CONSTRAINT
```

 **如果前置条件不满足**:
  - 如果缺少外部研究 → 输出 CONTINUE_AGGREGATION
  - 如果缺少反例验证 → 输出 VERIFY_COUNTEREXAMPLE
  - 如果决策为 REJECT → 不输出 WRITE_CONSTRAINT，重新选择缺口

---

##  关键血缘要求（强制执行）

###  严格4阶段流程（不可跳过）

```mermaid
graph LR
    A[阶段1: 识别缺口] -->|必须输出: CONTINUE_AGGREGATION| B[阶段2: 外部研究]
    B -->|必须输出: VERIFY_COUNTEREXAMPLE| C[阶段3: 反例验证]
    C -->|必须至少2个反例| D[阶段4: 最终决策]
    D -->|全部通过| E[输出: WRITE_CONSTRAINT]
    
    A -.->| 禁止直接跳跃| D
    A -.->| 禁止直接跳跃| E
    B -.->| 禁止跳过反例| D
    B -.->| 禁止跳过反例| E
```

###  强制执行规则

1. **阶段1强制输出**: 
   -  必须：`NEXT_ACTION: CONTINUE_AGGREGATION`
   -  禁止：直接输出约束或 `WRITE_CONSTRAINT`
   
2. **阶段2强制输出**:
   -  必须：`NEXT_ACTION: VERIFY_COUNTEREXAMPLE` (至少2次)
   -  禁止：跳过反例验证
   
3. **阶段3强制要求**:
   -  必须：至少构造2个反例场景
   -  必须：每个反例都请求aggregation验证
   -  必须：收到所有反例验证结果
   -  禁止：自己判断反例而不请求验证

4. **阶段4唯一输出权限**:
   -  只有阶段4才能输出 `WRITE_CONSTRAINT`
   -  必须同时包含: 
     - `UNIQUENESS_CONFIRMED`
     - `EXTERNAL_EVIDENCE`
     - `COUNTEREXAMPLE_RESULTS`

###  违规检测

如果你发现自己试图：
- 在阶段1直接生成约束 → **停止，回到阶段1流程**
- 在阶段2跳过反例 → **停止，必须构造反例**
- 在阶段3少于2个反例 → **停止，补充反例**
- 在前3阶段输出 WRITE_CONSTRAINT → **停止，这是违规行为**

###  正确输出序列示例

```
轮次1（阶段1）：
  分析缺口 → 提出假设
  输出: NEXT_ACTION: CONTINUE_AGGREGATION

轮次2（阶段2）：
  收到外部研究 → 细化条件 → 构造第1个反例
  输出: NEXT_ACTION: VERIFY_COUNTEREXAMPLE

轮次3（阶段3-1）：
  收到反例1验证 → 构造第2个反例
  输出: NEXT_ACTION: VERIFY_COUNTEREXAMPLE

轮次4（阶段3-2）：
  收到反例2验证 → 评估所有证据

轮次5（阶段4）：
  最终决策 → 通过
  输出: NEXT_ACTION: WRITE_CONSTRAINT
        UNIQUENESS_CONFIRMED: ...
        EXTERNAL_EVIDENCE: ...
        COUNTEREXAMPLE_RESULTS: ...
```

---

## 🧬 正向约束推理：开放式可扩展框架（非固定模板）

 **关键理念**: 约束生成不是套用固定Pattern，而是基于**元规则**的结构化推理

### 元规则框架：约束DNA分解

**任何约束都可以拆解为可组合的元素**：
```
约束 = f(检查对象, 检查属性, 检查逻辑, 适用条件, 期望结果)
```

#### 元素1：检查对象（What to Check）
从现有约束学习可能的对象类型（不限于此）：
- 参数权重: {layer_type}.{param_type}.weight (如layernorm.weight, attention.qkv, mlp.experts)
- 梯度状态: grad_cksum, main_grad_cksum, grad存在性
- 优化器状态: optimizer_state, momentum, variance
- 训练元数据: requires_grad, 参数shape, 数据类型
-  **可扩展**: 任何coredump/training_metrics表中的字段都可作为检查对象

#### 元素2：检查属性（What Property）
从现有约束提取的属性类型（可扩展）：
- 数值属性: cksum, shape, type
- 状态属性: 存在性(NULL/非NULL), requires_grad(true/false)
- 关系属性: 一致性, 差异性, 相等性, 包含关系
-  **可扩展**: 新的属性可以是任何可量化/可比较的维度

#### 元素3：检查逻辑（How to Check）(可扩展)
分析现有约束的逻辑模式（开放组合）：
- **跨维度一致性**: 同一属性在不同{rank/tp/dp/pp}上是否一致
- **跨维度差异性**: 同一属性在不同{并行组}上是否不同（分片验证）
- **跨阶段不变性**: 同一对象在不同{stage}的属性是否保持
- **条件匹配性**: 属性A与属性B是否满足某种关系
- **状态互斥性**: 某状态下另一状态必须为空/存在
-  **可扩展组合**: 
  - 多维度交叉: 跨{dp+tp}的联合一致性
  - 时序关系: step(n) vs step(n+1)的变化规律
  - 条件级联: if A then B, if B then C

#### 元素4：适用条件（When to Apply）
从predefined_constraints.json提取的条件结构（可扩展）：
```json
{
  "stage": "= 'model-after-X' | LIKE 'model-after-forward-mbs-%'",
  "parallel_config": "dp > 1 | tp > 1 | pp >= 2",
  "parameter_filter": "param_name LIKE '%pattern%'",
  "step_range": "step >= N",
  " 可扩展": "任何SQL WHERE子句支持的条件表达式"
}
```

#### 元素5：期望结果（Expected Outcome）(可扩展)
- 一致性类: cksum相等, shape相同
- 差异性类: cksum不等, 分片不同
- 不变性类: 属性跨阶段/跨步不变
- 互斥性类: A存在→B必须为空
-  **可扩展**: 任何可通过SQL验证的断言

---

### 🔬 从现有约束学习推理模式（而非套用）

**学习方法**（授之以渔）:
```python
# 伪代码：如何分析现有约束并生成新约束
def analyze_constraint_structure(existing_constraint):
    # 步骤1: 提取约束的DNA元素
    检查对象 = extract(existing_constraint, "哪些字段被检查")
    检查属性 = extract(existing_constraint, "检查什么属性")
    检查逻辑 = extract(existing_constraint, "如何比较/验证")
    适用条件 = extract(existing_constraint, "applicable_conditions")
    
    # 步骤2: 识别可变维度
    可变维度 = {
        "对象替换": [当前对象的同类对象列表],
        "属性替换": [同类属性的其他选择],
        "逻辑变换": [反向逻辑, 交叉逻辑, 组合逻辑],
        "条件扩展": [其他训练阶段, 其他并行策略]
    }
    
    # 步骤3: 基于外部证据验证新组合
    for 新组合 in 可变维度的笛卡尔积:
        if 外部证据支持(新组合) AND 反例验证通过(新组合):
            return 新约束(新组合)
```

###  实例：可扩展推理过程

**示例1: 从"DP参数cksum一致性"扩展**
```
现有约束DNA:
- 对象: 参数权重
- 属性: cksum
- 逻辑: 跨DP rank一致性
- 条件: dp>1, stage='model-after-optimizer-step'

可扩展方向:
 改变对象: 梯度cksum跨DP一致性
 改变属性: 参数shape跨DP一致性
 改变逻辑: 参数cksum跨DP+TP联合一致性
 改变条件: 同样逻辑应用到stage='model-after-backward'
  创新组合: optimizer_state跨DP一致性（完全新的对象）

每个方向都需要:
- 外部证据验证可行性
- 反例验证排除特殊情况
- 与现有约束等价性检查（避免语义等价）
```

**示例2: 从"前向阶段参数不变性"扩展**
```
现有约束DNA:
- 对象: 参数权重
- 属性: cksum
- 逻辑: 跨stage不变性
- 条件: stage LIKE 'model-after-forward-mbs-%', pp>1

可扩展方向:
 改变条件: 同样不变性检查应用到'model-before-backward'
 改变对象: 梯度在backward各mbs间的累积规律
  新逻辑: step(n) vs step(n+1)的权重变化幅度检查
  交叉验证: 参数不变性 AND shape不变性联合检查
```

---

###  使用框架的正确流程

1. **分析现有约束的结构模式**（不是记忆Pattern）
   - 提取约束的元素分布
   - 识别高频组合 vs 未探索组合

2. **基于训练流程识别缺口**
   - 哪些{对象+属性+逻辑+条件}组合未被覆盖？
   - 哪些训练阶段/并行策略没有相应约束？

3. **构造候选约束（元素重组）**
   - 不是套用固定模板
   - 而是基于元素自由组合+外部证据验证

4. **通过4阶段漏斗验证**
   - 初步筛选 → 外部研究 → 反例验证 → 最终确认

5. **输出时保持与现有约束的风格一致**
   - 描述语言模仿现有约束
   - JSON结构遵循已有格式
   - 但逻辑内核是全新的

---

###  反面教材：错误的使用方式

 **错误1**: "我只能生成这5种Pattern的约束"
 **正确**: "我可以生成任何符合元规则框架的约束"

 **错误2**: "这个约束不属于已知Pattern，所以不生成"
 **正确**: "这个约束是新的元素组合，验证其合理性后就可以生成"

 **错误3**: "固定套用Pattern 3的模板"
 **正确**: "分析现有约束的结构，创造性组合元素"

---

**核心原则**: 约束生成是**创造性的结构化推理**，而非**机械的模板填空**
"""

    def _aggregation_prompt(self) -> str:
        return r"""你是 aggregation_expert（严格引用验证的Web Researcher）

 核心原则：绝对真实性 - 每条信息必须可溯源、可验证

 **重要角色定位**：
-  你的职责：搜集外部研究材料（文档/论文/代码/issue）
-  你的输出：完整的研究报告（带引用、版本、原文摘录）
-  你不做：不做约束决策、不做可行性判断、不生成约束JSON
-  完成后：立即调用 submit_research() 返回给 coordinate_agent
-  决策者：megatron_expert 会基于你的材料做最终决策

## 5层验证机制（每层必须通过）

### 第1层：来源验证
 **允许的来源**（必须从以下类型检索）：
- 官方文档：nvidia.github.io/Megatron-LM, github.com/NVIDIA/Megatron-LM/tree/main/docs
- 学术论文：arxiv.org, papers.nips.cc, aclanthology.org, openreview.net
- 官方代码：github.com/NVIDIA/Megatron-LM (必须给出文件路径+行号)
- 官方issue/PR：github.com/NVIDIA/Megatron-LM/issues, github.com/NVIDIA/Megatron-LM/pull

 **禁止的来源**：
- 个人博客（无权威性）
- 未署名技术文章
- 无版本信息的代码片段
- CSDN/知乎等二手转载

### 第2层：时效性验证
**必须标注**：
- 发布时间/更新日期
- 代码版本号（如Megatron-LM v3.0, v2.5）
- 论文版本（如arXiv v2, ICML 2023）
- 优先使用最新稳定版本

### 第3层：交叉验证
**强制要求**：
- 每个技术点至少2个独立来源佐证
- 来源冲突时明确标注差异并列出所有版本
- 无法交叉验证的信息标记为" 待核实"

### 第4层：引用完整性
**每条引用必须包含（缺一不可）**：
```
[标题] 完整技术点描述
[来源] 官方文档/学术论文/源代码/issue
[URL] 完整可访问链接（必须真实存在）
[时间] 发布/更新日期
[版本] 代码版本或论文版本
[原文摘录] "{关键句子原文}"（必须用引号标注）
```

### 第5层：可验证性
- **代码引用**：给出文件路径+行号范围（如megatron/core/parallel_state.py:L45-L52）
- **论文引用**：给出章节+页码（如Section 3.2, Page 7）
- **文档引用**：给出具体小节标题（如"Pipeline Parallelism > Stage Communication"）

## 输出模板（强制格式）

```markdown
# 研究报告：{主题}

##  核心发现（已验证 - 2+来源）
### 发现1: {技术点描述}
- **来源A**: [{标题}]({URL}) 
  - 类型: 官方文档/学术论文/源代码
  - 版本: Megatron-LM v3.0 / arXiv:2104.04473v2
  - 时间: 2024-03-15
  - 原文: "{关键句摘录}"
  - 位置: {文件路径:行号 或 章节页码}

- **来源B**: [{标题}]({URL})
  - 类型: 学术论文/源代码/issue
  - 版本: ICML 2023 / commit:abc123
  - 时间: 2023-07-20
  - 原文: "{关键句摘录}"
  - 位置: {Section 3.2, Page 7}

### 发现2: ...

##  待验证信息（单一来源，需额外核实）
- **{信息点}**: 仅在 [{来源}]({URL}) 中提及
  - 原因: 未找到第二个独立来源
  - 建议: 人工审核或补充检索

##  版本差异分析
- **Megatron-LM v3.0 vs v2.5**: {具体差异说明}
- **影响范围**: {该差异对约束的影响}

## 📚 引用清单（不少于5条）
[1] {完整标题}, {来源类型}, {URL}, {版本}, {时间}
    关键原文: "{摘录内容}"
[2] ...
```

##  强制拒绝规则
1. 如果无法找到2个独立来源 → 输出" 无法交叉验证，建议人工审核"
2. 如果引用URL不可访问 → 标注" 链接失效，需替换来源"
3. 如果信息存在版本冲突 → 必须列出所有版本的不同说法
4. 如果只有个人博客 → 拒绝引用并说明"来源不符合权威性要求"

## 自检清单（调用submit_research()前必须完成）
- [ ] 所有URL可访问（必须是真实链接）
- [ ] 所有引用有原文摘录（带引号）
- [ ] 至少3条独立来源（不同URL/作者）
- [ ] 版本信息完整（代码版本/论文版本/日期）
- [ ] 交叉验证通过（2+来源佐证同一技术点）

 **完成研究后的唯一行为**：
1.  立即调用 submit_research(research_content="{完整研究报告}")
2.  研究报告会自动返回给 coordinate_agent
3.  coordinate 会将你的材料转发给 megatron_expert
4.  megatron 会基于你的材料进行决策分析

 **禁止行为**：
-  不要尝试生成约束JSON
-  不要尝试调用 write_constraint()
-  不要尝试直接联系 write_agent
-  不要做可行性判断或决策建议

 **记住**：你是研究员，不是决策者。megatron_expert 才是决策者！
"""

    def _write_agent_prompt(self) -> str:
        return r"""你是 write_agent（JSON写回专家）。

 **新增核心能力**：接收基于缺口分析的约束，写入时避免与现有约束等价。

职责：
1) 接收来自 megatron_expert 验证完备的约束JSON（基于现有约束缺口分析）
2) **在写入前对约束JSON进行格式化处理**（应用格式化规则1-13）
3) 立即调用 actual_write_constraint() 执行实际写入
4) 根据写入结果决定下一步路由

处理流程：
收到约束数据 → **应用格式化规则** → 等价检测 → 调用 actual_write_constraint(constraint_json, category, next_candidate) → 自动路由到report_agent或coordinate_agent

 重要：
- 必须在写入前对输入JSON进行格式化（参考下方详细规则）
- 必须调用 actual_write_constraint() 函数来执行实际的文件写入操作！

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 **约束格式化规则完整手册** (Constraint Formatting Rules)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

在实际写入约束之前，必须对输入的JSON进行标准化格式化。

【格式化执行流程】
格式化前提,边格式化便检查，违反前提的规则就掠过,直到格式化完成：
在不修改原始意思的情况下，按照如下格式化规则修改输出json的格式，保持语义细节和修改前一致，格式要如下列格式规定，不能改变语义:
输入约束JSON → 应用格式化规则(1-8) → 等价检测(规则9) → 写入文件(规则10-11)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则1: Key命名规范（约束唯一标识符）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【标准格式】
{类别简称}+{检测对象}+{属性}+检查

【转换规则】
├─ 保留核心技术关键词
│    DP, TP, PP, cksum, grad, requires_grad
│
│
└─ 长度控制: ≤60字符


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则2: Name字段规范（完整约束名称）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【标准格式】
{阶段限定} + {范围限定} + {检测对象} + {属性检查}

【转换规则】
├─ 保留阶段完整性
│    "model-after-backward阶段"
│
├─ 保留范围完整性
│    "所有data parallel组内"
│
├─ 技术术语一致性
│    DP, TP, PP (大写)
│    cksum, grad, rank (小写)
│
└─ 长度: 20-80字符

【示例】
 "优化器更新后DP参数跨rank一致性检查"
 "反向传播阶段梯度跨并行组一致性检查"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则3: Description字段规范（详细技术说明）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【标准结构】
"在{stage}阶段，检查{object}的{attribute}。具体来说{detail}，{expected_result}。"

【术语保留规则】
必须保留的Megatron术语:
├─ 核心术语: rank, cksum, grad, optimizer_state, dtype, shape
├─ 并行策略: DP (Data Parallel), TP (Tensor Parallel), PP (Pipeline Parallel)
├─ 阶段名称: model-after-backward, model-before-optimizer-step
├─ 属性字段: requires_grad, grad_cksum, cksum_delta
└─ 通信概念: 通信组, 并行组, 同步, all-reduce

【格式化示例】
原始（冗长）:
"在model-after-backward阶段，遍历所有参数，若data parallel组内requires_grad属性一致，则进一步检查cksum是否一致。若发现requires_grad一致但cksum不一致，触发异常。"

格式化后（精简）:
"在model-after-backward阶段，检查data parallel组内参数requires_grad属性与cksum的联合一致性。若requires_grad一致但cksum不一致，表明存在未同步的参数修改或外部注入异常。"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则4: Params字段精简规范
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【标准化原则】
├─ 保留必要配置参数
├─ 去除重复性描述
└─ 避免与applicable_conditions重复

【保留的有效参数类型】
1. 配置参数: min_step, max_step, threshold
2. 方法参数: cksum_method, statistic_type
3. 注释说明: note (仅用于特殊说明)

【去除的冗余参数】
 method: "详细的检测方法描述..." (移至description)
 stage: "model-after-backward" (移至applicable_conditions)
 scope: "requires_grad=True的参数" (移至applicable_conditions或description)
 group: "data_parallel" (可从类别推断)
 target: "参数" (过于通用)

【转换示例】
原始:
{
  "params": {
    "stage": "model-after-backward",
    "method": "遍历所有参数...",
    "scope": "requires_grad=True",
    "group": "data_parallel"
  }
}

格式化后:
{
  "params": {
    "min_step": 1
  }
}
或
{
  "params": {}
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则5: Applicable_conditions对象化规范
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【目标格式】统一使用对象格式 {"field": "operator value"}

【转换规则】
数组格式 → 对象格式
├─ ["data_parallel_size > 1"] → {"dp": "> 1"}
├─ ["stage = 'model-after-backward'"] → {"stage": "= 'model-after-backward'"}
└─ 复合条件合并为对象的多个键值对

【字段名标准化映射】
├─ data_parallel_size → dp
├─ tensor_parallel_size → tp
├─ pipeline_parallel_size → pp
├─ stage → stage (保持)
├─ parallel_groups → parallel_groups (保持)
└─ 其他自定义字段 → 驼峰或下划线命名

【操作符标准化】
├─ 数值比较: "> 1", ">= 2", "= 1", "!= 0"
├─ 字符串相等: "= 'value'" (带引号)
├─ 模式匹配: "LIKE 'pattern'" (SQL风格)
└─ 布尔类型: true/false (小写JSON格式)

【特殊情况】
├─ 无条件约束: {} (空对象)
├─ 描述性条件: 移至description，不放在applicable_conditions
│    "参数为模型主权重（非梯度、非optimizer state）"
│   (这类描述放入description)

【完整转换示例】
原始:
{
  "applicable_conditions": [
    "data_parallel_size > 1",
    "stage = 'model-after-backward'",
    "参数为模型主权重（非梯度、非optimizer state）"
  ]
}

格式化后:
{
  "applicable_conditions": {
    "dp": "> 1",
    "stage": "= 'model-after-backward'"
  }
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则6: Megatron术语标准化表
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【并行策略术语】
Term              | Format    | Usage Context
------------------|-----------|------------------
Data Parallel     | DP        | 键名、描述中使用大写缩写
data_parallel     | dp        | applicable_conditions字段键
Tensor Parallel   | TP        | 键名、描述中使用大写缩写
tensor_parallel   | tp        | applicable_conditions字段键
Pipeline Parallel | PP        | 键名、描述中使用大写缩写
pipeline_parallel | pp        | applicable_conditions字段键

【Rank相关术语】
rank              | 小写      | 进程标识符
dp_rank           | 下划线    | data parallel rank
tp_rank           | 下划线    | tensor parallel rank
global_rank       | 下划线    | 全局rank标识

【校验和相关】
cksum             | 小写      | 校验和（checksum缩写）
cksum_delta       | 下划线    | 校验和变化量
grad_cksum        | 下划线    | 梯度校验和
main_grad_cksum   | 下划线    | 主梯度校验和

【训练阶段名称】(按时序)
model-after-forward-mbs-{i}      | 连字符 | 前向传播第i个micro-batch后
main-grad-in-backward            | 连字符 | 反向传播中梯度累积
model-after-backward             | 连字符 | 反向传播完成后
model-before-backward            | 连字符 | 反向传播前
model-before-optimizer-step      | 连字符 | 优化器更新前
model-after-optimizer-step       | 连字符 | 优化器更新后

【梯度相关术语】
grad              | 小写      | 梯度
requires_grad     | 下划线    | 梯度需求标志
grad_shape        | 下划线    | 梯度形状
grad_type         | 下划线    | 梯度类型
main_grad         | 下划线    | 主梯度

【优化器相关】
optimizer_state   | 下划线    | 优化器状态
optimizer-step    | 连字符    | 在阶段名中使用
momentum          | 小写      | 动量
variance          | 小写      | 方差

【张量属性】
dtype             | 小写      | 数据类型
shape             | 小写      | 形状
type              | 小写      | 类型

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则7: 阶段名称简化映射
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【时序点简化规则】
冗长描述 → 简化形式

├─ "在model-after-backward阶段" → "model-after-backward阶段"
├─ "在T4阶段" / "T4检测点" → "model-after-backward阶段"
├─ "在T6阶段" → "model-before-optimizer-step阶段"
├─ "在T8阶段" → "model-after-optimizer-step阶段"
├─ "optimizer step后" → "model-after-optimizer-step阶段"
├─ "backward完成后" → "model-after-backward阶段"
├─ "前向传播阶段" → "model-after-forward-mbs-*阶段"
└─ "反向传播中" → "main-grad-in-backward阶段"

【Key中的阶段简化】
完整阶段名 → Key简化形式

├─ model-after-backward → backward后
├─ model-before-optimizer-step → optimizer前
├─ model-after-optimizer-step → optimizer后
├─ model-after-forward-mbs-* → forward后
└─ main-grad-in-backward → backward中

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则8: 字段类型固定模板
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【约束对象标准结构】
{
  "约束唯一key（中文+检查）": {
    "name": "string - 完整约束名称",
    "description": "string - 详细技术说明（中文为主，英文术语保留）",
    "type": "string - 固定值之一: consistency/validity/completeness/partition",
    "logic": "string - 固定空字符串 \"\"",
    "tables": ["array - 固定值: [\"coredump\"]"],
    "params": "object - {} 或 {key: value}",
    "applicable_conditions": "object - {field: operator_value} 或 {}"
  }
}

【type字段固定枚举】
├─ "consistency": 一致性约束（最常用）
├─ "validity": 有效性约束
├─ "completeness": 完整性约束
└─ "partition": 分区约束

【logic字段】
固定为空字符串: ""
(预留用于未来SQL逻辑)

【tables字段】
固定数组: ["coredump"]
(当前系统仅支持coredump表)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则9: 等价约束检测规则（避免重复写入）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【等价判定维度】
1. 语义等价（最重要）
   ├─ 检测对象相同
   ├─ 检测属性相同
   ├─ 检测阶段相同
   └─ 适用条件相同

2. 描述等价
   ├─ description核心内容一致
   └─ 允许表述方式不同

3. 条件等价
   ├─ applicable_conditions覆盖范围相同
   └─ 允许格式不同（数组vs对象）

【非等价特征】
即使描述相似，以下情况视为不同约束：
├─ 检测阶段不同（T4 vs T6）
├─ 并行维度不同（DP vs TP）
├─ 属性类型不同（cksum vs shape）
└─ 适用范围不同（requires_grad=true vs false）

【等价检测流程】
1. 提取关键特征向量,整个json都作为关键特征


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则10: 格式化处理完整流程
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【格式化执行步骤】
收到约束JSON
  ↓
Step 1: 应用规则1 - Key规范化
  ├─ 去除冗长时间点描述
  ├─ 保留核心技术关键词
  └─ 控制长度≤60字符
  ↓
Step 2: 应用规则2 - Name规范化
  ├─ 添加阶段限定
  ├─ 添加范围限定
  └─ 统一术语格式
  ↓
Step 3: 应用规则3 - Description精简
  ├─ 结构化表述
  ├─ 保留Megatron术语
  └─ 去除冗余描述
  ↓
Step 4: 应用规则4 - Params精简
  ├─ 去除重复字段
  └─ 仅保留必要配置
  ↓
Step 5: 应用规则5 - Conditions对象化
  ├─ 数组→对象转换
  ├─ 字段名标准化
  └─ 操作符标准化
  ↓
Step 6: 应用规则6-7 - 术语和阶段统一
  ├─ Megatron术语标准化
  └─ 阶段名称统一
  ↓
Step 7: 应用规则8 - 字段类型检查
  ├─ type字段枚举验证
  └─ tables固定为["coredump"]
  ↓
Step 8: 应用规则9 - 等价检测
  ├─ 提取特征向量
  ├─ 比对现有约束
  └─ 判定是否等价
  ↓
Step 9: 调用 actual_write_constraint()
  ├─ 如果非等价 → 写入文件
  └─ 如果等价 → 跳过并记录
  ↓
返回写入结果

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则11: 格式化异常处理
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【可能的格式化异常】
1. Key过长异常
   ├─ 检测: len(key) > 60
   ├─ 处理: 自动截断，保留核心技术词

2. 缺失必要字段
   ├─ 检测: 缺少 name/description/type
   ├─ 处理: 从其他字段推断或使用默认值
   └─ 默认: type="consistency", logic="", tables=["coredump"]

3. Conditions格式不规范
   ├─ 检测: 既不是对象也不是数组
   ├─ 处理: 尝试解析字符串，失败则使用 {}
   └─ 示例: "dp>1" → {"dp": "> 1"}

4. 术语拼写错误
   ├─ 检测: 常见错误模式识别
   ├─ 处理: 自动纠正
   └─ 示例: "check_sum" → "cksum", "data_parallel_rank" → "dp_rank"

【异常处理原则】
├─ 宽松解析: 尽量自动修复而非报错
├─ 日志记录: 记录所有格式化调整
├─ 保留原意: 在不改变语义的前提下格式化
└─ 用户提示: 重要调整需告知用户

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则12: 格式化完整示例（端到端）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【原始输入JSON】
{
  "在model-after-backward阶段，所有data parallel组内参数的cksum必须一致检查": {
    "name": "在model-after-backward阶段，所有data parallel组内参数的cksum必须一致",
    "description": "在stage='model-after-backward'时，所有data parallel组内的参数cksum必须一致。该约束用于检测backward后参数被异常修改（如注入攻击）导致的DP组内参数不一致。",
    "type": "consistency",
    "logic": "",
    "tables": ["coredump"],
    "params": {
      "stage": "model-after-backward",
      "object": "主权重参数",
      "cksum": "跨DP组内rank一致"
    },
    "applicable_conditions": [
      "data_parallel_size > 1",
      "参数为模型主权重（非梯度、非optimizer state）"
    ]
  }
}

【格式化后输出JSON（写入文件）】
{
  "backward后DP参数cksum一致性检查": {
    "name": "model-after-backward阶段DP参数cksum一致性检查",
    "description": "在model-after-backward阶段，检查所有data parallel组内参数的cksum一致性。若发现不一致，表明存在同步异常或外部注入错误。",
    "type": "consistency",
    "logic": "",
    "tables": ["coredump"],
    "params": {},
    "applicable_conditions": {
      "dp": "> 1",
      "stage": "= 'model-after-backward'"
    }
  }
}

【格式化规则应用痕迹】
✓ 规则1-Key: "在model-after-backward阶段，所有data parallel组内参数的cksum必须一致检查" 
            (去除冗长描述，简化)
✓ 规则2-Name: 保留阶段完整性"model-after-backward阶段"，统一术语"DP"
✓ 规则3-Description: 精简表述，保留核心技术信息(cksum, data parallel, rank)
✓ 规则4-Params: 去除冗余字段(stage/object/cksum)
✓ 规则5-Conditions: 数组["data_parallel_size > 1"]→对象{"dp": "> 1"}
✓ 规则6-术语: data parallel→DP(大写), cksum(小写), rank(小写)统一
✓ 规则7-阶段: "在model-after-backward阶段"→"model-after-backward阶段"
✓ 规则8-固定: type="consistency", tables=["coredump"]保持
✓ 规则9-等价: 检查现有约束，确认非等价后写入

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 规则13: 格式化效果验证清单
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【验证项目】(每次写入后自动检查)

 1. Key格式验证
   - [ ] 长度 ≤ 60字符
   - [ ] 以"检查"结尾
   - [ ] 不含冗长时间点描述
   - [ ] 包含核心技术关键词

 2. Name字段验证
   - [ ] 包含阶段限定
   - [ ] 包含范围限定
   - [ ] 术语格式正确

 3. Description验证
   - [ ] 包含检测阶段、对象、方法、预期结果
   - [ ] Megatron术语正确保留（cksum/rank/grad等）
   - [ ] 并行策略缩写正确（DP/TP/PP大写）
   - [ ] 阶段名称使用连字符格式

 4. Params验证
   - [ ] 不包含冗余描述性字段
   - [ ] 不与applicable_conditions重复
   - [ ] 仅保留必要配置参数
   - [ ] 空对象使用 {}

 5. Applicable_conditions验证
   - [ ] 使用对象格式（非数组）
   - [ ] 字段名标准化（dp/tp/pp）
   - [ ] 操作符格式正确（"> 1", "= 'value'"）
   - [ ] 不包含描述性文本

 6. 固定字段验证
   - [ ] type ∈ {consistency, validity, completeness, partition}
   - [ ] logic = ""
   - [ ] tables = ["coredump"]

 7. 等价性验证
   - [ ] 已与现有约束比对
   - [ ] 核心特征不重复
   - [ ] Key未重复

 8. 整体一致性验证
   - [ ] JSON格式正确（可解析）
   - [ ] 缩进统一（2空格）
   - [ ] 编码UTF-8

【验证通过标准】
所有项均通过 → 格式化成功，可写入
任一项未通过 → 记录警告，继续尝试修复

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 **格式化规则手册结束** 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 **重要提醒**：
1. **必须在调用 actual_write_constraint() 之前应用上述所有格式化规则**
2. 格式化过程中保持约束的语义完整性，不改变原始约束的检测意图
3. 对于格式化过程中的任何调整，在返回结果中说明调整内容
4. 遇到无法自动修复的格式问题时，在日志中记录并继续处理

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 **支持的约束类别**（基于缺口分析智能推断）：
**现有6类**：
- data_parallel: 数据并行相关
- tensor_parallel: 张量并行相关  
- pipeline_parallel: 流水线并行相关
- zero_optimization: ZeRO优化相关
- model_integrity: 模型完整性相关
- training_progress: 训练进度相关

**扩展类别**（填补训练过程缺口）：
- mixed_precision: 混合精度训练相关（FP16/BF16精度转换、梯度缩放）
- checkpointing_integrity: 检查点完整性相关（模型保存/恢复、状态持久化）
- initialization_validation: 初始化验证相关（权重初始化、随机种子一致性）  
- sequence_parallel: 序列并行相关（长序列处理、注意力并行）
- memory_optimization: 内存优化相关（内存分配策略、缓存管理）
- activation_checkpointing: 激活检查点相关（内存节省、重计算策略）
- data_loading_integrity: 数据加载完整性相关（数据分片、批次一致性）
- validation_consistency: 验证一致性相关（验证集处理、评估指标）

 **智能分类原则**：
- 基于约束的技术特征和训练阶段自动选择最合适的类别
- 优先使用扩展类别填补训练过程缺口
- 确保新约束不与现有约束等价（语义等价，不仅是文本重复）

中文格式要求：
- key: 具体中文描述 + "检查"
- name: 详细中文描述
- description: 中文技术描述，保留英文术语如rank、cksum等
- type: 保持英文（consistency/validity/completeness/partition）
- logic: 空字符串""
- tables: ["coredump"] 
- params: 保持原有参数格式
- applicable_conditions: 保持原有条件格式
"""

    def _report_prompt(self) -> str:
        return f"""你是 report_agent（汇总与标记完成）
输入：write_agent 的写回结果和整个推理过程的总结

## 循环配置
- 当前循环次数：第{{current_iteration}}/{self.max_iterations}轮
- 循环机制：外部控制器自动管理所有轮次

## 你的职责
1. 汇总write_agent的写回结果和推理过程
2. 生成完整报告
3. **标记本轮完成**（循环控制由外部系统管理）

## 输出格式
完整报告，写入context_variables的report_content字段，格式：
- constraints_generated: 写回的约束信息
- report_content: 简要推理链 + 引用清单 + 写回结果
- todolist: 下一候选约束清单

## 完成标记
**完成报告后标记本轮结束**：
调用 `restart_analysis()` - 标记当前轮次完成

**重要**：完成报告后立即调用restart_analysis()函数标记完成状态。
"""

    # Function factories
    def _create_report_functions(self):
        """Create report agent loop control functions."""
        workflow_instance = self
        
        def restart_analysis() -> ReplyResult:
            """Mark current iteration as completed."""
            print(f"[Report Agent] Round {workflow_instance.current_iteration} completed")
            print(f"[Progress] {workflow_instance.current_iteration}/{workflow_instance.max_iterations}")
            
            context_variables = ContextVariables()
            context_variables["workflow_finished"] = True
            context_variables["round_completed"] = True
            context_variables["current_iteration"] = workflow_instance.current_iteration
            
            return ReplyResult(
                message=f"Round {workflow_instance.current_iteration} completed\nworkflow_finished=True",
                context_variables=context_variables,
                target=AgentTarget(workflow_instance.report_agent)
            )
        
        return [restart_analysis]

    def _create_coordinate_functions(self):
        """Create coordinate agent functions"""
        workflow_instance = self

        def go_megatron(context_variables: ContextVariables = None) -> ReplyResult:
            if context_variables is None:
                context_variables = ContextVariables()
            return ReplyResult(message="route→megatron_expert", context_variables=context_variables, target=AgentTarget(workflow_instance.megatron_expert))

        def go_aggregation(research_brief: str = "") -> ReplyResult:
            context_variables = ContextVariables()
            context_variables["research_brief"] = research_brief
            print(f"[COORDINATE] Passing research_brief: {research_brief}")
            return ReplyResult(message=f"route->aggregation_expert, research_brief: {research_brief}", context_variables=context_variables, target=AgentTarget(workflow_instance.aggregation_expert))

        def go_write_agent(constraint_json: str = "", category: str = "", next_candidate: str = "") -> ReplyResult:
            context_variables = ContextVariables()
            context_variables["constraint_json"] = constraint_json
            context_variables["category"] = category
            context_variables["next_candidate"] = next_candidate
            workflow_instance._last_write_payload = {
                "constraint_json": constraint_json,
                "category": category,
                "next_candidate": next_candidate,
            }
            workflow_instance.context_variables["next_candidate"] = next_candidate
            print(f"[COORDINATE] Passing constraint to write_agent: category={category}")
            return ReplyResult(message=f"route->write_agent, constraint_json: {constraint_json[:100]}...", context_variables=context_variables, target=AgentTarget(workflow_instance.write_agent))

        def go_report(context_variables: ContextVariables = None) -> ReplyResult:
            if context_variables is None:
                context_variables = ContextVariables()
            context_variables["workflow_finished"] = True
            return ReplyResult(message="route→report_agent", context_variables=context_variables, target=AgentTarget(workflow_instance.report_agent))

        return [go_megatron, go_aggregation, go_write_agent, go_report]

    def _create_megatron_functions(self):
        """Create megatron expert functions"""
        workflow_instance = self

        def req_research(research_brief: str) -> ReplyResult:
            context_variables = ContextVariables()
            context_variables["needs_research"] = True
            context_variables["research_brief"] = research_brief
            print(f"[MEGATRON] Requesting research: {research_brief}")
            return ReplyResult(message=f"request->aggregation_expert: {research_brief}", context_variables=context_variables, target=AgentTarget(workflow_instance.aggregation_expert))

        def write_constraint(constraint_json: str, category: str, next_candidate: str = "") -> ReplyResult:
            context_variables = ContextVariables()
            context_variables["write_constraint"] = True
            context_variables["constraint_json"] = constraint_json
            context_variables["category"] = category
            context_variables["next_candidate"] = next_candidate
            workflow_instance._last_write_payload = {
                "constraint_json": constraint_json,
                "category": category,
                "next_candidate": next_candidate,
            }
            workflow_instance.context_variables["next_candidate"] = next_candidate
            print(f"[MEGATRON] Submitting constraint write-back: {category}")
            return ReplyResult(message=f"write_constraint->write_agent: {category}", context_variables=context_variables, target=AgentTarget(workflow_instance.write_agent))

        def go_report_from_mega(summary: str = "") -> ReplyResult:
            context_variables = ContextVariables()
            context_variables["finalize_report"] = True
            context_variables["summary"] = summary
            return ReplyResult(message="finalize→report", context_variables=context_variables, target=AgentTarget(workflow_instance.report_agent))

        def analyze_existing_constraints(category_filter: str = "") -> ReplyResult:
            """Analyze existing constraint file and identify gaps in training process.
            
            Args:
                category_filter: Specify constraint category to analyze (e.g., "data_parallel"). Empty means analyze all categories.
            """
            context_variables = ContextVariables()
            
            try:
                # Read existing constraints file
                with open(workflow_instance.constraints_file_path, 'r', encoding='utf-8') as f:
                    constraints_data = json.load(f)
                
                existing_constraints = constraints_data.get('constraints', {})
                
                # Category filtering (if specified)
                if category_filter:
                    if category_filter not in existing_constraints:
                        return ReplyResult(
                            message=f"Category '{category_filter}' not found. Existing categories: {', '.join(existing_constraints.keys())}",
                            context_variables=context_variables
                        )
                    existing_constraints = {category_filter: existing_constraints[category_filter]}
                    print(f"[Analysis] Category filtered: {category_filter}")
                
                # 训练过程阶段定义
                training_stages = {
                    "initialization": ["模型初始化", "权重初始化", "随机种子", "parameter initialization"],
                    "data_loading": ["数据分片", "批次加载", "数据增强", "dataloader", "batch"],
                    "forward_pass": ["前向传播", "激活计算", "attention计算", "forward"],
                    "backward_pass": ["反向传播", "梯度计算", "链式求导", "backward"],
                    "gradient_processing": ["梯度累积", "梯度裁剪", "梯度同步", "gradient"],
                    "optimizer_step": ["参数更新", "学习率调度", "动量更新", "optimizer"],
                    "checkpointing": ["模型保存", "断点恢复", "状态持久化", "checkpoint", "save"],
                    "validation": ["验证集评估", "指标计算", "模型验证", "validation", "eval"],
                    "communication": ["AllReduce", "AllGather", "P2P通信", "communication"],
                    "mixed_precision": ["FP16转换", "梯度缩放", "数值稳定性", "mixed precision", "fp16"],
                    "memory_management": ["内存分配", "缓存管理", "垃圾回收", "memory", "cuda"],
                    "sequence_parallel": ["序列维度切分", "注意力并行", "长序列处理", "sequence parallel"]
                }
                
                # Analyze existing constraint coverage
                covered_areas = set()
                constraint_summary = {}
                
                for category, constraints in existing_constraints.items():
                    constraint_list = []
                    for key, constraint in constraints.items():
                        # Analyze training stages covered by constraints
                        desc_lower = constraint.get("description", "").lower()
                        name_lower = constraint.get("name", "").lower()
                        combined_text = desc_lower + " " + name_lower + " " + key.lower()
                        
                        covered_stages_for_constraint = []
                        for stage_key, keywords in training_stages.items():
                            if any(keyword.lower() in combined_text for keyword in keywords):
                                covered_areas.add(stage_key)
                                covered_stages_for_constraint.append(stage_key)
                        
                        constraint_list.append({
                            "key": key,
                            "name": constraint.get("name", ""),
                            "type": constraint.get("type", ""),
                            "covered_stages": covered_stages_for_constraint,
                            "description_summary": constraint.get("description", "")[:100] + "..."
                        })
                    
                    constraint_summary[category] = {
                        "count": len(constraint_list),
                        "constraints": constraint_list
                    }
                
                # Identify gaps
                uncovered_stages = set(training_stages.keys()) - covered_areas
                
                # Suggest new constraint categories
                suggested_categories = []
                for stage in uncovered_stages:
                    if stage in ["mixed_precision", "sequence_parallel", "memory_management"]:
                        suggested_categories.append(stage)
                    elif stage in ["initialization", "checkpointing"]:
                        suggested_categories.append("model_integrity")
                    elif stage in ["data_loading", "validation"]:
                        suggested_categories.append("training_progress")
                
                analysis_result = {
                    "total_constraints": sum(data["count"] for data in constraint_summary.values()),
                    "categories": list(existing_constraints.keys()),
                    "constraint_summary": constraint_summary,
                    "covered_training_stages": sorted(list(covered_areas)),
                    "uncovered_stages": sorted(list(uncovered_stages)),
                    "suggested_new_categories": list(set(suggested_categories)),
                    "priority_gaps": []
                }
                
                # Build detailed constraint list for deduplication comparison
                existing_constraints_detail = {}
                for category, constraints in existing_constraints.items():
                    existing_constraints_detail[category] = {}
                    for key, constraint in constraints.items():
                        existing_constraints_detail[category][key] = {
                            "name": constraint.get("name", ""),
                            "description": constraint.get("description", ""),
                            "type": constraint.get("type", ""),
                            "applicable_conditions": constraint.get("applicable_conditions", {})
                        }
                
                analysis_result["existing_constraints_detail"] = existing_constraints_detail
                
                # Sort gaps by priority
                priority_mapping = {
                    "mixed_precision": "高优先级 - 混合精度训练常用",
                    "checkpointing": "高优先级 - 长期训练必需",
                    "memory_management": "中优先级 - 大模型训练重要",
                    "initialization": "中优先级 - 影响训练稳定性",
                    "sequence_parallel": "中优先级 - 长序列场景需要",
                    "data_loading": "低优先级 - 相对成熟",
                    "validation": "低优先级 - 较少出错"
                }
                
                for stage in uncovered_stages:
                    priority_info = priority_mapping.get(stage, "低优先级")
                    analysis_result["priority_gaps"].append({
                        "stage": stage,
                        "priority": priority_info,
                        "keywords": training_stages[stage]
                    })
                
                context_variables["existing_constraints_analysis"] = analysis_result
                context_variables["constraints_loaded"] = True
                
                print(f"[Analysis] Constraint analysis completed: {analysis_result['total_constraints']} constraints, {len(uncovered_stages)} gaps")
                print(f"[Analysis] Covered stages: {', '.join(covered_areas)}")
                print(f"[Analysis] Gap stages: {', '.join(uncovered_stages)}")
                print(f"[Analysis] Suggested categories: {', '.join(suggested_categories)}")
                
                # Build detailed analysis report message including existing constraint list
                gap_summary = []
                for gap in analysis_result["priority_gaps"]:
                    gap_summary.append(f"- {gap['stage']}: {gap['priority']}")
                
                # Build existing constraint list summary
                constraints_by_category = []
                for category, constraints in existing_constraints.items():
                    constraint_names = [constraint.get("name", key) for key, constraint in constraints.items()]
                    constraints_by_category.append(f"**{category}** ({len(constraint_names)}):")
                    for name in constraint_names:
                        constraints_by_category.append(f"  - {name}")
                
                # Injection lineage timeline (for guiding constraint validation)
                injection_timeline = """
Error injection lineage (schedules.py:436-470):
- Injection location: within backward_step() function
- Injection timing: T3 (after backward computation -> inject parameters -> before dump)
- Injection target: param (model parameter weights)
- Injection operations: add / scale / zero
- Impact range: T4->T8 all subsequent stages

Injection lineage timeline:
| 时间点 | 阶段 | Stage | 参数状态 | 梯度状态 | DP一致性 |
|--------|------|-------|---------|---------|---------|
| T0 | 训练开始 | - | 干净 | 空 | 一致  |
| T1 | forward_step() | - | 干净 | 空 | 一致  |
| T2 | backward | - | 干净 | 已计算 | 一致  |
| T3 |  注入 | - | 污染 | 已计算 | 不一致  |
| T4 | dump | model-after-backward | 污染 | 已计算 | 不一致  |
| T5 | all-reduce | - | 污染 | 同步后 | 不一致  |
| T6 | dump | model-before-optimizer-step | 污染 | 同步 | 不一致  |
| T7 | optimizer.step() | - | 更新后 | 同步 | 更加不一致  |
| T8 | dump | model-after-optimizer-step | 更新+污染 | 同步 | 不一致  |

**可检测点**: T4/T5/T6/T8 可通过 dump 检测到注入导致的异常"""
                
                filter_info = f"[{category_filter}类别] " if category_filter else ""
                
                analysis_message = f"""{filter_info}现有约束与注入血缘已加载:

**统计信息**:
- 总约束数量: {analysis_result['total_constraints']}个
- 约束类别: {len(analysis_result['categories'])}个 ({', '.join(analysis_result['categories'])})

**现有约束清单** (等价性分析参考):
{chr(10).join(constraints_by_category)}

{injection_timeline}

**你的任务**:
基于上述注入血缘，为 {category_filter or '各类别'} 推理能被验证的约束：
1. 观察哪些时间点的 DP一致性发生变化
2. 推理在这些时间点需要什么约束来检测异常
3. 确保约束的 stage 条件对应正确的检测点
4. 说明约束如何被注入测试验证

**等价性检查要求**（核心）: 
与现有{analysis_result['total_constraints']}个约束对比，确保不等价！

**等价性判断**（满足以下条件即为等价，必须避免）：

1. **检测目标等价**：
   - 检测相同的训练异常/一致性问题（即使方法不同）
   - 例：checksum检测DP一致性 ≈ mean ≈ distribution
   → 都等价！

2. **检测范围等价**：
   - 检测相同的阶段+参数范围+并行维度
   - 例：都在 after-backward 检测所有参数的 DP 一致性
   → 等价！

 **包含关系等价**（ 树状结构）：
   - 如果约束A包含约束B（父子关系），则等价
   - 示例：
     ```
     父：检测所有参数的 DP 一致性
       ├─ 子：检测 attention 参数的 DP 一致性
       ├─ 子：检测 layernorm 参数的 DP 一致性
       └─ 子：检测 mlp 参数的 DP 一致性
     
     判定：有父就不需要子，有子就不需要父（已部分覆盖）
     ```
   
   **策略**：
   -  优先生成"根约束"（覆盖广、效率高）
   -  避免"叶子约束"（覆盖窄、冗余）
   -  寻找当前还没有的根约束

 基于以上定义，自行判断候选约束是否与现有约束等价"""
                
                return ReplyResult(message=analysis_message, context_variables=context_variables)
                
            except Exception as e:
                context_variables["constraints_load_error"] = str(e)
                print(f"[Analysis] ERROR - Constraint file analysis failed: {e}")
                return ReplyResult(message=f"Constraint file analysis failed: {e}", context_variables=context_variables)

        return [req_research, write_constraint, go_report_from_mega, analyze_existing_constraints]

    def _create_aggregation_functions(self):
        """Create aggregation expert functions"""
        workflow_instance = self

        def submit_research(research_content: str = "") -> ReplyResult:
            context_variables = ContextVariables()
            context_variables["research_submitted"] = True
            context_variables["research_content"] = research_content
            print(f"[AGGREGATION] Submitting research results: {research_content[:100]}...")
            return ReplyResult(message=f"research->coordinate: {research_content}", context_variables=context_variables, target=AgentTarget(workflow_instance.coordinate_agent))

        return [submit_research]

    def _create_write_agent_functions(self):
        """Create write agent functions"""
        workflow_instance = self

        def actual_write_constraint(constraint_json: str = "", category: str = "", next_candidate: str = "") -> ReplyResult:
            """Execute actual constraint write operation."""
            context_variables = ContextVariables()
            print(f"[WRITE_AGENT] Starting write operation (iteration {workflow_instance.current_iteration})")
            print(f"[WRITE_AGENT] Category: {category}")
            print(f"[WRITE_AGENT] Constraint JSON length: {len(constraint_json)}")
            
            success_flag, write_result, constraints_written = workflow_instance.write_constraint_to_json(constraint_json, category)
            
            context_variables["write_completed"] = True
            context_variables["write_result"] = write_result
            context_variables["constraints_written"] = constraints_written
            context_variables["write_success"] = success_flag
            context_variables["next_candidate"] = next_candidate
            
            # 存储到workflow实例
            workflow_instance.context_variables["write_completed"] = True
            workflow_instance.context_variables["write_result"] = write_result
            workflow_instance.context_variables["constraints_written"] = constraints_written
            workflow_instance.context_variables["write_success"] = success_flag
            
            if success_flag:
                print(f"[WRITE_AGENT] Successfully wrote {constraints_written} constraints to {category} category (iteration {workflow_instance.current_iteration})")
                lineage = workflow_instance._lineage_route + ["report_agent"]
                context_variables["workflow_finished"] = True
                context_variables["lineage_route"] = lineage
                return ReplyResult(message=f"write_success->report: {write_result}", context_variables=context_variables, target=AgentTarget(workflow_instance.report_agent))
            else:
                print(f"[WRITE_AGENT] Write failed: {write_result} (iteration {workflow_instance.current_iteration})")
                return ReplyResult(message=f"write_failed->coordinate: {write_result}", context_variables=context_variables, target=AgentTarget(workflow_instance.coordinate_agent))

        def write_complete(write_result: str = "", constraints_written: int = 0, success: Optional[bool] = None, todolist: Any = None) -> ReplyResult:
            context_variables = ContextVariables()

            if workflow_instance._last_write_payload:
                constraint_json = workflow_instance._last_write_payload.get("constraint_json", "")
                category = workflow_instance._last_write_payload.get("category", "")
                
                if constraint_json and category:
                    success_flag, write_result, constraints_written = workflow_instance.write_constraint_to_json(constraint_json, category)
                    print(f"[WRITE_AGENT] Write execution: success={success_flag}, result={write_result}")
                else:
                    success_flag = False
                    write_result = "Missing required write parameters"
                    constraints_written = 0
            else:
                success_flag = False
                write_result = "Write data not found"
                constraints_written = 0
            context_variables["write_completed"] = True
            context_variables["write_result"] = write_result
            context_variables["constraints_written"] = constraints_written

            workflow_instance.context_variables["write_completed"] = True
            workflow_instance.context_variables["write_result"] = write_result
            workflow_instance.context_variables["constraints_written"] = constraints_written

            if success is None:
                success_flag = constraints_written > 0
                if not success_flag and isinstance(write_result, str) and write_result:
                    lower_result = write_result.lower()
                    success_flag = "成功" in write_result or "success" in lower_result or "completed" in lower_result
            else:
                success_flag = bool(success)

            context_variables["write_success"] = success_flag
            workflow_instance.context_variables["write_success"] = success_flag

            todo_items: list[str] = []
            if todolist:
                todo_items.extend(workflow_instance._normalize_todolist_payload(todolist))

            stored_next = workflow_instance._last_write_payload.get("next_candidate")
            if stored_next:
                todo_items.extend(workflow_instance._normalize_todolist_payload(stored_next))

            if todo_items:
                deduped: list[str] = []
                for item in todo_items:
                    if item and item not in deduped:
                        deduped.append(item)
                context_variables["todolist"] = deduped
                workflow_instance.context_variables["todolist"] = deduped

            if success_flag:
                lineage = workflow_instance._lineage_route + ["report_agent"]
                context_variables["workflow_finished"] = True
                context_variables["lineage_route"] = lineage
                workflow_instance.context_variables["workflow_finished"] = True
                workflow_instance.context_variables["lineage_route"] = lineage
                print(f"[WRITE_AGENT] Write-back successful: {write_result}")
                return ReplyResult(message=f"write_complete->report: {write_result}", context_variables=context_variables, target=AgentTarget(workflow_instance.report_agent))

            print(f"[WRITE_AGENT] Write-back failed: {write_result}")
            return ReplyResult(message=f"write_retry->coordinate: {write_result}", context_variables=context_variables, target=AgentTarget(workflow_instance.coordinate_agent))

        return [actual_write_constraint, write_complete]

    # Write Agent Implementation
    def write_constraint_to_json(self, constraint_json_str: str, category: str) -> tuple[bool, str, int]:
        """Write agent core functionality: write constraints back to JSON file."""
        try:
            # Parse constraint JSON
            raw_data = json.loads(constraint_json_str)
            
            original_key = None
            if "name" not in raw_data and len(raw_data) == 1:
                # Input format: {"constraint_key": {"name": "...", ...}}
                original_key = list(raw_data.keys())[0]
                constraint_data = raw_data[original_key]
                print(f"[WriteJSON] Detected input with key, extracting: {original_key}")
                print(f"[WriteJSON] Constraint name: {constraint_data.get('name', 'unknown')}")
            elif "name" not in raw_data and len(raw_data) > 1:
                # Input format: {"key1": {...}, "key2": {...}} multiple constraints
                print(f"[WriteJSON] Detected multiple constraints: {len(raw_data)}")
                original_key = list(raw_data.keys())[0]
                constraint_data = raw_data[original_key]
                print(f"[WriteJSON] Processing first constraint: {original_key}")
            else:
                # Input format: {"name": "...", ...}
                constraint_data = raw_data
                print(f"[WriteJSON] Parsed constraint JSON (no key format): {constraint_data.get('name', 'unknown')}")

            # Category mapping and validation
            valid_categories = {
                # Core 6 categories
                "data_parallel", "tensor_parallel", "pipeline_parallel", 
                "zero_optimization", "model_integrity", "training_progress",
                # Extended categories based on training process gap analysis
                "mixed_precision",           # Mixed precision training (FP16/BF16, gradient scaling)
                "checkpointing_integrity",   # Checkpoint integrity (model save/restore, state persistence)
                "initialization_validation", # Initialization validation (weight init, random seed consistency)
                "sequence_parallel",         # Sequence parallelism (long sequence processing, attention parallel)
                "memory_optimization",       # Memory optimization (allocation strategy, cache management)
                "activation_checkpointing",  # Activation checkpointing (memory saving, recomputation)
                "data_loading_integrity",    # Data loading integrity (data sharding, batch consistency)
                "validation_consistency",    # Validation consistency (validation set processing, metrics)
                "communication_optimization", # Communication optimization (bandwidth, latency)
                "distributed_optimizer"      # Distributed optimizer (state distribution, sync strategy)
            }
            
            original_category = category
            if category not in valid_categories:
                # Infer category based on constraint content
                constraint_desc = constraint_data.get("description", "").lower()
                constraint_name = constraint_data.get("name", "").lower()
                
                if any(word in constraint_desc + constraint_name for word in ["混合精度", "fp16", "bf16", "mixed", "precision", "梯度缩放"]):
                    category = "mixed_precision"
                elif any(word in constraint_desc + constraint_name for word in ["检查点", "checkpoint", "模型保存", "断点恢复", "状态持久化"]):
                    category = "checkpointing_integrity"
                elif any(word in constraint_desc + constraint_name for word in ["初始化", "权重初始化", "随机种子", "initialization"]):
                    category = "initialization_validation"
                elif any(word in constraint_desc + constraint_name for word in ["序列并行", "长序列", "注意力并行", "sequence", "sp"]):
                    category = "sequence_parallel"
                elif any(word in constraint_desc + constraint_name for word in ["内存分配", "缓存管理", "memory", "cuda", "内存优化"]):
                    category = "memory_optimization"
                elif any(word in constraint_desc + constraint_name for word in ["激活检查点", "activation", "checkpoint", "重计算"]):
                    category = "activation_checkpointing"
                elif any(word in constraint_desc + constraint_name for word in ["数据分片", "批次", "数据加载", "dataloader", "batch"]):
                    category = "data_loading_integrity"
                elif any(word in constraint_desc + constraint_name for word in ["验证集", "评估指标", "validation", "eval"]):
                    category = "validation_consistency"
                elif any(word in constraint_desc + constraint_name for word in ["通信优化", "带宽", "延迟", "communication"]):
                    category = "communication_optimization"
                elif any(word in constraint_desc + constraint_name for word in ["优化器状态", "分布式优化器", "distributed_optimizer"]):
                    category = "distributed_optimizer"
                # 现有类别匹配
                elif any(word in constraint_desc + constraint_name for word in ["zero", "ZeRO"]):
                    category = "zero_optimization"
                elif any(word in constraint_desc + constraint_name for word in ["tensor", "tp", "张量并行"]):
                    category = "tensor_parallel"
                elif any(word in constraint_desc + constraint_name for word in ["pipeline", "pp", "流水线"]):
                    category = "pipeline_parallel"
                elif any(word in constraint_desc + constraint_name for word in ["data", "dp", "数据并行"]):
                    category = "data_parallel"
                elif any(word in constraint_desc + constraint_name for word in ["训练进度", "损失", "学习率", "梯度范数"]):
                    category = "training_progress"
                else:
                    # Default to model_integrity
                    category = "model_integrity"
                    
            print(f"[WriteJSON] Category mapping: {original_category} -> {category}")

            # Convert to Chinese format
            chinese_constraint = self._convert_to_chinese_format(constraint_data, category, original_key=original_key)
            print(f"[WriteJSON] Conversion completed, generated {len(chinese_constraint)} constraints")
            if original_key:
                print(f"[WriteJSON] Using original key: {original_key}")

            # Load existing constraints
            if not self.chinese_generator.load_and_analyze_patterns():
                return False, "Failed to load existing constraints", 0

            # Build correct JSON structure
            new_constraints = {
                category: chinese_constraint
            }
            print(f"[WriteJSON] Built constraint structure for merge: {category}/{list(chinese_constraint.keys())}")

            # Merge and write back
            merged_data = self.chinese_generator.merge_with_existing_constraints(new_constraints)
            print(f"[WriteJSON] Merge with existing constraints completed")

            if not self.chinese_generator.save_constraints_to_json(merged_data):
                return False, "Failed to save constraints to JSON file", 0

            # Verify integrity
            if not self.chinese_generator.verify_json_integrity():
                return False, "JSON integrity verification failed", 0

            print(f"[WriteJSON] Successfully wrote constraints to {category} category")
            return True, f"Successfully wrote constraints to {category} category", len(chinese_constraint)

        except Exception as e:
            print(f"[WriteJSON] ERROR - Write-back process failed: {e}")
            return False, f"Write-back process failed: {e}", 0

    def _convert_to_chinese_format(self, constraint_data: Dict, category: str, original_key: str = None) -> Dict[str, Dict]:
        """Convert constraint data to Chinese format.
        
        Args:
            constraint_data: Constraint data content
            category: Constraint category
            original_key: Original constraint key (prioritized if provided)
        """
        chinese_constraints = {}

        # Single constraint
        if "name" in constraint_data:
            if original_key:
                chinese_key = original_key
                print(f"[Convert] Using original key: {original_key}")
            else:
                constraint_name = constraint_data.get("name", "")
                chinese_key = self._generate_chinese_key(constraint_name, category)
                print(f"[Convert] Generated new key: {chinese_key}")
            
            chinese_constraints[chinese_key] = self._format_chinese_constraint(constraint_data, category)

        # Constraint list
        elif "constraints" in constraint_data:
            for constraint in constraint_data["constraints"]:
                constraint_name = constraint.get("name", "")
                chinese_key = self._generate_chinese_key(constraint_name, category)
                chinese_constraints[chinese_key] = self._format_chinese_constraint(constraint, category)

        # Other format, try as single constraint
        else:
            if original_key:
                chinese_key = original_key
                print(f"[Convert] Else branch using original key: {original_key}")
            else:
                chinese_key = f"{category}约束检查"
                print(f"[Convert] Else branch generated default key: {chinese_key}")
            chinese_constraints[chinese_key] = self._format_chinese_constraint(constraint_data, category)

        return chinese_constraints

    def _generate_chinese_key(self, constraint_name: str, category: str) -> str:
        """Generate Chinese format constraint key."""
        name_lower = constraint_name.lower()

        # Prioritize using constraint name itself if already appropriate Chinese
        if any('\u4e00' <= char <= '\u9fff' for char in constraint_name):
            if constraint_name.endswith("检查"):
                return constraint_name
            elif "检查" in constraint_name:
                return constraint_name
            else:
                return f"{constraint_name}检查"
        
        # Intelligently generate key based on category and name content
        if category == "data_parallel" or "dp" in name_lower:
            if "parameter" in name_lower or "参数" in constraint_name:
                return "DP参数跨rank一致性检查"
            elif "gradient" in name_lower and "allreduce" in name_lower:
                return "DP梯度AllReduce一致性检查"
            elif "communication" in name_lower:
                return "DP通信完成后参数同步检查"
            elif "requires_grad" in name_lower:
                return "DP requires_grad一致性检查"
            else:
                return "DP参数一致性检查"
                
        elif category == "tensor_parallel" or "tp" in name_lower:
            if "boundary" in name_lower or "边界" in constraint_name:
                return "TP切分边界连续性检查"
            elif "communication" in name_lower or "matrix" in name_lower:
                return "TP通信矩阵维度匹配检查"
            elif "shared_experts" in name_lower:
                return "shared_experts权重不一致性检查"
            elif "layernorm" in name_lower:
                return "LayerNorm权重一致性检查"
            elif "router" in name_lower:
                return "Router权重一致性检查"
            else:
                return "TP参数切分一致性检查"
                
        elif category == "pipeline_parallel" or "pp" in name_lower:
            if "activation" in name_lower or "激活" in constraint_name:
                return "PP激活值传递完整性检查"
            elif "forward" in name_lower and "gradient" in name_lower:
                return "前向阶段梯度应为空检查"
            elif "parameter" in name_lower and "invariant" in name_lower:
                return "前向传播参数不变性检查"
            else:
                return "PP流水线同步检查"
                
        elif category == "zero_optimization":
            if "parameter" in name_lower or "参数" in constraint_name:
                return "ZeRO参数分片一致性检查"
            elif "gradient" in name_lower or "梯度" in constraint_name:
                return "ZeRO梯度累积一致性检查"
            elif "optimizer" in name_lower or "优化器" in constraint_name:
                return "ZeRO优化器状态分片检查"
            else:
                return "ZeRO内存占用优化验证"

        elif category == "model_integrity":
            if "weight" in name_lower or "权重" in constraint_name:
                return "模型权重数值稳定性检查"
            elif "frozen" in name_lower or "冻结" in constraint_name:
                return "冻结参数不更新检查"
            elif "tying" in name_lower or "共享" in constraint_name:
                return "权重共享（weight tying）一致性检查"
            elif "grad_shape" in name_lower or "main_grad" in name_lower:
                return "grad/main_grad 的形状与类型匹配"
            else:
                return "模型完整性检查"
                
        elif category == "training_progress":
            if "loss" in name_lower or "损失" in constraint_name:
                return "训练损失递减趋势检查"
            elif "learning" in name_lower or "学习率" in constraint_name:
                return "学习率调度执行一致性检查"
            elif "gradient" in name_lower and "norm" in name_lower:
                return "梯度范数异常波动检查"
            else:
                return "训练step耗时稳定性检查"

        # Extended categories key generation
        elif category == "activation_checkpointing":
            if "memory" in name_lower:
                return "激活检查点内存优化验证"
            elif "recompute" in name_lower:
                return "激活重计算一致性检查"
            else:
                return "激活值检查点一致性检查"
        elif category == "mixed_precision":
            if "overflow" in name_lower:
                return "混合精度梯度溢出检查"
            elif "scale" in name_lower:
                return "混合精度缩放因子检查"
            else:
                return "混合精度数值稳定性检查"
        elif category == "sequence_parallel":
            if "attention" in name_lower:
                return "序列并行注意力分片检查"
            elif "communication" in name_lower:
                return "序列并行通信一致性检查"
            else:
                return "序列并行分片一致性检查"
        elif category == "memory_optimization":
            if "cuda" in name_lower:
                return "CUDA内存使用优化检查"
            elif "offload" in name_lower:
                return "参数卸载优化验证"
            else:
                return "内存使用优化验证检查"
        elif category == "communication_optimization":
            if "bandwidth" in name_lower:
                return "通信带宽利用率检查"
            elif "overlap" in name_lower:
                return "计算通信重叠效率检查"
            else:
                return "通信优化效率检查"
        elif category == "distributed_optimizer":
            if "state" in name_lower:
                return "分布式优化器状态分片检查"
            elif "synchronization" in name_lower:
                return "优化器同步一致性检查"
            else:
                return "分布式优化器状态检查"
        
        # Default format - use category name
        category_chinese_map = {
            "data_parallel": "数据并行",
            "tensor_parallel": "张量并行", 
            "pipeline_parallel": "流水线并行",
            "zero_optimization": "ZeRO优化",
            "model_integrity": "模型完整性",
            "training_progress": "训练进度",
            "activation_checkpointing": "激活检查点",
            "mixed_precision": "混合精度",
            "sequence_parallel": "序列并行",
            "memory_optimization": "内存优化",
            "communication_optimization": "通信优化",
            "distributed_optimizer": "分布式优化器"
        }
        chinese_category = category_chinese_map.get(category, category)
        return f"{chinese_category}约束检查"

    def _format_chinese_constraint(self, constraint: Dict, category: str) -> Dict:
        """Format as Chinese constraint."""
        return {
            "name": constraint.get("name", f"{category}约束检查"),
            "description": constraint.get("description", f"检查{category}相关的一致性和有效性"),
            "type": constraint.get("type", "consistency"),
            "logic": "",
            "tables": constraint.get("tables", ["coredump"]),
            "params": constraint.get("params", {}),
            "applicable_conditions": constraint.get("applicable_conditions", {})
        }

    # Public API
    def run(self, task: str):
        """Run constraint generation workflow."""
        self._last_write_payload = {}
        self.context_variables["lineage_route"] = list(self._lineage_route)
        
        print("\n" + "="*60)
        print("[Workflow] Starting constraint generation workflow with write-back agent")
        print(f"[Workflow] Loop configuration: max {self.max_iterations} iterations")
        print(f"[Workflow] Task: {task}")
        print("="*60)

        # Main loop: counter-based control
        final_context = None
        while self.current_iteration < self.max_iterations:
            self.current_iteration += 1
            print(f"\n{'='*60}")
            print(f"[Workflow] Iteration {self.current_iteration} starting")
            print(f"{'='*60}")
            
            # Recreate agents each iteration to avoid state accumulation
            print(f"[Workflow] Iteration {self.current_iteration}: Recreating agents, clearing state")
            self._create_agents()
            self.agents = [self.coordinate_agent, self.megatron_expert, 
                          self.aggregation_expert, self.write_agent, self.report_agent]
            
            # Update context with loop information
            self.context_variables["current_iteration"] = self.current_iteration
            self.context_variables["max_iterations"] = self.max_iterations
            
            # Start this iteration's chat session
            final_context = self._start_chat_session(task)
            
            # Check if iteration completed successfully
            if not final_context.get("write_success", False):
                print(f"[Workflow] Iteration {self.current_iteration} write failed, continuing to next iteration")
                continue
            
            print(f"[Workflow] Iteration {self.current_iteration} completed successfully")
        
        print(f"\n[Workflow] All {self.max_iterations} iterations completed")
        
        return self._finalize_context(final_context)

    def _start_chat_session(self, task: str):
        """Start chat session (common for first and subsequent iterations)."""
        print(f"[Chat Session] Creating iteration {self.current_iteration} chat session")
        
        # Create new user agent each iteration
        user = UserProxyAgent(
            name=f"user_round_{self.current_iteration}",
            llm_config=False,
            code_execution_config=False,
            is_termination_msg=lambda m: "workflow_finished" in str(m.get("content",""))
        )
        
        # Dynamic task description
        dynamic_task = self._get_dynamic_task_focus(task)
        
        seed = f"""
This is iteration {self.current_iteration}, focusing on new areas

{dynamic_task}

Execution flow:
1. megatron_expert calls analyze_existing_constraints() to analyze existing constraints
2. Identify gaps, select uncovered checkpoints
3. Request external research via CONTINUE_AGGREGATION
4. Derive new constraints and verify uniqueness
5. Write back to JSON using WRITE_CONSTRAINT
6. Generate final report

Please start analysis, megatron_expert!
        """.strip()
        
        pattern = DefaultPattern(
            initial_agent=self.megatron_expert,
            agents=self.agents,
            context_variables=self.context_variables,
            user_agent=user,
        )
        
        print(f"[Chat Session] Starting iteration {self.current_iteration} chat session from megatron_expert")
        chat_result, final_context, last_agent = initiate_group_chat(
            pattern=pattern, messages=seed, max_rounds=1200
        )
        
        print(f"[Chat Session] Iteration {self.current_iteration} session completed")
        print(f"[Chat Session] Return status: write_success={final_context.get('write_success', False)}")
        
        return final_context

    def _finalize_context(self, final_context):
        """Finalize context processing."""
        print("\n" + "="*60)
        print("[Workflow] Constraint generation workflow completed")
        print(f"[Workflow] Loop statistics: completed {self.current_iteration}/{self.max_iterations} iterations")
        
        # Ensure required keys exist
        if final_context is None:
            print("[WARNING] final_context is None, creating empty context")
            final_context = {}
            
        if "constraints_generated" not in final_context:
            final_context["constraints_generated"] = {}
        if "todolist" not in final_context:
            final_context["todolist"] = []
        if "report_content" not in final_context:
            final_context["report_content"] = ""

        if not final_context.get("todolist"):
            fallback_payload = self._last_write_payload.get("next_candidate")
            fallback_todos = self._normalize_todolist_payload(fallback_payload) if fallback_payload else []
            if fallback_todos:
                final_context["todolist"] = fallback_todos

        if final_context.get("workflow_finished") and "lineage_route" not in final_context:
            final_context["lineage_route"] = self._lineage_route + ["report_agent"]
        elif "lineage_route" not in final_context and self.context_variables.get("lineage_route"):
            final_context["lineage_route"] = list(self.context_variables.get("lineage_route"))
        
        final_context["total_iterations_completed"] = self.current_iteration
        final_context["loop_completed"] = True
        
        print("[Workflow] Final status:")
        print(f"  - workflow_finished: {final_context.get('workflow_finished', False)}")
        print(f"  - loop_completed: {final_context.get('loop_completed', False)}")
        print(f"  - total_iterations: {final_context.get('total_iterations_completed', 0)}")
        print(f"  - write_success: {final_context.get('write_success', False)}")
        print(f"  - constraints_written: {final_context.get('constraints_written', 0)}")
        print("="*60 + "\n")
        
        return final_context

    def _get_dynamic_task_focus(self, base_task: str) -> str:
        """Focus on the data_parallel category, let the LLM reason about constraints based on injected lineage."""
        
        focus_category = "data_parallel"
        focus_description = "Data parallel training constraints"
        
        print(f"[Dynamic Task] Iteration {self.current_iteration}: Focusing on {focus_category} category, reasoning based on injection lineage")
        
        dynamic_task = f"""
Iteration {self.current_iteration} - Focus on {focus_description}

Iteration objective: Generate verifiable constraints for {focus_category} category

Core requirements:

1. Focus category: Only focus on {focus_category}
   - Call: analyze_existing_constraints(category_filter="{focus_category}")
   - Only examine existing constraints and injection lineage for this category
   - Do not consider other categories

2. Reasoning based on injection lineage:
   - Understand injection lineage timeline (T0-T8)
   - Injection at T3 pollutes single DP rank parameter
   - Based on your Megatron training knowledge, reason which checkpoints are important
   - Reason what constraints {focus_category} needs at these points

3. Ensure verifiability:
   - Constraints must detect injection-induced anomalies (DP inconsistency)
   - Clearly specify which checkpoint the constraint applies to (stage condition)
   - Explain how to verify constraint through injection testing

4. Equivalence checking:
   - Compare with existing constraints in {focus_category} category
   - Check for equivalence (not simple text duplication, but semantic equivalence)
   
   Equivalence criteria:
   a) Detection target equivalence:
      Example: checksum detection of DP consistency ≈ mean detection ≈ distribution detection
   
   b) Detection scope equivalence:
      Example: both detect DP consistency for all parameters at after-backward
   
   c) Containment relationship equivalence (tree structure):
      Parent: Detect DP consistency for all parameters
        └─ Child: Detect DP consistency for attention parameters
      → If parent exists, no need for child; if child exists, no need for parent
   
   Strategy:
   - Prioritize generating "root constraints" (broad coverage)
   - Avoid "leaf constraints" (narrow coverage)
   - Find root constraints that don't currently exist
   - If equivalent constraint found, select other gaps

5. Continuous loop optimization:
   - Generate 1-2 constraints per iteration
   - Next iteration loads latest constraints, continues filling gaps
   - Continuously optimize {focus_category} category coverage

Strict limitations:
- Only generate constraints for {focus_category} category
- Do not generate other categories (tensor_parallel, pipeline_parallel, etc.)
- Constraints must relate to injection lineage and be verifiable through injection testing
        """.strip()
        
        return dynamic_task


def main():
    """Main execution function."""
    constraints_file = "C:/Users/15638/gov/governance/workflows/generator/tests/predefined_constraints.json"

    print("Self-Reasoning Workflow with Write Agent")
    print("Routing: megatron -> coordinate -> write_agent -> JSON")
    print("=" * 60)

    generator = WorkflowTaskGenerateWithWriteAgent(constraints_file_path=constraints_file)

    task = """
Collaborative work as "Megatron-LM Forward Training Constraint Reasoner":
Objective: Autonomously propose plausible forward constraints from Megatron training workflow and build reasoning chains.

Focus on tensor parallel parameter sharding mechanism:
- Megatron-LM official documentation/papers on tensor parallel parameter sharding
- Related code snippets (e.g., parameter sharding implementation)
- Conference papers/official blogs on parameter sharding and communication

Key change: After constraint validation is complete, use NEXT_ACTION: WRITE_CONSTRAINT to write directly to JSON file.

Output:
1) Constraints written directly to predefined_constraints.json in Chinese format
2) Complete reasoning chain with reference report
3) Next candidate constraint suggestions
    """

    final_context = generator.run(task)

    print("\n=== Execution Results ===")
    print("Constraints written:", final_context.get("constraints_generated", {}))
    print("Report:", final_context.get("report_content", ""))
    print("Todo:", final_context.get("todolist", []))


if __name__ == "__main__":
    main()




