# 指标核查工作流 (Indicator Verification Workflow)

## 概述

该工作流用于自动化BI报表指标核查，通过爬取BI页面数据并与基准指标清单对比，识别差异并生成预警。

## 入口参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `html_url` | string | BI报表页面URL，通过爬虫获取HTML内容 |
| `baseline_list_path` | string | 基准指标清单文件路径（text格式） |

## 工作流血缘图

```mermaid
graph TD
    %% 入口参数
    Input[用户输入<br/>参数1: HTML页面URL<br/>参数2: 基准指标清单文件路径]
    
    Input --> Coordinate[coordinate_agent<br/>协调者<br/>管理上下文变量]
    
    %% 初始化：爬取HTML
    Coordinate -->|路由0: 初始化爬取| Crawler[bi_crawler<br/>BI报表爬虫<br/>使用Selenium]
    Crawler -->|接收URL参数| LoadURL[加载HTML页面URL]
    LoadURL -->|爬取页面| FetchHTML[Selenium爬取<br/>获取完整HTML内容]
    FetchHTML -->|返回HTML| HTMLContent[HTML内容<br/>存储在context中]
    HTMLContent -->|HTML准备完成| Coordinate
    
    %% 初始化：加载基准清单
    Coordinate -->|路由0.5: 加载基准清单| LoadBaseline[读取基准指标清单<br/>从text文件路径]
    LoadBaseline -->|接收文件路径参数| ReadText[读取text文件<br/>解析基准指标清单]
    ReadText -->|解析内容| BaselineList[基准指标清单<br/>baseline_indicator_list<br/>存储在context中]
    BaselineList -->|基准清单准备完成| Coordinate
    
    %% 阶段1: 指标提取和清单初始化
    Coordinate -->|路由1: 提取指标| Extractor[html_extractor_agent<br/>HTML指标提取专家<br/>维护当前指标清单]
    
    Extractor -->|从context读取| GetHTML[获取HTML内容]
    GetHTML -->|解析HTML结构| Parse[解析HTML DOM结构<br/>识别报表元素]
    Parse -->|提取所有指标| ExtractAll[提取所有指标<br/>- 指标名称<br/>- 指标值<br/>- 指标类型]
    ExtractAll -->|生成清单| CurrentList[当前指标清单<br/>current_indicator_list<br/>status: pending]
    CurrentList -->|清单初始化完成| Coordinate
    
    %% 阶段1-2循环: 逐个/批量对比
    Coordinate -->|路由2: 开始对比循环| Extractor
    Extractor -->|检查清单状态| CheckList{清单中是否还有<br/>pending状态的指标?}
    
    CheckList -->|是: 选择待对比指标| Select[选择1-3个指标<br/>status=pending]
    Select -->|发送指标数据| Coordinate
    Coordinate -->|路由3: 对比请求| Comparator[indicator_comparator_agent<br/>指标对比专家]
    
    %% 阶段2: 读取基准清单并对比
    Comparator -->|从context读取| GetBaseline[获取基准指标清单]
    GetBaseline -->|读取text清单内容| ReadBaselineText[读取基准清单]
    ReadBaselineText -->|匹配指标| Match[指标匹配<br/>按名称匹配]
    Match -->|计算差异| Calculate[差异计算<br/>- 绝对差异<br/>- 相对差异<br/>- 百分比差异]
    Calculate -->|判断阈值| Threshold[阈值判断<br/>是否超过预警阈值]
    Threshold -->|返回对比结果| CompareResult[对比结果<br/>- 差异值<br/>- 风险等级]
    CompareResult -->|返回结果| Coordinate
    
    Coordinate -->|路由4: 更新清单| Extractor
    Extractor -->|更新清单状态| UpdateList[更新当前指标清单<br/>status: compared<br/>difference: 差异值]
    UpdateList -->|检查是否全部完成| CheckComplete{所有指标<br/>都已对比完成?}
    
    CheckComplete -->|否: 继续循环| Select
    CheckComplete -->|是: 进入阶段3| Coordinate
    
    %% 阶段3: 深度分析
    Coordinate -->|路由5: 深度分析| Analyzer[difference_analyzer_agent<br/>差异分析专家]
    Analyzer -->|读取完整清单| ReadList[读取已对比的完整清单]
    ReadList -->|分析差异模式| PatternAnalysis[差异模式分析<br/>- 趋势分析<br/>- 异常识别]
    PatternAnalysis -->|风险评估| RiskAssessment[风险评估<br/>- 风险等级<br/>- 影响范围]
    RiskAssessment -->|生成分析报告| AnalysisReport[深度分析报告]
    AnalysisReport -->|返回结果| Coordinate
    
    %% 阶段4: 写入JSON
    Coordinate -->|路由6: 输出预警| Alert[alert_agent<br/>预警输出专家]
    Alert -->|读取分析结果| ReadAnalysis[读取分析报告]
    ReadAnalysis -->|分类预警| Classify[预警分类<br/>- high<br/>- medium<br/>- low]
    Classify -->|格式化数据| Format[格式化预警数据]
    Format -->|写入JSON文件| WriteJSON[写入JSON文件<br/>indicator_check_result.json]
    WriteJSON -->|写入完成| Coordinate
    
    %% 阶段5: 简短汇报
    Coordinate -->|路由7: 生成报告| Report[report_agent<br/>汇总报告]
    Report -->|汇总所有信息| Summary[简短汇报总结]
    Summary -->|生成最终报告| FinalReport[最终报告]
    FinalReport --> End[输出结果]
    
    %% 样式定义
    style Coordinate fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style Crawler fill:#fff4e1,stroke:#e65100,stroke-width:2px
    style Extractor fill:#fff4e1,stroke:#e65100,stroke-width:2px
    style Comparator fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    style Analyzer fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Alert fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    style Report fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    
    style HTMLContent fill:#e3f2fd,stroke:#0277bd,stroke-width:2px,stroke-dasharray: 5 5
    style BaselineList fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,stroke-dasharray: 5 5
    style CurrentList fill:#fff9c4,stroke:#f57f17,stroke-width:2px,stroke-dasharray: 5 5
    
    style CheckList fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    style CheckComplete fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    style Input fill:#f1f8e9,stroke:#33691e,stroke-width:3px
```

