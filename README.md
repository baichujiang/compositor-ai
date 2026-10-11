# Compositor AI

An **unofficial, MIT-licensed fork** of [Compositor](https://github.com/robbietilton/Compositor) with an AI assistant inside the native Mac editor. Manual editing and natural-language commands operate on the same live document and native undo history.

[Downloads](https://github.com/baichujiang/compositor-ai/releases) · [中文使用说明](docs/README.zh-CN.md) · [Report a bug](https://github.com/baichujiang/compositor-ai/issues) · [Architecture](docs/ai-architecture.md)

## Try the preview

1. Use an **Apple Silicon Mac running macOS 26 or later**.
2. Download the ZIP from this repository's Releases, unzip it, and move **Compositor AI.app** to Applications.
3. This preview is **ad hoc signed and not notarized**. macOS may block the download. Follow Apple's [instructions for opening a trusted app](https://support.apple.com/en-us/102445), or build the source yourself. Do not turn off Gatekeeper globally.
4. Choose **Codex** or **Gemini CLI**. For Codex, install a current [Codex CLI](https://github.com/openai/codex) and run `codex login`, or sign in to the Codex desktop app. For Gemini, install [Gemini CLI](https://geminicli.com/docs/get-started/installation/) **0.63.0 or later**, then run `gemini` in Terminal and authenticate. **Google sign-in can reject this client for individual accounts; see the authentication notes below.** Each person uses their own credentials and usage allowance. The app does not include shared AI credits.
5. Open an image or `.comp` project, choose **View / 显示 → AI Assistant / AI 助手**, select the **AI backend**, and describe an edit. For spatial requests, enable **Include canvas image**.

The app finds both CLIs in standard install locations, including NVM Node installations, and finds Codex in `/Applications/Codex.app` or `/Applications/ChatGPT.app`. For a different installation, choose the executable in AI Settings. A detected executable does not establish that the account is signed in. This preview was verified with Codex CLI 0.162.0-alpha.2; older CLIs may not support its planning flags. Gemini integration was checked against CLI 0.63.0. The Gemini model field is optional; leave it blank for that CLI’s default. Switching providers clears the app conversation and pending commands, and requests never silently fall back to another provider.

### Gemini authentication and unsupported Google sign-in

On October 11, 2026, an individual account using Gemini CLI 0.63.0 received Google's message that this client is no longer supported for Gemini Code Assist for individuals. Similar failures are reported in the [official Gemini CLI issue tracker](https://github.com/google-gemini/gemini-cli/issues/28745), although the [authentication guide](https://geminicli.com/docs/get-started/authentication/) still recommends Google sign-in. Installing a current CLI does not guarantee that Google accepts that client for your account.

For the existing Gemini CLI backend, obtain your own key in [Google AI Studio](https://aistudio.google.com/), run `gemini`, and choose **Use Gemini API Key**. Enter the key only in the local CLI prompt. CLI 0.63.0 stores it through its [credential storage](https://github.com/google-gemini/gemini-cli/blob/v0.63.0/packages/core/src/core/apiKeyCredentialStorage.ts); subsequent app requests use the CLI's saved authentication. If needed, follow the official guide's user-wide `~/.gemini/.env` setup instead of relying only on a shell `export`, which a Finder-launched app does not inherit. Do not commit keys or put them in the app executable-path field. **API key requests have separate API quotas and billing; a Google AI subscription does not establish API credits.** Check [quota and pricing](https://geminicli.com/docs/resources/quota-and-pricing/) for your account before enabling paid usage.

Google provides an [Antigravity CLI migration guide](https://antigravity.google/docs/cli/gcli-migration/). Antigravity uses `agy`, different configuration and different output envelopes. **Compositor AI 0.3.0 does not support Antigravity CLI.** Selecting `agy` as the Gemini executable is not a working migration; it needs a separate adapter through the shared native command bridge. Live Gemini API key editing and Antigravity account authentication have not yet been verified for this app.

Examples:

- “Set the Moon layer to 65% opacity.”
- “Move the moon above the second mountain peak.” (include the canvas image)
- “Make the whole image a little brighter.”
- “Rename the selected layer to Foreground.”
- “Undo the last edit.”

## Interface language

The editor defaults to **Simplified Chinese**, including menus, tool controls, dialogs and the AI assistant. To use English, choose **Compositor AI → 界面语言 / Interface Language → English**, then quit and reopen the app. The choice is saved for this app only. Document names, layer names, typed text and the `.comp` format remain unchanged. Command search accepts Chinese tool names and their English aliases.

The native toolbar, project-tab width allocation, and manual tools retain the upstream layout. The AI panel starts closed and opens only when requested; it uses additional space beside the Layers panel while open. Its menu entry is appended after the native View commands and has no reserved shortcut, so existing and remapped native shortcuts keep their behavior.

## What AI can do

Select, rename, show/hide, change opacity and blend mode, move, scale, and rotate visible image/shape/text layers; add or update exposure, master saturation and black-and-white adjustments; zoom; undo and redo. Disable **Apply edits automatically** to inspect a proposed command list first.

Every editing request is validated as a complete sequence and becomes one native undo step. If you edit the document while AI is thinking, its stale result is rejected. Saving and exporting use the normal editor controls. AI cannot paint, generate objects, crop, delete layers, transform folders, save/export files, or control other apps in this preview. The full manual editor remains available.

## Privacy and account use

AI sends your text, recent conversation and layer metadata through the selected local CLI and its own account. **Include canvas image** is off by default; enabling it sends a flattened canvas preview up to 1,400 pixels on its long side. It does not capture the desktop. The app deletes its temporary request files after each request and keeps its own chat in memory. The CLI and its service may independently retain sessions or logs; Gemini uses its usual local `.gemini` storage. Clearing app chat does not clear CLI or service records. Each provider’s account and service policies still apply.

No API keys or account tokens are included in this repository or release. Never copy credentials to friends or GitHub. Both providers return typed JSON through the same strict schema and native validation. Codex disables shell, browser, app, plugin and computer-use tools in a read-only sandbox. Gemini uses a private generated workspace with an empty core-tool list, disabled hooks and skills, extensions disabled, a unique MCP allowlist, and a deny-all tool policy. User-controlled `@` characters are encoded as JSON data so Gemini cannot expand them into file reads. Only the app-generated canvas PNG is attached when explicitly enabled. Native code applies the allowed commands. This preview runs without the macOS App Sandbox so it can launch the locally installed CLI and use that CLI's own credentials.

## Build and test

Install Xcode **26.6 or later**, then:

```sh
git clone https://github.com/baichujiang/compositor-ai.git
cd compositor-ai
xcodebuild build -project Compositor.xcodeproj -scheme Compositor   -destination 'platform=macOS,arch=arm64' -configuration Debug   -derivedDataPath build/DerivedData CODE_SIGN_IDENTITY=-
open 'build/DerivedData/Build/Products/Debug/Compositor AI.app'
```

Run `./scripts/test.sh` for the unit suite, including native command validation, undo, stale-document rejection and adjustment preservation. Tests do not need AI credentials. Gemini tests use fake local CLIs for schema errors, format correction, cancellation, timeout, provider switching, and native undo. Real CLI configuration and PNG preprocessing were verified with 0.63.0; a signed-in live Gemini edit and model vision result have not yet been verified. GitHub Actions runs the suite on pushes and pull requests. To build a downloadable preview, run `./scripts/release.sh`; outputs and SHA-256 checksums are placed in `dist/`.

A public release that opens without Gatekeeper's unverified-developer warning requires this project's own Developer ID signing and Apple notarization. Those credentials are not present in this repository. Preview releases are marked prerelease.

## Upstream and compatibility

The AI branch is based on **Compositor 1.4.8**, commit `22c7b8d5b23bb1e27a5746912061b23757c4f554`. The project's default branch is `ai/integrated-assistant`; `main` retains upstream history. AI changes are concentrated in `Compositor/AI/`, with small hooks in the editor UI and session.

The `.comp` format remains version **11**; AI adds ordinary native adjustment layers rather than private file fields. Opening a newer upstream format is subject to the original editor's compatibility rules. Upstream's Sparkle updater was removed, so official Compositor updates cannot replace this build. Compositor AI has its own bundle ID, preferences and release channel and can coexist with Compositor.

See [upstream tracking](UPSTREAM.md), [contributing](CONTRIBUTING.md), and [the original feature list](docs/UPSTREAM-README.md). Upstream updates are reviewed and tested before being adopted; a source fork still requires maintenance for macOS, rendering, file formats and AI dependencies.

The development policy is to preserve the full adopted native editor and add optional capabilities through shared native operations. See [native compatibility](docs/native-compatibility.md) for reviewed source areas, intentional differences, and the upgrade checklist. This is a preservation requirement, not a claim of exhaustive behavior or pixel equivalence with every upstream release.

## License and credits

Compositor was created by Robbie Tilton / Wonder Assembly LLC. Its MIT license and copyright notice are retained in [LICENSE](LICENSE). Compositor AI is an independent derivative maintained in this repository and is not an official Compositor release. AI additions are also MIT licensed; see [NOTICE](NOTICE).
