# Compositor AI

<img src="Compositor/Assets.xcassets/AppIcon.appiconset/app-icon-128.png" width="96" height="96" alt="Compositor AI">

Since 0.4.2, Compositor AI uses its own green icon with stacked canvases and a star, distinct from the official Compositor icon.

An **unofficial, MIT-licensed fork** of [Compositor](https://github.com/robbietilton/Compositor) with an AI assistant inside the native Mac editor. Manual editing and natural-language commands operate on the same live document and native undo history.

[Downloads](https://github.com/baichujiang/compositor-ai/releases) · [中文使用说明](docs/README.zh-CN.md) · [Report a bug](https://github.com/baichujiang/compositor-ai/issues) · [Architecture](docs/ai-architecture.md)

Chinese labels and help follow a context-aware editing glossary; see [Chinese terminology and translation revisions](docs/chinese-terminology.md).

## Try the preview

1. Use an **Apple Silicon Mac running macOS 26 or later**.
2. Download the ZIP from this repository's Releases, unzip it, and move **Compositor AI.app** to Applications.
3. This preview is **ad hoc signed and not notarized**. macOS may block the download. Follow Apple's [instructions for opening a trusted app](https://support.apple.com/en-us/102445), or build the source yourself. Do not turn off Gatekeeper globally.
4. Choose **Codex**, **Antigravity CLI** (Google account) or **Gemini CLI** (API key if Google sign-in is rejected). For Codex, install a current [Codex CLI](https://github.com/openai/codex) and run `codex login`, or sign in to the Codex desktop app. For Google account authentication, use **Antigravity CLI 1.3.3** and run `agy` in Terminal. The legacy Gemini adapter requires **Gemini CLI 0.63.0 or later**. See the authentication notes below. Each person uses their own credentials and usage allowance. The app does not include shared AI credits.
5. Open an image or `.comp` project, choose **View / 显示 → AI Assistant / AI 助手**, select the **AI backend**, and describe an edit. For spatial requests, choose a provider with canvas input and enable **Include canvas image**. Antigravity is text-only in this preview.

The app finds `codex`, `gemini` and `agy` in standard install locations, including `~/.local/bin` and NVM Node installations, and finds Codex in `/Applications/Codex.app` or `/Applications/ChatGPT.app`. For a different installation, choose the executable in AI Settings. A detected executable does not establish that the account is signed in. Codex was checked with CLI 0.162.0-alpha.2, Gemini with 0.63.0, and Antigravity with 1.3.3. Antigravity is pinned to that tested version because its agent restrictions and stream format need verification on upgrades. CLI auto-update is disabled for app requests. Each model field is optional and provider-specific. Switching providers clears the app conversation and pending commands, and requests never silently fall back to another provider.

### Google account: Antigravity CLI

From a source checkout, run `bash scripts/install-antigravity.sh` to install the tested official CLI 1.3.3 in `~/.local/bin` with a checksum check, without changing shell profiles or overwriting an existing executable. Alternatively use Google's [official Antigravity CLI instructions](https://antigravity.google/docs/cli/install/) and check the installed version. Run `~/.local/bin/agy` (or your chosen path) in Terminal and complete the Google browser login. Select **Antigravity CLI** in the existing AI panel and select the `agy` executable in Settings if auto-discovery does not find it. For an installation outside PATH, use that same absolute executable path to log in. No API key is required by the app; the CLI owns the saved login. Google determines account eligibility, models and usage allowances.

Use a normal CLI install location such as `~/.local/bin`. On the development Mac, a CLI under Documents stalled during app-launched binary loading, while the same official binary outside Documents worked. Avoid storing the executable inside Documents/Desktop/Downloads when setting up GUI use; Google login and CLI preferences do not need to be copied.

Compositor AI 0.4.0 supports **Antigravity CLI 1.3.3**. A real authenticated Google-account plan was verified through the shared native command and undo bridge; see the release validation record. This adapter currently accepts **text and layer metadata only**. CLI streaming input accepts only text blocks, and a live test confirmed that an `@canvas.png` reference did not supply an image. The canvas toggle is unavailable for this provider, with an explanation; other providers keep their existing image input.

### Gemini authentication and unsupported Google sign-in

On October 11, 2026, an individual account using Gemini CLI 0.63.0 received Google's message that this client is no longer supported for Gemini Code Assist for individuals. Similar failures are reported in the [official Gemini CLI issue tracker](https://github.com/google-gemini/gemini-cli/issues/28745), although the [authentication guide](https://geminicli.com/docs/get-started/authentication/) still recommends Google sign-in. Installing a current CLI does not guarantee that Google accepts that client for your account.

For the existing Gemini CLI backend, obtain your own key in [Google AI Studio](https://aistudio.google.com/), run `gemini`, and choose **Use Gemini API Key**. Enter the key only in the local CLI prompt. CLI 0.63.0 stores it through its [credential storage](https://github.com/google-gemini/gemini-cli/blob/v0.63.0/packages/core/src/core/apiKeyCredentialStorage.ts); subsequent app requests use the CLI's saved authentication. If needed, follow the official guide's user-wide `~/.gemini/.env` setup instead of relying only on a shell `export`, which a Finder-launched app does not inherit. Do not commit keys or put them in the app executable-path field. **API key requests have separate API quotas and billing; a Google AI subscription does not establish API credits.** Check [quota and pricing](https://geminicli.com/docs/resources/quota-and-pricing/) for your account before enabling paid usage.

Google provides an [Antigravity CLI migration guide](https://antigravity.google/docs/cli/gcli-migration/). Antigravity uses `agy`, different configuration and different output envelopes. Use the separate **Antigravity CLI** backend added in 0.4.0; selecting `agy` as the **Gemini CLI** executable is not a working migration. Earlier 0.3.0 downloads do not contain the Antigravity adapter. Live Gemini API key editing remains unverified.

Examples:

- “Set the Moon layer to 65% opacity.”
- “Move the moon above the second mountain peak.” (include the canvas image)
- “Make the whole image a little brighter.”
- “Rename the selected layer to Foreground.”
- “Undo the last edit.”

## Interface language

The editor defaults to **Simplified Chinese**, including menus, tool controls, dialogs and the AI assistant. To use English, choose **Compositor AI → 界面语言 / Interface Language → English**, then quit and reopen the app. The choice is saved for this app only. Document names, layer names, typed text and the `.comp` format remain unchanged. Command search accepts Chinese tool names and their English aliases.

The native toolbar, project-tab width allocation, and manual tools retain the upstream layout. The AI panel starts closed and opens only when requested; it uses additional space beside the Layers panel while open. Its menu entry is appended after the native View commands and has no reserved shortcut, so existing and remapped native shortcuts keep their behavior.

Canvas zoom is shown at the lower left and in the Zoom tool's percentage field. The Transform header's Scale is the layer scale; in Chinese 0.4.1 labels it “比例”. The fixed **100%** toolbar button sets actual-pixel zoom. Pinch or hold Command/Option while scrolling to zoom; ordinary scrolling pans. The adopted native zoom range is 0.1–3200%, with a pixel-grid overlay from 800% when enabled in View.

## What AI can do

Select, rename, show/hide, change opacity and blend mode, move, scale, and rotate visible image/shape/text layers; add or update exposure, master saturation and black-and-white adjustments; zoom; undo and redo. Disable **Apply edits automatically** to inspect a proposed command list first.

Every editing request is validated as a complete sequence and becomes one native undo step. If you edit the document while AI is thinking, its stale result is rejected. Saving and exporting use the normal editor controls. AI cannot paint, generate objects, crop, delete layers, transform folders, save/export files, or control other apps in this preview. The full manual editor remains available.

## Privacy and account use

AI sends your text, recent conversation and layer metadata through the selected local CLI and its own account. **Include canvas image** is off by default; enabling it sends a flattened canvas preview up to 1,400 pixels on its long side. It does not capture the desktop. The app deletes its temporary request files after each request and keeps its own chat in memory. The CLI and its service may independently retain sessions or logs; Gemini uses its usual local `.gemini` storage. Clearing app chat does not clear CLI or service records. Each provider’s account and service policies still apply.

No API keys or account tokens are included in this repository or release. Never copy credentials to friends or GitHub. All providers return typed JSON through the same strict schema and native validation. Codex disables shell, browser, app, plugin and computer-use tools in a read-only sandbox. Gemini uses a private generated workspace with an empty core-tool list, disabled hooks and skills, extensions disabled, a unique MCP allowlist, and a deny-all tool policy. User-controlled `@` characters are encoded as JSON data so Gemini cannot expand them into file reads. Only the app-generated canvas PNG is attached when explicitly enabled. Native code applies the allowed commands. This preview runs without the macOS App Sandbox so it can launch the locally installed CLI and use that CLI's own credentials.

Antigravity uses a private generated workspace and an explicitly selected custom agent with only `finish` allowed, empty declared MCP/skill/plugin dependencies, and command execution off. An empty agent tool list inherits default tools in CLI 1.3.3, so it is deliberately not used. The app checks the selected agent, terminal status, structured output and observed tool steps; external tool steps never produce native edits. The CLI's own global configuration and account machinery remain trusted dependencies; the adapter does not rewrite them or claim an OS sandbox. CLI 1.3.3 also exposes an internal task-management tool; the planner is instructed not to use it, and any observed task-management step is rejected. Antigravity sessions may remain in its own storage even after the app removes its temporary files.

## Build and test

Install Xcode **26.6 or later**, then:

```sh
git clone https://github.com/baichujiang/compositor-ai.git
cd compositor-ai
xcodebuild build -project Compositor.xcodeproj -scheme Compositor   -destination 'platform=macOS,arch=arm64' -configuration Debug   -derivedDataPath build/DerivedData CODE_SIGN_IDENTITY=-
open 'build/DerivedData/Build/Products/Debug/Compositor AI.app'
```

Run `./scripts/test.sh` for the credential-free suite, including native command validation, undo, stale-document rejection and adjustment preservation. Fake CLI tests cover schema errors, malformed streams, format correction, cancellation, timeout, provider switching, and native undo. Antigravity has an optional live Google-account test enabled only by `TEST_RUNNER_COMPOSITOR_AI_TEST_AGY=/absolute/path/to/agy` when running `xcodebuild test`; CI does not have account credentials. Real Gemini CLI configuration and PNG preprocessing were verified with 0.63.0; a signed-in live Gemini API key edit and vision result remain unverified. GitHub Actions runs the suite on pushes and pull requests. To build a downloadable preview, run `./scripts/release.sh`; outputs and SHA-256 checksums are placed in `dist/`.

A public release that opens without Gatekeeper's unverified-developer warning requires this project's own Developer ID signing and Apple notarization. Those credentials are not present in this repository. Preview releases are marked prerelease.

## Upstream and compatibility

The AI branch is based on **Compositor 1.4.8**, commit `22c7b8d5b23bb1e27a5746912061b23757c4f554`. The project's default branch is `ai/integrated-assistant`; `main` retains upstream history. AI Core/UI use an editor gateway protocol and are compiled independently of native editor sources in CI. Native dependencies live in `Compositor/AI/Integration/`; EditorSession owns no AI state. The app attaches the optional panel through generic UI hooks. See [the dependency boundary](docs/ai-decoupling.md).

The `.comp` format remains version **11**; AI adds ordinary native adjustment layers rather than private file fields. Opening a newer upstream format is subject to the original editor's compatibility rules. Upstream's Sparkle updater was removed, so official Compositor updates cannot replace this build. Compositor AI has its own bundle ID, preferences and release channel and can coexist with Compositor.

See [upstream tracking](UPSTREAM.md), [contributing](CONTRIBUTING.md), and [the original feature list](docs/UPSTREAM-README.md). Upstream updates are reviewed and tested before being adopted; a source fork still requires maintenance for macOS, rendering, file formats and AI dependencies.

The development policy is to preserve the full adopted native editor and add optional capabilities through shared native operations. See [native compatibility](docs/native-compatibility.md) for reviewed source areas, intentional differences, and the upgrade checklist. This is a preservation requirement, not a claim of exhaustive behavior or pixel equivalence with every upstream release.

## License and credits

Compositor was created by Robbie Tilton / Wonder Assembly LLC. Its MIT license and copyright notice are retained in [LICENSE](LICENSE). Compositor AI is an independent derivative maintained in this repository and is not an official Compositor release. AI additions are also MIT licensed; see [NOTICE](NOTICE).