## 时序图

```mermaid
sequenceDiagram
    participant User as 用户
    participant Coord as coordinate_agent
    participant Crawler as bi_crawler
    participant Extractor as html_extractor_agent
    participant Comparator as indicator_comparator_agent
    participant Analyzer as difference_analyzer_agent
    participant Alert as alert_agent
    participant Report as report_agent
    
    User->>Coord: 输入: html_url + baseline_list_path
    Coord->>Crawler: 爬取HTML页面
    Crawler-->>Coord: 返回HTML内容
    Coord->>Coord: 读取基准清单text文件
    Coord->>Extractor: 路由1: 提取指标
    Extractor->>Extractor: 解析HTML,生成current_indicator_list
    Extractor-->>Coord: 清单初始化完成
    
    loop 对比循环 (直到所有指标compared)
        Coord->>Extractor: 路由2: 选择待对比指标(1-3个)
        Extractor-->>Coord: 返回待对比指标
        Coord->>Comparator: 路由3: 对比请求
        Comparator->>Comparator: 读取baseline_indicator_list
        Comparator->>Comparator: 匹配并计算差异
        Comparator-->>Coord: 返回对比结果
        Coord->>Extractor: 路由4: 更新清单状态
        Extractor->>Extractor: 更新指标status和difference
        Extractor-->>Coord: 清单更新完成
    end
    
    Coord->>Analyzer: 路由5: 深度分析
    Analyzer->>Analyzer: 分析差异模式,评估风险
    Analyzer-->>Coord: 返回分析报告
    Coord->>Alert: 路由6: 输出预警
    Alert->>Alert: 分类预警,格式化数据
    Alert->>Alert: 写入JSON文件
    Alert-->>Coord: 写入完成
    Coord->>Report: 路由7: 生成报告
    Report->>Report: 汇总信息,生成简短报告
    Report-->>User: 返回最终报告
```

## Agent角色说明

| Agent | 阶段 | 职责 |
|-------|------|------|
| `coordinate_agent` | 全程 | 协调者，管理工作流路由和上下文变量 |
| `html_extractor_agent` | 阶段1 | 从HTML提取指标，维护当前指标清单 |
| `indicator_comparator_agent` | 阶段2 | 读取基准清单，对比指标差异 |
| `difference_analyzer_agent` | 阶段3 | 深度分析差异模式，评估风险 |
| `alert_agent` | 阶段4 | 生成预警，写入JSON文件 |
| `report_agent` | 阶段5 | 生成简短汇报总结 |

## 基准指标清单格式

text文件，CSV格式，示例：

```csv
指标名称,指标值,指标类型,单位,时间范围
门诊人次,838723,门诊指标,人次,2025-11
专家挂号人次,117250,门诊指标,人次,2025-11
出科人次,23993,住院指标,人次,2025-11
```

## 使用方法

### 命令行运行

```bash
cd agents
python workflow_indicator_verification.py "https://hxdmc.wchscu.cn/bi/sso?..." "baseline_indicators.txt"
```

### Python代码调用

```python
from workflow_indicator_verification import IndicatorVerificationWorkflow

# 创建工作流
workflow = IndicatorVerificationWorkflow(
    html_url="https://hxdmc.wchscu.cn/bi/sso?proc=1&action=viewer&...",
    baseline_list_path="baseline_indicators.txt",
    output_dir="."
)

# 运行
result = workflow.run()

# 查看结果
print(f"成功: {result['success']}")
print(f"报告: {result['report']}")
print(f"预警文件: {result['alert_file']}")
```

## 输出文件

| 文件 | 说明 |
|------|------|
| `indicator_check_result.json` | 预警结果JSON文件 |
| `bi_screenshot.png` | 页面截图 |

## 预警输出格式

```json
{
    "check_time": "2026-01-16T10:00:00",
    "source_url": "https://...",
    "baseline_file": "baseline.txt",
    "summary": {
        "total_indicators": 100,
        "with_difference": 15,
        "high_risk_count": 2,
        "medium_risk_count": 8,
        "low_risk_count": 5
    },
    "alerts": [
        {
            "level": "high",
            "indicator_name": "门诊人次",
            "current_value": "937949",
            "baseline_value": "838723",
            "difference_percentage": 11.83,
            "message": "指标门诊人次差异超过15%，需立即核查"
        }
    ]
}
```

## 风险等级定义

| 等级 | 条件 | 说明 |
|------|------|------|
| `high` | 差异 >= 15% | 严重预警，需立即处理 |
| `medium` | 5% <= 差异 < 15% | 一般预警，需关注 |
| `low` | 差异 < 5% | 信息提示 |
