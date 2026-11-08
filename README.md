# plain-zh 平实中文

中文输出的平实性规范，做成 agent skill（纯 Markdown，零依赖，Claude Code / Codex / zcode / Hermes 通用）。

解决的问题是：AI 生成的中文经常出现读者「读不懂、觉得突兀」的表达。真实标本（取自一次实际 AI 输出）：

> 「1. **出身**与它要解决的问题」「**三根柱子**／柱子一」「设计**门面**」「装一个『离众数』的**推进器**」「教具已发话题……开讲」「**一句话带走**」

这些不是孤立的坏词，是四类系统性问题：比喻当术语、英文行话不翻译、自造黑话、课堂拟剧腔。加上更早就被公认的套话、翻案腔、翻译腔，构成完整的问题全景（L0-L4，见下表）。

## 为什么自建

调研了生态里的主力 skill，没有一款覆盖完整问题空间：

| 问题层 | op7418/Humanizer-zh | Fenng/Tech-Doc-Style-Chinese | francoisdp/anti-ai-writing | lieflat-less-ai-tone | **plain-zh** |
|---|---|---|---|---|---|
| L0 经典套话（综上所述、客服腔） | ✓ | 部分 | ✓ | 仅显著项 | ✓ |
| L1 结构信号（翻案腔、同义重命名、衔接连环） | 部分 | ✗ | 部分 | ✓✓ 带数据 | ✓ 移植判据 |
| L2a 比喻当术语（出身、三根柱子） | 部分 | 部分 | ✗ | ✗ 自认判不了 | ✓ 源头限量 |
| L2b 不译行话（brief、tell 混用） | ✗ 规则明确保留英文 | ✓ | ✓ | ✗ | ✓ |
| L2c 自造黑话（众数回归） | 部分 | ✓ | 部分 | 部分 | ✓ |
| L2d 拟剧腔（教具、开讲） | 部分 | ✗ | ✗ | ✗ | ✓ |
| L3 凭空名词、未定义缩写 | ✗ | 部分 | ✓ | ✗ | ✓ |
| L4 受众校准 | ✗ | 部分 | 部分 | ✗ | ✓ |
| 中文原生 | ✓ | ✓ | ✗ | ✓ | ✓ |
| 生成时 + 改稿时双模式 | ✗ | ✗ | ✓ | ✗ | ✓ |

另一个自建理由：lieflat-less-ai-tone 的 270 对配对复测把一批民间智慧翻了案（赋能、闭环等词表差异不显著；序数词小标题、「这意味着」人类用得更多），所以规则必须按证据强度分层，不能堆词表。本项目的每条规则都带证据等级注记（实测／认知／工程／约定）。

## 组成

- `SKILL.md`：完整规范。五组规则 R1-R5（术语纪律、读者校准、结构信号、文体边界、改写纪律），共 22 条，每条带判据、改前改后示例、保留边界
- `POLICY.md`：8 行常驻版，贴入机器级全局指令文件（每台机器一次），写作时塑形
- `tests/`：回归测试标本与预期命中清单

## 安装（一条命令，自动兼容主流 agent）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Gyanesh5/plain-zh/main/install.sh)
```

install.sh 做三件事：规范副本装到 `~/.local/share/plain-zh` → 技能软链进各 agent 的 skills 目录 → 政策块带标记幂等写入各 agent 的全局指令文件。**默认只配置检测到已安装的 agent**，`--all` 预写全部兼容位（之后装新 agent 即生效），重复执行自动去重更新。

| 环境 | 覆盖方式 | 政策载体 |
|---|---|---|
| Claude Code | 自动（检测 `~/.claude`） | `~/.claude/CLAUDE.md` |
| Codex CLI | 自动（检测 `~/.codex`） | `~/.codex/AGENTS.md` |
| OpenCode | 自动（检测 `~/.config/opencode`） | `~/.config/opencode/AGENTS.md` |
| zcode | 自动（检测 `~/.zcode`） | `~/.zcode/AGENTS.md` |
| Gemini CLI | 自动（检测 `~/.gemini`） | `~/.gemini/GEMINI.md` |
| Hermes | 自带通道：`hermes skills install https://raw.githubusercontent.com/Gyanesh5/plain-zh/main/SKILL.md`，POLICY 七条并进 SOUL.md（一次） | SOUL.md |
| Cursor | 项目级：`.cursor/skills/` 里软链 canonical 目录；全局规则手动 | 设置里的全局规则 |
| 网页类（ChatGPT 等） | 无文件系统，手动粘 POLICY.md 进自定义指令（一次） | 自定义指令 |

规则更新只改两处：`cd ~/.local/share/plain-zh && git pull && ./install.sh --update`（各 agent 全自动刷新）+ Hermes 侧重装一次。

**政策只放全局一处**。项目 AGENTS.md 不需要也不应复制这份内容。

## 用法

- 写作前：加载 SKILL.md（生成模式），或只嵌 POLICY.md 常驻
- 成稿后：「用 plain-zh 审阅这段文字」（审阅模式：报告 → 等确认 → 改写 → 前后对照）

## 路线图

- [ ] detect 脚本：可数指标（缩写计数、同词轮换、比喻密度）确定性检测，接 CI
- [ ] 用 tests/ 标本跑通第一轮回归
- [ ] 扩充语料验证：〔约定〕级规则（P4、P15、P16）目前无实验证据，积累标注后升级或修正
- [x] 项目术语表机制（v0.2.0）：生成/审阅前先读项目 CONTEXT.md 或术语对照表，词条视为项目约定
- [x] 评估记录（2026-11-08）：客服腔/意义拔高/排版装饰三类候选规则，经 304 篇真实语料实测全部零真命中（17 处「里程碑」命中均为 milestone 正常术语；emoji 全为 ✅ 状态标记），不加规则——规则等证据，不为假想敌立法

## 许可

MIT
