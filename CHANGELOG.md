# Changelog

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
