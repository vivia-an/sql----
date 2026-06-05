# DeepSeek-V4 发布观察：长上下文与 Agent 之间的“去 CUDA 化”豪赌

> 整理时间：2026-04-24（与 V4 预览版发布同日）
> 资料来源：IT之家、Reuters、AFP/France24、钛媒体、InfoQ、NxCode、Atlas Cloud Blog、纽约时报等公开报道（见文末「引用」）

![DeepSeek 标志（Wikimedia Commons / 公开素材）](https://upload.wikimedia.org/wikipedia/commons/e/ec/DeepSeek_logo.svg)

---

## 一、发布时间线（2025-12 → 2026-04-24）

| 时间点 | 事件 | 出处 |
|--------|------|------|
| 2025-Q4 | 业内开始流传 V4 将于「农历新年/2-3 月」发布 | [钛媒体](https://www.tmtpost.com/7961261.html) |
| 2026-02 | DeepSeek 仅做小幅升级，V4 推迟；Anthropic 公开指控中国实验室「蒸馏攻击」，并把 DeepSeek 列在最前 | [InfoQ](https://www.infoq.cn/article/kN0HD0jPivJBm8JZt8lw) |
| 2026-03 | 路透/CNBC：V4「最快下周发布」，市场担心再现去年 NVIDIA 单日蒸发 6000 亿美元的剧烈波动 | [InfoQ](https://www.infoq.cn/article/kN0HD0jPivJBm8JZt8lw) |
| 2026-04-21 | 钛媒体披露：V4 因为对**华为昇腾**与 **CANN 框架**做深度适配而再次推迟 | [钛媒体](https://www.tmtpost.com/7961261.html) |
| **2026-04-24** | **DeepSeek-V4 预览版正式上线并开源**（V4-Pro / V4-Flash 同步开源） | [IT之家](https://www.ithome.com/0/942/955.htm)、[AFP/France24](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1) |
| 2026-07-24 | 旧版 API 名 `deepseek-chat` / `deepseek-reasoner` 计划停用 | [IT之家](https://www.ithome.com/0/942/955.htm) |

---

## 二、值得肯定的地方

### 1. 把「百万级上下文」变成默认配置
官方公告明确：

> 「DeepSeek-V4 开创了一种全新的注意力机制，在 token 维度进行压缩，结合 **DSA（DeepSeek Sparse Attention）**……从现在开始，**1M（一百万）上下文将是 DeepSeek 所有官方服务的标配**。」 ——[IT之家](https://www.ithome.com/0/942/955.htm)

AFP 也确认了这一点：V4「features an ultra-long context of one million words」（[France24](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1)）。在长文档检索、Agent 多步对话等场景，这是业界第一次把超长上下文以「全产品默认 + 开源 + 低价」形式普及。

### 2. 一次发两款，覆盖「极致质量」与「极致经济」
- **V4-Pro：1.6T 参数**，世界知识仅次于 Google Gemini-Pro-3.1，数学/STEM/竞赛代码「比肩世界顶级闭源模型」；
- **V4-Flash：284B 参数**，简单任务 Agent 表现与 Pro 接近，但 API 价格、推理时延更友好。
（参数与定位见 [France24/AFP 报道](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1)）

### 3. 把 Agent 当一等公民
官方明确针对 **Claude Code / OpenClaw / OpenCode / CodeBuddy** 做了适配，思考模式提供 `reasoning_effort = high / max` 控制思考强度（[IT之家](https://www.ithome.com/0/942/955.htm)）。DeepSeek 内部表态：

> 「使用体验**优于 Sonnet 4.5**，交付质量**接近 Opus 4.6 非思考模式**，但仍与 Opus 4.6 思考模式存在一定差距。」 ——[IT之家](https://www.ithome.com/0/942/955.htm)

### 4. 仍然彻底开源
模型权重同步上 [Hugging Face](https://huggingface.co/deepseek-ai) 与 [ModelScope](https://modelscope.cn)，技术报告随发即可读。AFP 在报道中专门指出：DeepSeek 与 OpenAI 等西方闭源路线形成对照，是「全球开源 AI 生态」的引领者，并引用了中国总理李强在年度会议上的相关表态（[France24](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1)）。

---

## 三、值得期待的方向

1. **稀疏注意力 + token 压缩**带来的成本曲线变化，可能让「百万 context」成为下一代 Agent 框架（Claude Code / OpenClaw 之类）的默认假设，而不是奢侈品。
2. **V4-Flash** 的定价/性能拐点：第三方编程基准对比中，多家媒体把它列入「同档闭源旗舰的 1/N 价位」级别（如 [NxCode 对比](https://www.nxcode.io/zh/resources/news/deepseek-v4-vs-claude-opus-vs-gpt-5-coding-2026)、[GetAIPerks](https://www.getaiperks.com/zh/blogs/30-gpt-5-vs-claude-vs-deepseek-2026)），有可能压缩 OpenAI / Anthropic 在 API 经济上的利润空间。
3. **国产算力链路验证**：钛媒体披露 V4 此次推迟的核心原因之一，就是要在**华为昇腾 + CANN**上做生产级适配。这本身就是中国 AI 第一次在非 CUDA 平台进行系统性「压力测试」（[钛媒体](https://www.tmtpost.com/7961261.html)）。

---

## 四、值得担忧的部分

### 1. 「Benchmark 优于真实世界」的老问题
Anthropic CEO Dario Amodei 在 InfoQ 引述的访谈中直接点名：

> 「许多模型，尤其是来自中国的那些，往往**针对基准测试做了强优化**……当有人设计了一个未公开过、此前从未见过的新基准时，它们的表现就明显下滑。」 ——[InfoQ](https://www.infoq.cn/article/kN0HD0jPivJBm8JZt8lw)

虽然 T3 Chat 创始人 t3dotgg 已逐条反驳了 Anthropic 的「蒸馏攻击」叙事（[InfoQ](https://www.infoq.cn/article/kN0HD0jPivJBm8JZt8lw)），但「公测基准 vs 工程现场」的差距，仍是 V4 需要被独立第三方继续验证的。

### 2. 多模态广度仍非「全能」
[NxCode 对比](https://www.nxcode.io/zh/resources/news/deepseek-v4-vs-claude-opus-vs-gpt-5-coding-2026)、[Evolink 验证](https://evolink.ai/zh/blog/deepseek-v4-vs-gpt-5-4-vs-claude-opus-4-6-verified-comparison) 都提到，V4 在视频、Computer Use 等多模态广度上，相对 GPT-5.4 / Claude Opus 4.6 仍有限。AFP 也只把 V4-Pro 在「世界知识基准」上排到第二（仅次于 Gemini-Pro-3.1）。

### 3. 「兼容 vs 自立」的硬币两面
钛媒体提出最尖锐的质疑：

> 「兼容只能解决『活下来』的问题，真正的自立，才能决定『走多远』。」 ——[钛媒体](https://www.tmtpost.com/7961261.html)

CANN 选择**类 CUDA 兼容层**虽然降低迁移成本（迁移时间从「数周」压到「小时」），但也意味着默认沿用 NVIDIA 定义的范式，遇到 SSM / Mamba / 异步逻辑等「非主流算子」时容易撞到兼容层的天花板。

### 4. 政治与合规风险
就在 V4 发布当天，AFP 同步报道：白宫科技与科学事务负责人 Michael Kratsios 在 X 上指控「外国实体（主要是中国）正在工业化规模地『蒸馏』美国 AI」，并称将「采取措施保护美国创新」（[France24](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1)）。换言之，V4 的开源越成功，可能引来的合规/出口管制压力越大。

---

## 五、对国内的影响

1. **加速国产算力生态成熟**：钛媒体判断，如果昇腾后续芯片能达到 H100 80–90% 的推理性能，叠加 CANN Next 兼容红利，**1–2 年内**有望形成产业级优势（[钛媒体](https://www.tmtpost.com/7961261.html)）。
2. **倒逼云厂商定价**：V4-Flash 的「极致经济」会再次拉低国内 API 平均价格曲线，对豆包、千问、Kimi、MiniMax 等是直接价格压力（参考 [网易早报](https://www.163.com/dy/article/KPJ0J26L05118O8G.html) 中各家日均 token 数据）。
3. **政府/医疗/金融客户的「国产可替代」标签**：AFP 援引中国总理李强的表态指出，DeepSeek 已被多家市政机构、医疗机构与金融行业广泛采用（[France24](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1)）。V4 的「百万 context + Agent 适配」会让这条路径更顺。

---

## 六、对国际的影响

1. **重新唤起「DeepSeek shock」记忆**：AFP 复盘了 2025-01 V3/R1 引发的「Sputnik moment」与 NVIDIA 等 AI 股全面回调（[France24](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1)）；CNBC/Reuters 的 V4 前瞻也提到机构「严阵以待」NVIDIA 是否再现去年单日蒸发 6000 亿美元的场面（[InfoQ](https://www.infoq.cn/article/kN0HD0jPivJBm8JZt8lw)）。
2. **闭源阵营的舆论与法律前置**：Anthropic 对 DeepSeek/Moonshot/MiniMax 的「蒸馏攻击」指控、白宫的「保护美国创新」表态，都是 V4 发布前后形成的「叙事护城河」（[InfoQ](https://www.infoq.cn/article/kN0HD0jPivJBm8JZt8lw)、[France24](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1)）。
3. **开源生态吸引力上升**：[纽约时报](https://www.nytimes.com/2026/04/24/business/china-ai-deepseek-open-source.html) 把 V4 视作「中国在开源 AI 上影响力的延伸」。当一线开源模型在长上下文与 Agentic Coding 上不再落后头部闭源，全球开发者「默认选 Claude/GPT」的惯性会被进一步松动。

---

## 七、一句话总结

> DeepSeek-V4 不是一次单纯的版本迭代，而是「**百万上下文普惠 + Agentic Coding 一等公民 + 国产算力栈生产级验证**」三件事的集中交付。
> 它把「中国开源能不能做到一线」这个问题的答案从「接近」推到「**在多个维度并列**」；
> 但与之相伴的「benchmark 优化质疑」「兼容 vs 自立」「合规与地缘」三个老问题，也一起被推到了下一阶段。

---

## 引用

1. IT之家：[迈入百万上下文普惠时代：DeepSeek-V4 模型预览版正式上线并同步开源（2026-04-24）](https://www.ithome.com/0/942/955.htm)
2. AFP / France24：[China's DeepSeek says releases long-awaited new AI model（2026-04-24）](https://www.france24.com/en/live-news/20260424-china-s-deepseek-says-releases-long-awaited-new-ai-model-1)
3. 钛媒体：[自主还是兼容：DeepSeek V4 延期背后的中国 AI 生态选择题（2026-04-21）](https://www.tmtpost.com/7961261.html)
4. InfoQ：[DeepSeek V4 压顶，Anthropic CEO 先动手了：一场漏洞百出的舆论战（2026-02-26）](https://www.infoq.cn/article/kN0HD0jPivJBm8JZt8lw)
5. NxCode：[DeepSeek V4 vs Claude Opus 4.6 vs GPT-5.4：2026 年 AI 编程模型对比](https://www.nxcode.io/zh/resources/news/deepseek-v4-vs-claude-opus-vs-gpt-5-coding-2026)
6. Evolink：[DeepSeek V4 vs GPT-5.4 vs Claude Opus 4.6：2026 年 3 月官方验证对比](https://evolink.ai/zh/blog/deepseek-v4-vs-gpt-5-4-vs-claude-opus-4-6-verified-comparison)
7. Get AI Perks：[GPT-5.4 vs Claude Opus 4.6 vs DeepSeek V4：2026 年最佳 AI 模型](https://www.getaiperks.com/zh/blogs/30-gpt-5-vs-claude-vs-deepseek-2026)
8. Atlas Cloud Blog：[DeepSeek V4 全网情报汇总：特性、预期发布时间、以及如何在 atlascloud 上使用](https://www.atlascloud.ai/zh/blog/ai-updates/what-is-deepseek-v4)
9. The New York Times：[DeepSeek's Sequel Set to Extend China's Reach in Open-Source（2026-04-24）](https://www.nytimes.com/2026/04/24/business/china-ai-deepseek-open-source.html)
10. Reuters：[China's DeepSeek returns with new model, a year after viral rise（2026-04-24）](https://www.reuters.com/technology/chinas-deepseek-returns-with-new-model-year-after-viral-rise-2026-04-24/)
11. 凤凰网（vivo 端转载）：[DeepSeek V4 来了！梁文锋官宣 4 月下旬发布，万亿参数 + 长期记忆](https://h5.ifeng.com/c/vivoArticle/v002l38qXVGbIZ4jGcMNRC5i2Nohz-_EtGjocslCRg---_B-_hY__)
12. 网易早报：[豆包大模型日均 Token 使用量破 120 万亿 / DeepSeek V4 预计 4 月亮相](https://www.163.com/dy/article/KPJ0J26L05118O8G.html)

> 注：以上内容均为整理自上述公开来源，**模型参数、定价、对比基准等以厂商技术报告与第三方独立评测为准**；本文不构成任何投资建议。
