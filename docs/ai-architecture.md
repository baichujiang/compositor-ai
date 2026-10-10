# Integrated AI architecture

```
Text + current document metadata + optional native canvas render
  → local Codex CLI using the user's own login (JSON planning only)
  → AIEditPlan v1
  → full validation against the captured document
  → native editor methods inside one DocumentHistory transaction
  → live canvas, native undo/redo, ordinary .comp save/export
```

`AICodexBackend` runs off the UI thread with a three-minute deadline and cancel support. The temporary request folder contains the schema, optional preview, response and execution log and is removed afterward. The CLI receives no project paths and has shell/apps/plugins/browser/computer-use tools disabled. This is a model adapter, not a hosted AI service.

`AIDocumentToken` compares the document value and history revision before applying a response. All actions are simulated on a value copy before live mutation; no partial edit occurs if a later command is invalid. Transform commands use native transform commit so linked mask placement and shape redraw keep the editor's behavior. Exposure and saturation reuse existing adjustment data structures. Selection and zoom alone do not create document undo entries.

Coordinates are document pixels with origin at the top left. Move uses absolute unrotated top-left position; scale uses percentage of original source dimensions and keeps the center; rotation is absolute clockwise degrees. Opacity is 0–100 percent, exposure -5–5 stops, master saturation -100–100. Global adjustments are created when layerID is null; supplying a matching adjustment layer ID updates that layer. Groups cannot be transformed by this API yet.

The optional image is rendered by ImageExporter, then resized to at most 1,400 pixels on its long side. To bound preview memory, canvases above 25 megapixels require text-only mode. Images are not desktop screenshots. Conversations are per editor session, in memory, and reset when the session changes documents.

The app has its own bundle identifier and does not use the upstream updater. The macOS App Sandbox is disabled in this preview to allow execution of a user-installed CLI and access to its login. A production distribution needs its own signing/notarization pipeline. No saved-project schema fields were added.
