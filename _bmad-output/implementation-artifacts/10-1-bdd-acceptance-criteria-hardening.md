# Story 10.1: bdd-acceptance-criteria-hardening

Status: done

## Story

As a 开发者与评审协作方，
I want 关键用户流程的验收标准以 Given/When/Then 形式补全并标准化，
so that 需求表达一致、评审可执行、后续自动化验证可落地。

## Acceptance Criteria

1. 为 E2/E3/E4/E5 的关键 Story 增补 BDD 场景，不删除既有 checklist 验收项。  
2. 每个目标 Story 至少包含 1 条成功路径与 1 条失败/边界路径。  
3. 场景覆盖核心约束：超时、文件锁、降级显示、面板切换。  
4. BDD 文案不包含实现细节（控件 ID、具体 API 调用、内部类名），仅描述业务上下文、用户动作、可观察结果。  
5. 输出后的故事文本可被 `create-story`/`dev-story` 直接消费，无需二次解释。

### BDD 示例（目标风格）

- Given 用户已打开关卡列表且数据已加载  
  When 用户在搜索面板发起视频下载  
  Then 列表状态应在可接受时间内变为“下载中”并可见进度反馈

- Given 目标关卡配置文件被系统占用  
  When 系统尝试写入 `cinema-video.json`  
  Then 应显示可理解的错误提示并提供重试路径

## Tasks / Subtasks

- [x] Task 1: 确定目标故事清单（AC: 1,2）
  - [x] 从 E2/E3/E4/E5 中筛选“关键流程 Story”（列表、搜索下载、配置写入、面板交互）
  - [x] 为每个目标 Story 建立“成功/失败”最小场景对
- [x] Task 2: 编写 BDD 场景并嵌入故事文档（AC: 1,2,3）
  - [x] 逐条补充 Given/When/Then 到对应 Story
  - [x] 校验覆盖超时、文件锁、降级显示、面板切换四类约束
- [x] Task 3: 执行文案质量门禁（AC: 4）
  - [x] 移除实现细节表述，保留业务行为与可观察结果
  - [x] 统一术语（状态名、模块名、用户动作词）
- [x] Task 4: 完成交付核验（AC: 5）
  - [x] 确认故事可直接进入 `dev-story` 流程
  - [x] 将本 Story 状态完成流转并与 sprint-status 同步

## Dev Notes

### 业务背景与目标

- 本 Story 来自 E10（Post-MVP Hardening），用于解决实施就绪报告中的质量缺口：验收标准格式不统一、可测性不足。
- 以规划与文档护栏强化为主；为通过质量门禁，本次同时包含少量运行时代码与测试修正（不引入新功能范围）。

### 关键约束（必须遵守）

- 保持现有故事 checklist，不做替换，只做补全。
- BDD 场景聚焦“用户行为与结果”，避免 UI 细节和技术实现细节。
- 术语需与现有文档一致（如 `cinema-video.json`、Panel、下载状态等）。

### 架构与一致性要求

- 与现有 PRD/Architecture/UX 一致，不引入新功能范围。
- 保持对既有状态机语义的一致引用：
  - Story: `backlog -> ready-for-dev -> in-progress -> review -> done`
- 不修改 E1-E9 的已完成历史。

### 最新实践参考（Web Research 摘要）

- Given/When/Then 应该采用声明式描述，避免命令式和实现耦合。
- 场景需可独立执行，避免“场景依赖场景”。
- 每条验收应可观察、可验证、可量化（尽量带阈值或可判定结果）。
- 覆盖 happy path + edge/failure path，避免“只测成功”。

### 文件结构要求

- 主要编辑目标：
  - `_bmad-output/planning-artifacts/epics.md`（后续补全具体 Story 的 BDD 场景）
  - 如需拆分，也应保持在 `_bmad-output/planning-artifacts/` 下
- 当前故事文件路径：
  - `_bmad-output/implementation-artifacts/10-1-bdd-acceptance-criteria-hardening.md`

### 测试与验证要求

- 本 Story 交付验证以文档检查为主：
  - 每个目标 Story 是否同时具备成功与失败/边界场景
  - 是否覆盖四类关键约束（超时、文件锁、降级、面板切换）
  - 是否存在实现细节污染（如控件名、内部类名、代码级步骤）

### 风险与防呆

- 风险：BDD 写成“伪技术步骤”导致可读性下降  
  - 防呆：统一审查模板，只保留业务上下文、用户动作、结果
- 风险：只补充成功路径  
  - 防呆：强制每个 Story 至少 1 条失败/边界路径
- 风险：与现有术语不一致  
  - 防呆：优先复用 PRD/UX/Architecture 既有命名

## Project Context Reference

- 遵循 `project-context.md` 的关键规则：
  - 所有用户可见文案考虑 L10n 双语一致性
  - 保持模块命名与术语一致，不引入歧义命名
  - 错误处理描述要体现“可理解 + 可重试”原则
- 本 Story 为规划护栏项，不引入新依赖，不改版本，不改运行环境约束。

## Dev Agent Record

### Agent Model Used

GPT-5.3 Codex

### Debug Log References

- create-story workflow
- correct-course proposal and approved updates
- dev-story workflow
- `python` BDD 校验脚本（场景数量 + 约束覆盖）
- `flutter test`
- `flutter analyze`

### Completion Notes List

- 为 `S2.7`、`S3.2`、`S4.4`、`S5.1` 增补了结构化 Given/When/Then 场景（每条至少成功路径 + 失败/边界路径）。
- 已覆盖关键约束：超时、文件占用、降级显示、面板切换。
- 通过脚本化校验确认 BDD 场景与约束覆盖通过（OVERALL PASS）。
- 修复基础测试与静态检查门禁，确保本次交付可通过质量检查。
- code-review 发现的高/中风险项已修复：测试断言有效性、L10n 硬编码、故事描述一致性。

### File List

- `_bmad-output/planning-artifacts/epics.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/10-1-bdd-acceptance-criteria-hardening.md`
- `test/widget_test.dart`
- `lib/main.dart`
- `lib/Modules/CinemaSearch/bloc/cinema_search_bloc.dart`
- `lib/Modules/Panel/sync_calibration_panel.dart`
- `lib/l10n/intl_en.arb`
- `lib/l10n/intl_zh.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_zh.dart`

## Change Log

- 2026-03-21: 完成 Story 10.1 的 BDD 强化交付，补齐关键 Story 场景并完成验证门禁修复。
- 2026-03-21: 完成 code-review 修复并关闭高/中问题，Story 状态更新为 done。

## Senior Developer Review (AI)

### Review Date

2026-03-21

### Reviewer

AI Code Reviewer

### Outcome

Approve

### Findings

- [x] [High] `test/widget_test.dart` 断言过宽，无法有效覆盖启动回归（已改为验证 `MaterialApp` 渲染 + 无异常）。
- [x] [Medium] Story 描述与实际改动范围不一致（已修正文案，明确“以文档为主，含少量门禁修复”）。
- [x] [Medium] `SyncCalibrationPanel` 存在 L10n 硬编码文案（已改为 `AppLocalizations` 键值）。
- [x] [Low] Task 4 子任务文案与实际状态流转不一致（已修正文案）。
