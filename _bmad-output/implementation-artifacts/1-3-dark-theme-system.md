# Story 1.3: 暗色主题系统（Surface 色阶 + 语义色 + 难度色 + 8px 网格）

Status: in-progress

## Story

As a 用户,
I want 应用有统一的暗色游戏风格主题，颜色层次清晰且视觉舒适,
so that 长时间使用不会视觉疲劳。

## Acceptance Criteria

1. ThemeData 配置 Material 3 暗色主题，colorSchemeSeed 使用品牌紫
2. 5 层 Surface 色阶：Surface-0 #141422、Surface-1 #1A1A2E、Surface-2 #1E1E35、Surface-3 #24243B、Surface-4 #2A2A42
3. 语义色常量：成功紫 #9B59FF、警告琥珀 #FFA000、错误红 #CF6679、信息青 #80CBC4
4. Beat Saber 难度色静态常量（Easy→Expert+），Expert+ 带 1px 白色边框标识
5. 前景文字色定义（主文字、次文字、禁用文字）满足 WCAG AA 对比度
6. 8px 基础网格间距系统（padding/margin 为 8 的倍数）
7. 主题通过 AppTheme 类统一提供，避免硬编码颜色值

## Dev Agent Record

### Agent Model Used
claude-4.6-opus-high-thinking (Cursor Agent)

### Completion Notes List

### File List
