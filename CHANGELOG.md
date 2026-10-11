# Changelog

## 0.5.0 — 2026-10-11 (preview)

- Removed AI chat and panel state from native EditorSession. The app composition root now owns per-tab assistant state and attaches optional UI through generic editor extension hooks; the native editor can run with the empty default hooks.
- Split AI Core, UI and Integration. Assistant planning and its panel use an AIEditorGateway protocol, JSON context, opaque request handles and optional preview data. Native document snapshots, rendering, whole-plan validation and undo execution remain in the adapter.
- Pending plans keep their original gateway. Requests release captures on success, error, cancellation and discard; closing a tab cancels its assistant and detaches its adapter without retaining the native session.
- Added independent compilation of AI Core/UI without native editor sources and a native-dependency check to local tests and GitHub CI, plus gateway, preview and lifecycle regression coverage.
- Preserved the v1 planning protocol, existing provider restrictions and account preferences, manual editing layout/shortcuts, native execution methods, Chinese terminology, independent icon and Compositor 1.4.8 baseline. This is source/protocol separation, not a dynamically loaded binary plugin or automatic upstream compatibility guarantee.

## 0.4.3 — 2026-10-11 (preview)

- Reviewed the Chinese catalog and refined 79 existing translations for tonal controls, vignettes, sampling, masks, selections and filter parameters; documented the terminology and individual changes in `docs/chinese-terminology.md`.
- Added four context-specific display keys so selection Amount, healing Type, Camera Raw Light and perspective-guide clearing do not share misleading translations with filter strength, the text tool, color swatches or canvas guides. Their English display values, enum IDs, shortcuts, actions and layout are preserved.
- Retained the independent 0.4.2 application icon and the adopted Compositor 1.4.8 editing baseline.

## 0.4.2 — 2026-10-11 (preview)

- Replaced the inherited application icon with an independent forest-green icon featuring stacked image canvases and a star, distinguishing Compositor AI from the official editor in Finder, the Dock and the app switcher.
- Updated all macOS AppIcon sizes, with transparent outer corners; added the icon to the English/Chinese project guides and documented its source and generation in `docs/app-icon.md`. Native editor behavior, layout, AI providers and the adopted upstream baseline are unchanged.

## 0.4.1 — 2026-10-11 (preview)

- Clarified Chinese layer Scale as “比例” and canvas-zoom help as “画布缩放”; the actual-pixels button now explains where the current zoom is displayed. Control positions and native navigation behavior are preserved.
- Gave the zoom toolbar icons explicit localized label semantics. After creating a new project, the macOS accessibility snapshot can still duplicate the Zoom In description for Zoom Out; help text and the actual zoom-out action are correct. This remaining description issue is tracked in [#2](https://github.com/baichujiang/compositor-ai/issues/2), and VoiceOver behavior is unverified.
- Added native-handler regression coverage for pinch, Command/Option scrolling, ordinary panning, Zoom-tool clicks/drags, anchor preservation and resize after zoom. Added empty transparent-canvas GPU/Core Graphics comparisons at 100%, 200% and 3200%.
- The user retested a real trackpad pinch in the 0.4.1 Release app on a 1920×1080 canvas, starting at 100%, and confirmed it exceeded 100%; the current canvas status showed 191.4%. Toolbar zoom reached 125% and the Zoom tool reached 200% in separate GUI checks. The original reported cap was not reproduced; this release clarifies labels without changing the renderer, gesture handlers or adopted 1.4.8 baseline. Follow-up is recorded in [#1](https://github.com/baichujiang/compositor-ai/issues/1).

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
