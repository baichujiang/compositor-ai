# 原生能力保留与扩展约束

开发目标：完整保留已采用的 Compositor 原生编辑能力、布局、按键位置和手动交互，在其基础上增加可选 AI 与中文界面。原生编辑器始终可独立使用；模型没有覆盖的功能继续通过原生工具操作。

## 对照基线

- 上游：[robbietilton/Compositor](https://github.com/robbietilton/Compositor)。
- 已采用版本：1.4.8，提交 `22c7b8d5b23bb1e27a5746912061b23757c4f554`。
- 文档格式：`.comp` 版本 11，无 AI 私有字段。
- 0.2.1 恢复上游工具栏按钮与标签区域宽度分配；AI 侧栏默认收起。

这里记录保留要求与已核查的源码边界，不宣称与官方后续版本、所有边界行为或界面像素完全等价。中文文字长度可能影响控件尺寸，但不应改变工具位置、命令含义或按键映射。

## 模块边界

| 部分 | 所有者与要求 |
| --- | --- |
| 渲染、像素处理、画笔、选区、变换、图层和蒙版 | 沿用上游实现，不因 AI 能力范围而删减或另做实现。 |
| 工具栏、项目标签、工具顺序、原生菜单与快捷键 | 保留上游布局和既有项目顺序。新增命令追加到适合的菜单末尾；不得绕过原生冲突系统占用快捷键。 |
| 文档、保存、导入、导出、撤销与重做 | 使用原生模型及历史。保留上游格式迁移和文件限制；AI 不增加文件字段。 |
| 中文界面 | 集中在 `Compositor/Localization/`；UI 调用只翻译显示文字，保留原始枚举、命令 ID、快捷键 ID 以及用户内容。 |
| AI 面板及命令桥 | 集中在 `Compositor/AI/`；仅通过少量会话、视图与菜单钩子接入。侧栏按需打开，可随时关闭；关闭时恢复原有编辑布局。 |
| 模型后端 | Codex、Gemini CLI、Antigravity CLI 负责生成统一的类型化计划，共用校验和原生命令桥，不复制编辑器核心。Claude Code 仍仅保留方案。 |

新增功能若需要调整原生工具，应先说明必要性、列出行为差异，并验证相应手动流程。兼容修复单独记录，方便与上游对比、合并或在上游修复后移除。

## 当前源码核查

对基线的源码对比可复现：

```sh
git diff --stat 22c7b8d5b23bb1e27a5746912061b23757c4f554 -- Compositor
git diff --exit-code 22c7b8d5b23bb1e27a5746912061b23757c4f554 -- Compositor/Rendering
git diff --exit-code 22c7b8d5b23bb1e27a5746912061b23757c4f554 -- Compositor/Document/DocumentHistory.swift Compositor/Document/EditorSession+Brush.swift Compositor/Document/Selection.swift Compositor/Document/SelectionEdits.swift Compositor/Document/LayerTransform.swift Compositor/Document/Filters.swift Compositor/IO/ImageExporter.swift
```

这些原生核心源码与基线一致。0.2.1 的工具栏代码与原生 `ShortcutDefinition` 定义也已逐段对比一致，没有删除任何上游 `Compositor/` 源码文件。`EditorSession` 增加 AI 会话和侧栏状态，PSD 确认文字做本地化；`ContentView` 增加可选侧栏及对话重置钩子。其余原生 UI、项目控制器、蒙版确认与工作区的改动主要是显示文字本地化。混合模式选择将显示标题和存储枚举分离，以保持中文菜单的选择、预览和提交含义；命令搜索增加中文与英文工具名称匹配。

原生功能包括图层与文件夹、混合模式、图层及实时蒙版、裁剪蒙版、变换与自由扭曲、多种选区、画笔与修复、文字与形状、调整层与图层效果、Camera Raw、滤镜、项目标签、原生快捷键设置、导入、保存和导出。详细上游功能表见 [上游 README](UPSTREAM-README.md)。源码沿用与现有回归测试是证据；仍需按下面清单逐项人工核对，才能对完整交互一致性作更强的结论。

## 明确保留的差异

- AI 面板开启时，在原图层面板右侧使用额外空间；关闭后保留原版布局。入口追加在“显示”菜单末尾，不插入工具栏、不改变原生命令相对顺序，也不保留固定 AI 快捷键，以免与用户改键冲突。
- AI 请求增加整批命令校验、过期文档拒绝及一次请求整体撤销。手动操作继续使用原生历史逻辑。
- 0.4.3 修订 79 条中文译文，并为选区像素数、修复方式、Camera Raw 明暗区和清除透视校正线新增上下文翻译键。英文显示值及原始枚举 ID 保持不变，仅修改显示用键；操作、参数范围和布局代码沿用原实现。术语和逐条修订见 [中文术语说明](chinese-terminology.md)。
- 中文、英文选择和中文搜索是显示及搜索增强；用户输入、文件数据和操作语义保持原有含义。
- Camera Raw 滑块点击坐标使用固定的绘制轨道，修正当前 AppKit 跟踪矩形随滑块移动造成的数值偏移。该修复已单独记录在 0.2.0 CHANGELOG，不隐藏为翻译改动。
- 0.4.2 起采用独立的深绿底色、叠加画布与星芒应用图标，替换继承的原版蓝橙渐变图标，以区分 Dock、访达和应用切换器中的两个应用。图标来源和生成方式见 [图标说明](app-icon.md)，编辑器内工具图标及布局沿用已有设计。
- 产品名称、Bundle ID、设置和发布渠道独立。上游 Sparkle 官方更新器未保留，避免将本软件替换为官方 Compositor；当前通过本项目 GitHub Releases 更新。自动更新、正式签名与公证尚不等同于官方分发能力，未来需接入本项目自己的更新渠道和签名。

## 空画布与缩放核查（0.4.1）

- 缩放手势、CanvasViewport、透明格子和像素网格仍沿用 1.4.8 原生源码；0.4.1 仅调整中文说明和缩放图标标签，没有更改倍率计算、手势路由、格子颜色、大小或默认设置。
- 在 0.4.0 发布程序上实际验证：工具栏从 100% 到 125%，左侧缩放工具从 100% 到 200%。新建 1920×1080 透明画布，视觉检查未见与本机官方 1.4.9 的格子样式差异；两者窗口大小不同，“适合窗口”倍率不能直接比较。
- 40×40 测试画布在较大窗口适合显示时可达 3200%。原生像素网格从 800% 起叠加在透明格子上，形成两组不同间距的线。此处没有关闭或重画网格来改变原版行为。
- 原中文将图层 Scale 和画布 Zoom 都译为“缩放”。现在图层 Scale 标为“比例”，帮助说明区分左下角画布倍率；固定 100% 按钮的帮助说明其用于设为实际像素。按钮位置和命令保持原样。
- 新回归测试覆盖捏合跨过 100%、缩放锚点、缩放后调整窗口、⌘ / Option 滚动、普通滚动平移、缩放工具点击与拖动。空透明画布比较 GPU 与 Core Graphics 在两种尺寸和三种倍率下的绘制结果。
- 捏合自动测试使用测试画布内部的事件对象。另在 0.4.1 Release 程序中以 1920×1080 画布、100% 起始倍率和指针位于画布内进行真实触控板复测：用户确认双指向外展开可以超过 100%，当前画布状态读数为 191.4%，缩放工具字段为 191.39。原报告的上限问题未复现；本次修正确定的中文显示歧义，不将其描述为修改了手势算法。复测记录见 [Issue #1](https://github.com/baichujiang/compositor-ai/issues/1)。
- 本次也检查了上游 1.4.8→1.4.9：透明格子和画布倍率范围没有改变；1.4.9 新增的 Command/Control 加中键拖动缩放尚未采用。当前兼容基线仍是 1.4.8。
- 缩放图标增加显式本地化标签；本机 macOS 辅助功能快照在新建项目后仍可能将缩小按钮的描述重复为“放大”。按钮帮助和实际缩小操作已验证正确；该描述问题在 [Issue #2](https://github.com/baichujiang/compositor-ai/issues/2) 单独跟踪，尚未实测 VoiceOver，不列为已解决的交互问题。

## 每次上游升级的验收

1. 记录准确版本、提交与格式版本，比较上游新增、移除或更改的功能；按 UPSTREAM.md 合并，不重建一套编辑器。
2. 检查所有核心差异。原生工具的菜单、工具栏、焦点处理、快捷键定义和默认值保持上游行为；已有用户改键不能被新增 AI 快捷键抢占。
3. AI 关闭时人工核对新建/打开、多标签、工具位置、缩放、全屏、命令搜索、中文/英文和快捷键设置。
4. 人工核对图层/文件夹拖放、蒙版/实时蒙版、混合模式预览、图层效果、变换/自由扭曲、选区、画笔/修复/克隆、文字、形状及渐变；按上游功能表记录结果与未测项。
5. 人工核对调整层、Camera Raw、滤镜预览、裁剪/画布尺寸、常用图像/RAW/PSD 导入，以及 PNG/JPEG/PDF 导出。
6. 保存并重新打开普通工程及包含文字、调整、蒙版的工程；检查原生撤销/重做、外部文件更新与未保存提示。使用安全的示例验证与所采用官方版本的文件兼容；新格式按上游规则验证迁移。
7. 运行 `scripts/test.sh`，完整保留上游测试。中文断言适配显示文字，不降低编辑行为断言；必要修复单独解释。
8. 再开启 AI，验证计划校验、过期文档、原生编辑方法及整体撤销；关闭侧栏、切换项目、进入全屏后仍能正常手动编辑。没有模型账号也能使用完整手动编辑器。
9. 构建安装包并记录测试证据、故意保留的差异和未测项，再更新 UPSTREAM.md 与 CHANGELOG。

自动测试通过不能替代上述人工一致性核对。升级仍需要合并、验证和维护；模块边界减少冲突，不代表自动兼容所有上游变化。

## Gemini backend (0.3.0)

Gemini is an optional provider inside the existing AI panel. Its only editing output is the same `AIEditPlan` used by Codex; document validation, native commands, rendering and history are shared. Provider controls add no native toolbar button, menu command, shortcut or saved-project field. No adopted upstream manual editing code was changed for this integration.

## Antigravity backend (0.4.0)

Antigravity adds another provider within that same optional panel, with independent executable/model preferences. It uses the existing typed plan, document validation and native undo. Its text-only input limitation affects that provider's canvas-sharing toggle; manual image tools/rendering and other providers retain their capabilities. No native toolbar, menu order, shortcut definition, renderer, document/history implementation or `.comp` field changed for this integration.
