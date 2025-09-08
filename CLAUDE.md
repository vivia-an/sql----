# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a healthcare data analysis and SQL generation project focusing on multiple hospital systems including:
- **手术麻醉系统** (Surgery and Anesthesia System) - SAM tables
- **输血科系统** (Blood Transfusion System) - BIS/BTS tables  
- **LIS检验系统** (Laboratory Information System) - LIS tables
- **医保飞检系统** (Medical Insurance Inspection) - Dynamic queries
- **体检系统** (Physical Examination System)
- **病理系统** (Pathology System)

The project contains SQL queries, data architecture designs, and AI-powered SQL generation guidance for healthcare analytics.

## Key Architecture Components

### Data Architecture Layers
- **DL层 (Data Lake)**: Raw source system data (BIS_*, LIS_*, SAM_*)
- **DC层 (Data Center)**: Standardized business data models (BTS_*, Apply_*, Fee_*)
- **MDR层 (Master Data Repository)**: Business-oriented analytical themes

### Core Systems Integration
- All queries use **Presto** query engine
- Database naming convention: `hid0101_orcl_operaanesthisa_emrhis` for surgery/anesthesia systems
- All tables require logical deletion filter: `isdeleted = '0'`
- All fields are VARCHAR type in the big data platform
- Chinese field names must be wrapped in double quotes for Presto

## SQL Generation Guidelines

### Core Principles (from AI大模型SQL生成指南.md)
1. **Unified Library Naming**: All surgery/anesthesia tables use `hid0101_orcl_operaanesthisa_emrhis.` prefix
2. **Main Table Strategy**: Primary table is `SAM_ANA` (alias: an) joined with `SAM_APPLY` (alias: t)
3. **Required WHERE Conditions**:
   ```sql
   WHERE t.HEALTH_SERVICE_ORG_ID = 'HXSSMZK'
     AND t.OPER_TYPE = 'ROOM_OPER'  
     AND t.IS_REJECT = '2'
     AND t.S_SSSYZT_DM = '90'
     AND t.isdeleted = '0'
   ```

### Field Mapping Strategy
- Follow the comprehensive field mapping table in `AI大模型SQL生成指南.md:24-40`
- Use proper JOINs based on data requirements (patient info needs `ipi_registration`, surgery details need `sam_reg_op`)
- Apply appropriate `isdeleted = '0'` filters for each joined table

### Blood Lineage Analysis
- **Always analyze field lineage** before generating SQL
- Check for unnecessary JOINs that might reduce data
- Use iterative context gathering when requirements are unclear
- Generate JSON analysis first, then confirm with user before final SQL generation

## Common Development Tasks

### SQL Query Development
1. **Analyze Requirements**: Understand what fields/data are needed
2. **Check Field Lineage**: Use existing documentation to map fields to source tables
3. **Build Progressive JOINs**: Start with core tables, add JOINs as needed
4. **Apply Standard Filters**: Include required WHERE conditions and logical deletion filters
5. **Validate Results**: Check for data completeness and accuracy

### Documentation Patterns
- **Architecture Documents**: Comprehensive data flow diagrams and table structures (see `输血科报表主题数据架构设计方案.md`)
- **Field Mapping Guides**: Detailed field-to-table mappings with business rules
- **Query Examples**: Working SQL with explanations and comments

## Important Business Rules

### Surgery/Anesthesia System (SAM)
- Core relationship: `SAM_ANA.SAM_APPLY_ID = SAM_APPLY.ID`
- Patient info requires `ipi_registration` join
- Surgery details require `sam_reg` and `sam_reg_op` joins  
- Doctor info requires `hrm_employee` joins with appropriate aliases

### Blood Transfusion System (BTS/BIS)
- Three-layer architecture: DL → DC → MDR
- Monthly comparison analysis (current vs last month vs year-over-year)
- Complex work volume calculations across 4 categories
- Revenue categorization: blood fees, testing fees, treatment fees

### Data Quality Requirements
- **Completeness**: All core fields must have >95% completeness rate
- **Consistency**: Cross-system data must align within 1% variance
- **Timeliness**: Data updates must be within 24 hours of source changes

## Technology Stack

- **Query Engine**: Presto
- **Data Platform**: Big Data Platform with standardized naming
- **Languages**: SQL (primary), Python (utilities), JavaScript (web components)
- **Documentation**: Markdown with Mermaid diagrams

## Cursor Rules Integration

The project includes Cursor AI rules in `.cursor/rules/sql-generator.mdc` that enforce:
- Field lineage analysis requirements
- Presto SQL generation standards
- Iterative context gathering for complex requirements
- JSON-based requirement analysis workflow

## File Organization

```
├── AI大模型SQL生成指南.md          # Core SQL generation methodology
├── *主题数据架构设计方案.md         # System architecture documents  
├── 医保飞检动态查询数据集/           # Medical insurance dynamic queries
├── 手麻/                          # Surgery/anesthesia queries
├── 输血/                          # Blood transfusion queries
├── 病理/                          # Pathology queries
├── 体检/                          # Physical examination queries
└── *.sql files                    # Working SQL queries with examples
```

When working with this codebase:
1. Always reference the appropriate architecture document first
2. Follow the established naming conventions and filtering patterns
3. Validate field lineage before generating new SQL
4. Test queries incrementally, building from core tables outward
5. Document any new field mappings or business rules discovered

字段没找到，就把没找到的列和有歧义取值字段的列列出来，并在结果中标识，切记，不要胡编乱造

最后需要检查分析现有实现的sql血缘，看有没有多余的关联会导致数据减少，如果有多余的关联需要去除。

分析需求血缘，看能否实现，如果分析不行需要额外上下文，交互式的补充上下文，深入分析，形成json，然后要问我再次确认修改需要我提供的上下文，然后我再次提供，然后你再进行生成。如此迭代

当前系统表结构的表已集成到大数据平台，所有查询都适配presto查询，所有库名都 涉及到 手术麻醉的，修改为 hid0101_orcl_operaanesthisa_emrhis 没有明确说是手术麻醉的不用修改，所有表都添加逻辑删除字段的帅选  isdeleted = '0' 的筛选条件，然后生成可执行presto sql,优先按照血缘查询，如果血缘查询不到，再按照表结构查询，注意，集成到大数据的字段全都是varchar类型，注意日期 等的处理。标注字段最终来源，Presto对于中文字段名需要用双引号包围，然后再满足以下需求：

当前集成的表层次是dl->dc->mdr

不过一般查询是查dl或dc
dc是datacenter_db用来汇聚dl数据字段，对应的字段都在 Datacenter目录下的datacenter文件中
是按领域划分的

preto语法,因为当前大数据构建都是在presto中完成的


如果是his查询 添加库名为 hid0101_cache_his_dhcapp_sqluser
如果是 datacenter 查询 添加库名 datacenter_db 


所有字段都要有准确的来源 

先分析血缘和我交互 得到你不清楚的地方，然后再生成sql

