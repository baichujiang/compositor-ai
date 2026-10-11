# Changelog

## 0.4.1 — 2026-10-11 (preview)

- Clarified Chinese layer Scale as “比例” and canvas-zoom help as “画布缩放”; the actual-pixels button now explains where the current zoom is displayed. Control positions and native navigation behavior are preserved.
- Added explicit accessible names to the zoom buttons so the minus magnifier is announced as Zoom Out in Chinese.
- Added native-handler regression coverage for pinch, Command/Option scrolling, ordinary panning, Zoom-tool clicks/drags, anchor preservation and resize after zoom. Added empty transparent-canvas GPU/Core Graphics comparisons at 100%, 200% and 3200%.
- A reported hardware pinch stopping at 100% was not reproduced in handler tests. GUI checks reached 125% using the toolbar and 200% using the Zoom tool; these do not establish physical trackpad delivery. The renderer, gesture handlers and adopted 1.4.8 baseline are unchanged.

## 0.4.0 — 2026-10-11 (preview)

- Corrected Gemini login guidance after Google rejected the legacy CLI for an individual account, including on CLI 0.63.0. API key authentication uses separate API quotas and billing; Antigravity CLI uses a separate adapter rather than replacing the Gemini executable.
- Recognize the unsupported-client error before generic authentication failures, with English/Chinese migration guidance and regression coverage. This does not change account credentials or native editor behavior.
- Added an independent Antigravity CLI backend for saved Google-account authentication, with executable/model settings and English/Chinese guidance in the existing optional AI panel.
- Pin CLI 1.3.3; generate a custom planning agent with an explicit `finish` allowlist, parse only schema-enforced structured output, reject unexpected streams/tools, and reuse native validation/undo and cancellation limits.
- Antigravity is text-only in this preview. Its CLI stream protocol does not attach the canvas image; the panel explains that limitation and keeps canvas input available for other providers. Native manual tools, layout, shortcuts, rendering and `.comp` format retain their existing behavior.
- Added credential-free Antigravity tests, an optional real Google-account/native-undo test, and an installer for the tested official CLI archive that preserves existing binaries and shell profiles.

## 0.3.0 — 2026-10-11 (preview)

- Added optional Gemini CLI backend alongside the default Codex backend, with separate executable and model settings in Chinese and English.
- Shared typed-plan instructions, strict schema validation and native command/history integration across providers. Provider switching clears app chat and pending plans; no automatic fallback.
- Added one bounded format correction for Gemini, controlled canvas-image attachment, escaped user file-reference syntax, tool restrictions, deadline/output limits and cancel escalation.
- Added credential-free backend/process tests and documented Gemini installation, account use, CLI log retention and the remaining live-account validation gap. Native manual editing, toolbar, menu order, shortcuts and `.comp` format are unchanged by this provider addition.

## 0.2.1 — 2026-10-11 (preview)

- Restored the upstream native toolbar and project-tab width allocation; the AI panel starts closed.
- Appended the AI visibility toggle after native View commands, with no reserved shortcut to interfere with remapped native shortcuts.
- Documented native capability preservation, extension boundaries, known differences and upstream upgrade validation as contributor and agent requirements.

## 0.2.0 — 2026-10-11 (preview)

- Simplified Chinese by default across menus, tools, parameters, dialogs, help and AI controls.
- Saved Chinese/English language choice in the app menu, applied on reopening.
- Chinese command and shortcut search, with English aliases for tools.
- Localized blend-mode labels resolve through stable stored values; document data and command IDs remain compatible.
- Fixed Camera Raw track-click values using the drawn bar rather than AppKit's moving tracking rectangle.
- Native localization coverage for packaged resources, default language, command search and blend-mode mapping.

## 0.1.0 — 2026-10-11 (preview)

- Integrated AI chat panel in the native editor, with optional canvas-image understanding.
- Version-1 typed command API for layers, transforms, adjustments and native history.
- Whole-plan validation, stale-document rejection, and one undo step per editing request.
- Each user supplies their own local Codex login; no shared credentials or hosted backend.
- Independent app identity and release channel, with the upstream updater removed.
- Public source, native tests, CI, preview packaging and bilingual getting-started guide.

Preview: ad hoc signed, not Apple notarized. macOS 26+, Apple Silicon.
