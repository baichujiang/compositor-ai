# Compositor AI

An **unofficial, MIT-licensed fork** of [Compositor](https://github.com/robbietilton/Compositor) with an AI assistant inside the native Mac editor. Manual editing and natural-language commands operate on the same live document and native undo history.

[Downloads](https://github.com/baichujiang/compositor-ai/releases) · [中文使用说明](docs/README.zh-CN.md) · [Report a bug](https://github.com/baichujiang/compositor-ai/issues) · [Architecture](docs/ai-architecture.md)

## Try the preview

1. Use an **Apple Silicon Mac running macOS 26 or later**.
2. Download the ZIP from this repository's Releases, unzip it, and move **Compositor AI.app** to Applications.
3. This preview is **ad hoc signed and not notarized**. macOS may block the download. Follow Apple's [instructions for opening a trusted app](https://support.apple.com/en-us/102445), or build the source yourself. Do not turn off Gatekeeper globally.
4. Install a current [Codex CLI](https://github.com/openai/codex) and run `codex login`, or sign in to the Codex desktop app on this Mac. Each person uses their own account and usage allowance. The app does not include shared AI credits.
5. Open an image or `.comp` project, use the **AI** toolbar button, and describe an edit. For spatial requests, enable **Include canvas image**.

The app finds Codex in standard install locations and in `/Applications/Codex.app` or `/Applications/ChatGPT.app`. For a different installation, choose the executable in AI Settings. A detected executable does not establish that the account is signed in. This preview was verified with Codex CLI 0.162.0-alpha.2; older CLIs may not support its planning flags.

Examples:

- “Set the Moon layer to 65% opacity.”
- “Move the moon above the second mountain peak.” (include the canvas image)
- “Make the whole image a little brighter.”
- “Rename the selected layer to Foreground.”
- “Undo the last edit.”

## Interface language

The editor defaults to **Simplified Chinese**, including menus, tool controls, dialogs and the AI assistant. To use English, choose **Compositor AI → 界面语言 / Interface Language → English**, then quit and reopen the app. The choice is saved for this app only. Document names, layer names, typed text and the `.comp` format remain unchanged. Command search accepts Chinese tool names and their English aliases.

## What AI can do

Select, rename, show/hide, change opacity and blend mode, move, scale, and rotate visible image/shape/text layers; add or update exposure, master saturation and black-and-white adjustments; zoom; undo and redo. Disable **Apply edits automatically** to inspect a proposed command list first.

Every editing request is validated as a complete sequence and becomes one native undo step. If you edit the document while AI is thinking, its stale result is rejected. Saving and exporting use the normal editor controls. AI cannot paint, generate objects, crop, delete layers, transform folders, save/export files, or control other apps in this preview. The full manual editor remains available.

## Privacy and account use

AI sends your text, recent conversation and layer metadata to the service configured by your local Codex login. **Include canvas image** is off by default; enabling it sends a flattened canvas preview up to 1,400 pixels on its long side. It does not capture the desktop. Temporary request files are deleted after each request, and chat is kept in app memory only. Codex's own account and service policies still apply.

No API keys or account tokens are included in this repository or release. Never copy your Codex credentials to friends or GitHub. The process is instructed to return typed JSON only, with shell, browser, app, plugin and computer-use tools disabled and a read-only sandbox. Native code validates and applies the allowed commands. This preview runs without the macOS App Sandbox so it can launch the locally installed CLI and use that CLI's own credentials.

## Build and test

Install Xcode **26.6 or later**, then:

```sh
git clone https://github.com/baichujiang/compositor-ai.git
cd compositor-ai
xcodebuild build -project Compositor.xcodeproj -scheme Compositor   -destination 'platform=macOS,arch=arm64' -configuration Debug   -derivedDataPath build/DerivedData CODE_SIGN_IDENTITY=-
open 'build/DerivedData/Build/Products/Debug/Compositor AI.app'
```

Run `./scripts/test.sh` for the unit suite, including native command validation, undo, stale-document rejection and adjustment preservation. Tests do not need AI credentials. GitHub Actions runs the suite on pushes and pull requests. To build a downloadable preview, run `./scripts/release.sh`; outputs and SHA-256 checksums are placed in `dist/`.

A public release that opens without Gatekeeper's unverified-developer warning requires this project's own Developer ID signing and Apple notarization. Those credentials are not present in this repository. Preview releases are marked prerelease.

## Upstream and compatibility

The AI branch is based on **Compositor 1.4.8**, commit `22c7b8d5b23bb1e27a5746912061b23757c4f554`. The project's default branch is `ai/integrated-assistant`; `main` retains upstream history. AI changes are concentrated in `Compositor/AI/`, with small hooks in the editor UI and session.

The `.comp` format remains version **11**; AI adds ordinary native adjustment layers rather than private file fields. Opening a newer upstream format is subject to the original editor's compatibility rules. Upstream's Sparkle updater was removed, so official Compositor updates cannot replace this build. Compositor AI has its own bundle ID, preferences and release channel and can coexist with Compositor.

See [upstream tracking](UPSTREAM.md), [contributing](CONTRIBUTING.md), and [the original feature list](docs/UPSTREAM-README.md). Upstream updates are reviewed and tested before being adopted; a source fork still requires maintenance for macOS, rendering, file formats and AI dependencies.

## License and credits

Compositor was created by Robbie Tilton / Wonder Assembly LLC. Its MIT license and copyright notice are retained in [LICENSE](LICENSE). Compositor AI is an independent derivative maintained in this repository and is not an official Compositor release. AI additions are also MIT licensed; see [NOTICE](NOTICE).
