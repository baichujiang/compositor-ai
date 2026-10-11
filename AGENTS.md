# Notes for AI agents

Compositor is a macOS image editor for compositing and photo work, written in Swift (SwiftUI and AppKit, with some C for pixel work).

## Designing or editing a Compositor project

If you've been asked to make or change an image in a `.comp` project, you don't need the app's source code. Read [docs/writing-comp-files.md](docs/writing-comp-files.md): it covers the file format, the rules that make a project load, and how to write it safely while it's open, so the person can watch the canvas update as you work.

## Working on the app itself

- Build: open `Compositor.xcodeproj` and run the **Compositor** scheme, or `xcodebuild -project Compositor.xcodeproj -scheme Compositor -destination 'platform=macOS' build`.
- Tests: the `CompositorTests` target (`xcodebuild ... test -only-testing:CompositorTests`). CI runs these on every push.
- Match the surrounding code: its naming, its comment style and density.
- American spelling in code, comments and UI ("color", not "colour").
- The project file format is described in [docs/project-format.md](docs/project-format.md). A change to what's saved means a format version bump there and in `ProjectManifest.current`.

## Compositor AI: preserve the native editor

- Preserve every adopted upstream manual editing capability. Reuse its tools, layout, toolbar positions, menu order, shortcut definitions, focus handling, and editor/history methods. AI limitations must never disable the corresponding manual operations.
- Keep AI optional and its panel closed on launch. Append its menu entry after native View commands; do not insert AI controls into the native toolbar or reserve a shortcut outside the native shortcut conflict system.
- Keep native dependencies inside `Compositor/AI/Integration/`. Core/UI must use `AIEditorGateway`; do not add AI state to EditorSession or ProjectWorkspace. Run `bash scripts/check-ai-boundaries.sh` before testing. CompositorApp is the composition root; ContentView supplies only generic optional extension hooks.
- Keep enhancements in `Compositor/AI/` and localization in `Compositor/Localization/`, using small integration hooks. Translate display text without translating stored enum values, command IDs, shortcut IDs, or user content.
- New agent providers may plan typed commands; they must use the same validation and native command bridge. Do not fork the renderer, document model, history, or manual interaction implementation for a provider.
- Record deliberate native behavior fixes and distribution differences in `docs/native-compatibility.md` and CHANGELOG. Do not silently remove or redesign upstream features to simplify AI integration.
- For upstream upgrades, follow UPSTREAM.md and the compatibility checklist. A passing test suite is not proof that every interaction matches upstream.
