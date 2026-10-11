# Compositor AI 使用说明

这是基于 [Compositor](https://github.com/robbietilton/Compositor) 开源源码开发的独立 AI 版本，由本仓库维护，非原作者官方版本。手动编辑和 AI 指令直接操作同一份编辑器文档，共用原生撤销记录。

## 安装

1. 准备 Apple Silicon Mac，系统须为 **macOS 26 或更新版本**。
2. 从 [Releases](https://github.com/baichujiang/compositor-ai/releases) 下载 ZIP，解压，将 **Compositor AI.app** 放到“应用程序”。
3. 当前版本是测试预览，仅有临时签名，**尚未通过 Apple 公证**。系统可能拦截来自网络的安装包。确认下载来源后，按 [Apple 官方说明](https://support.apple.com/zh-cn/102445) 为这一个应用授权打开，或自行编译源码。不要全局关闭系统安全检查。
4. 可选 **Codex**、**Antigravity CLI（Google 账号）** 或 **Gemini CLI（Google 登录受限时可用 API Key）**。Codex 可运行 `codex login`，也可登录本机 Codex 桌面应用。Google 账号接入请使用 **Antigravity CLI 1.3.3**，在终端运行 `agy` 完成登录；原 Gemini 接入要求 CLI 0.63.0 或更新版本。详细步骤见下方。每个人使用自己的凭据和额度，本应用不提供共享额度。
5. 用正常的打开/导入功能加载图片或 `.comp` 工程，选择 **显示 → AI 助手**，选择“AI 后端”，在输入框用中文描述修改。

如果没有找到对应 CLI，可在 AI 面板的“设置”中选择其可执行文件。自动查找包含常规路径、`~/.local/bin` 和 NVM 的 Node 目录。“已找到”只代表文件存在，不代表已登录。Codex 实测版本为 0.162.0-alpha.2，Gemini 为 0.63.0，Antigravity 为 1.3.3。Antigravity 的工具限制与输出协议在 CLI 升级时需要复核，本预览固定接受 1.3.3；应用请求中关闭 CLI 自动更新。各后端的可执行文件路径和模型设置分别保存，切换后端清空应用对话及待执行计划，不自动改用其他服务。

### Google 账号：Antigravity CLI

在本项目源码目录运行 `bash scripts/install-antigravity.sh`，会从 Google 下载并校验已测试的官方 CLI 1.3.3，安装到 `~/.local/bin`，不改写 shell 配置或覆盖已有文件。也可按 [Google 官方安装说明](https://antigravity.google/docs/cli/install/) 安装并核对版本。然后在终端运行 `~/.local/bin/agy` 或自己选择的安装路径，在浏览器中使用自己的 Google 账号登录。在 AI 面板选择 **Antigravity CLI**；若未自动找到，请在“设置”里选择登录时运行的 `agy` 文件。安装位置不在 PATH 时，登录也应使用该文件的完整路径。应用使用 CLI 保存的登录，不需要填写 API Key；账号资格、可用模型和额度由 Google 决定。

建议将 CLI 安装在 `~/.local/bin` 等常规位置。开发机实测：放在 Documents 下的 CLI 从应用进程启动时卡在二进制加载阶段，同一个官方文件移出 Documents 后成功。因此供 GUI 应用使用时，应避免将可执行文件保存在 Documents、桌面或下载文件夹中；已有 Google 登录与 CLI 设置无需复制。

从 **Compositor AI 0.4.0** 起支持 **Antigravity CLI 1.3.3**。真实 Google 账号计划已通过原生命令与撤销链路验证，具体结果见发布验证记录。可输入“添加全局曝光调整，曝光值为 0.25”“把选中图层透明度改为 65%”等文字指令。

**当前 Antigravity 接入仅支持文字与图层信息。** 官方流输入只支持文本块，实测 `@canvas.png` 未将图片送到模型。本后端的“附带画布图片”开关不可用并显示原因；需要看图定位时仍可选择 Codex 或 Gemini CLI。手动修图、渲染和原生工具保持完整。

### 原 Gemini CLI

安装 Gemini CLI 需要 Node.js 20 或更新版本；在终端运行：

```sh
npm install -g @google/gemini-cli@0.63.0
gemini
```

登录完成后，在 AI 面板选择 Gemini CLI。设置中的模型名称可以留空，使用 CLI 默认模型；额度不足、登录失败或格式无效会显示错误，不会自动改用其他服务。切换后端会清空应用当前对话和待执行计划。

### Gemini 认证与 Google 登录受限

2026 年 10 月 11 日，个人账号在 Gemini CLI 0.63.0 上收到 Google 的报错，说明该客户端不再支持个人版 Gemini Code Assist。[官方问题记录](https://github.com/google-gemini/gemini-cli/issues/28745) 也有相同情况，但 [认证文档](https://geminicli.com/docs/get-started/authentication/) 仍推荐 Google 登录。安装新版 CLI 并不能保证服务端接受你账号所用的客户端。

现有 Gemini CLI 后端可使用你自己在 [Google AI Studio](https://aistudio.google.com/) 创建的 API Key：运行 `gemini`，选择 **Use Gemini API Key**，只在本机 CLI 的输入框中填写密钥。CLI 0.63.0 会通过它自己的 [凭据存储](https://github.com/google-gemini/gemini-cli/blob/v0.63.0/packages/core/src/core/apiKeyCredentialStorage.ts) 保存密钥，应用之后使用 CLI 已保存的认证。必要时可按官方认证文档配置用户级 `~/.gemini/.env`；仅在终端 `export` 的变量不会自动传给从 Finder 打开的应用。不要提交密钥，也不要把它填到应用的可执行文件路径中。

**API Key 使用独立 API 额度和计费；Google AI 订阅不代表已经包含 API 额度。** 启用付费调用前请查看自己账号的 [额度与计费](https://geminicli.com/docs/resources/quota-and-pricing/)。目前尚未验证真实 API Key 下的模型编辑和看图效果。

Google 提供了 [Antigravity CLI 迁移说明](https://antigravity.google/docs/cli/gcli-migration/)。该客户端使用 `agy`，配置和输出格式与 `gemini` 不同。请在 0.4.0 及以上版本选择独立的 **Antigravity CLI** 后端；直接把 **Gemini CLI** 的可执行文件换成 `agy` 不会完成适配。原 0.3.0 下载包不包含新后端。

## 中文界面与语言切换

0.2.0 起默认使用简体中文，涵盖菜单、工具、参数面板、常用对话框、帮助提示和 AI 设置。需要英文时，在菜单栏选择 **Compositor AI → 界面语言 → English**，然后退出并重新打开应用；选择“简体中文”可切回。语言设置只影响 Compositor AI。

图层名、文件名、输入的文字和 AI 对话内容保留原样，`.comp` 文件格式保持兼容。命令搜索支持中文工具名，也保留工具的英文搜索名。

## 保留原生编辑器

从 0.2.1 起，AI 侧栏默认收起，工具栏恢复上游原有按钮及项目标签区域的宽度分配。“AI 助手”追加在“显示”菜单原有命令之后，不占用原生快捷键；打开后在图层面板旁增加侧栏，关闭后回到原有编辑布局。

开发原则是保留所采用上游版本的完整手动编辑能力，再增加中文和可选 AI 功能。AI 暂不支持的操作仍可使用原生工具完成。后续模型接入共用原生文档、命令校验和撤销系统，不另做一套编辑器。具体差异与升级检查见 [原生兼容约束](native-compatibility.md)。这是开发约束；尚未完成全部功能、所有边界情况及每个界面像素的一致性审计。

## 两种编辑方式

- **手动编辑**：原来的图层、蒙版、画笔、滤镜等工具仍可使用。
- **AI 指令**：例如“把月亮图层透明度改成 65%”“整体稍微提亮”“将选中的图层重命名为前景”。

对于“把月亮放到第二个山尖上”这样的空间指令，需要使用支持画布输入的后端，并勾选 **附带画布图片**，模型才能看到画布。Antigravity 当前只接受文字；Codex 和 Gemini CLI 保留画布入口。图片预览来自编辑器的渲染器，不需要屏幕录制或辅助功能权限。

**自动应用编辑** 默认开启，AI 返回的合法命令会自动应用。关闭它则先显示命令列表，由你点击“应用修改”。一次 AI 编辑对应一次原生撤销，按 ⌘Z 可撤销，⇧⌘Z 可重做。保存和导出仍使用编辑器的常规菜单。

## 首版能力与限制

AI 支持选择、重命名、显隐、不透明度、混合模式，移动/缩放/旋转可见的图像、形状和文字图层，以及曝光、主饱和度、黑白调整、视图缩放和撤销/重做。暂不支持 AI 绘画、生成物体、裁剪、删除图层、整体变换文件夹、自动保存/导出或操作其他软件。这些部分可继续手动操作。

AI 思考期间仍可手动编辑；如果文档改变，旧计划会被拒绝，需要重新发送请求。模型可能理解错误，请检查结果并按需撤销。

## 隐私

请求文字、近期对话和图层信息会通过所选本地 CLI 的账号发送给对应服务。**附带画布图片默认关闭**；开启后额外发送最长边不超过 1400 像素的画布预览，不截取桌面。应用自己的聊天保存在运行内存中，应用创建的请求临时文件完成后删除。CLI 可能另外保留会话或日志，例如 Gemini 自己的 `.gemini` 目录；清空应用聊天不会删除 CLI 或服务端记录。服务端的数据规则取决于所用账号和服务。

Gemini 只返回编辑计划，使用临时工作区、空工具列表、关闭钩子与技能、禁用扩展、独立 MCP 白名单和禁止工具执行的策略。用户输入、图层名称和历史中的 `@` 会编码成 JSON 数据，避免被 CLI 展开成任意文件引用；只有勾选图片选项时，才附带应用生成的画布 PNG。

Antigravity 使用私有临时工作区和独立命名的自定义代理，显式只声明 `finish` 工具，关闭命令执行，MCP、技能和插件依赖声明为空；CLI 1.3.3 的空工具列表会继承默认工具，所以不能用于限制。本应用检查所选代理、终态、结构化计划和实际工具步骤，外部工具步骤不会进入原生编辑。CLI 自己的全局配置和账号模块仍是受信任依赖，应用不改写它们，也不宣称有操作系统级隔离。CLI 还提供内部任务管理工具；代理被要求不使用它，出现相应步骤也会拒绝计划。应用临时文件删除后，CLI 自己的会话记录仍可能保留。

不要把登录凭据或 API Key 发给朋友或上传 GitHub。每个人自行登录。

自动测试默认使用模拟 CLI，不需要账号。Antigravity 另有显式开启的真实 Google 账号测试；CI 不使用个人账号。原 Gemini API Key 下的模型编辑和看图效果仍待验证，不能与 Antigravity 的文字计划验证等同。

## GitHub 跟踪与参与

- 订阅 [Releases](https://github.com/baichujiang/compositor-ai/releases) 获取新预览包。
- 在 [Issues](https://github.com/baichujiang/compositor-ai/issues) 报告问题：附系统版本、应用版本、复现步骤与非敏感示例。
- 开发者可按主 README 编译、运行测试和提交 Pull Request。

本版固定在 Compositor 1.4.8 的源码基线上，保留原 `.comp` 格式 11；不会被官方 Compositor 自动更新替换。后续更新由本项目合并上游改动并测试后发布。正式流畅分发还需要独立的 Developer ID 签名与 Apple 公证。
