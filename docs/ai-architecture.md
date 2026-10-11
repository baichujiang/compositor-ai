# Integrated AI architecture

```
Text + current document metadata + optional native canvas render
  → selected local Codex / Gemini CLI / Antigravity CLI using the user’s own authentication
  → shared strict AIPlanningContract (JSON planning only)
  → AIEditPlan v1
  → full validation against the captured document
  → native editor methods inside one DocumentHistory transaction
  → live canvas, native undo/redo, ordinary .comp save/export
```

All adapters implement `AIBackend` and run off the UI thread. `AIBackendProvider` chooses the adapter, and `AIPlanningContract` owns instructions, schema and strict decoding. Provider choice, executable paths and optional models are saved separately; Codex remains the default. Switching providers cancels the current request and discards app history and pending plans, with request IDs rejecting late replies. No automatic provider fallback occurs.

`AICodexBackend` runs with a three-minute deadline and cancel support. The temporary request folder contains the schema, optional preview, response and execution log and is removed afterward. The CLI receives no project paths and has shell/apps/plugins/browser/computer-use tools disabled. These are local model adapters, not a hosted AI service.

`AIGeminiCLIBackend` requires stable CLI 0.63.0 or later. It creates a private temporary workspace with `.gemini/settings.json`, disables core tools, hooks, skills, extensions and external tool discovery, uses a unique MCP allowlist and a deny-all administrator policy, and supplies the shared system instructions. Administrator settings and policies may override workspace restrictions; installed CLI/admin configuration is a trusted dependency, not an OS security sandbox. The CLI remains responsible for its own credentials and logs. `GEMINI_CLI_NO_RELAUNCH=true` prevents a supervisor from swallowing cancellation. System-settings overrides are deliberately not used: official 0.63.0 requires root-owned system configuration files.

Gemini’s JSON envelope is checked for process errors before parsing its response. A format error permits one format-only correction, within the same total 180-second deadline; unsupported commands/versions and document validation errors never trigger correction. Plans are capped at 256 KB, 20 actions and 4,000 reply characters. `AIProcessRunner` uses file-backed I/O, limits stdout/stderr, and escalates termination to SIGKILL after a short grace period. It signals a process group only when the child owns it.

Gemini expands `@file` references before inference independently of its registered tools. Shared request JSON escapes every user-controlled `@` as `\u0040`; format correction output receives the same treatment. The only literal file reference is the generated `@./canvas.png` when image sharing is enabled. Tests with the official 0.63.0 preprocessor verified that the controlled PNG becomes an image part even with an empty tool registry. A signed-in live model response/vision result has not yet been verified.

`AIAntigravityCLIBackend` pins official CLI 1.3.3 and uses its cached Google login. It creates a unique workspace agent with `tools: [finish]`, no declared skill/plugin/MCP dependencies, `subagent: false`, and command execution off. `tools: []` inherits default tools in this CLI and is unsuitable. The agent body uses the shared planning instructions. CLI-global configuration/account machinery remain trusted dependencies and are not rewritten; no OS sandbox is claimed. Its internal `manage_task` tool remains available, so the instructions forbid its use and observed task/external-tool steps reject the plan. The streamed `init.tools` field reports the CLI-wide registry, not the selected agent's actual allowlist.

One NDJSON `user` message carries the request on stdin, with slash/skill expansion disabled. The CLI supplies schema-enforced `structured_output`; its free-text `response` can include extra completion material and is never decoded as a plan. Success requires exit 0, `SUCCESS`, the selected agent, one terminal result, and no unexpected stream or tool steps. The wire schema omits the version's numeric enum because CLI 1.3.3's Google schema conversion rejects it; the shared strict decoder still enforces version 1, exact fields and known actions. A real Google-account exposure plan was checked through the native command/undo bridge. Auto-update is disabled per app request, files are removed afterward, and CLI-owned sessions may persist.

Antigravity streaming input supports text blocks only. An official CLI test of `@./canvas.png` returned “no image,” so this provider explicitly exposes text/layer-metadata input only and rejects direct preview data. The panel shows a disabled, unchecked canvas toggle for it while preserving the user's saved image preference for other providers. Native image rendering/manual tools and other adapters keep their capabilities. CLI children have editor/Xcode dynamic-loader injection variables removed from their inherited environment; their normal account/environment configuration remains available.

`AIDocumentToken` compares the document value and history revision before applying a response. All actions are simulated on a value copy before live mutation; no partial edit occurs if a later command is invalid. Transform commands use native transform commit so linked mask placement and shape redraw keep the editor's behavior. Exposure and saturation reuse existing adjustment data structures. Selection and zoom alone do not create document undo entries.

Coordinates are document pixels with origin at the top left. Move uses absolute unrotated top-left position; scale uses percentage of original source dimensions and keeps the center; rotation is absolute clockwise degrees. Opacity is 0–100 percent, exposure -5–5 stops, master saturation -100–100. Global adjustments are created when layerID is null; supplying a matching adjustment layer ID updates that layer. Groups cannot be transformed by this API yet.

The optional image is rendered by ImageExporter, then resized to at most 1,400 pixels on its long side. To bound preview memory, canvases above 25 megapixels require text-only mode. Images are not desktop screenshots. The app’s conversations are per editor session, in memory, and reset when the session changes documents or provider. CLIs may independently store sessions/logs according to their own settings; app cleanup does not erase those records.

The app has its own bundle identifier and does not use the upstream updater. The macOS App Sandbox is disabled in this preview to allow execution of a user-installed CLI and access to its login. A production distribution needs its own signing/notarization pipeline. No saved-project schema fields were added.

## Native editor boundary

The adopted upstream editor owns rendering, document data, tools, focus, manual shortcuts and history. AI owns request planning, validation and its optional panel; localization owns display text. Provider adapters must return the same typed plan rather than implement their own edits. The panel starts closed, is appended beside the existing Layers panel when requested, and is toggled from the end of the native View menu. It adds no native toolbar control and reserves no shortcut. See [native compatibility](native-compatibility.md) for exceptions and upgrade validation.
