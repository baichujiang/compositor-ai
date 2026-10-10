# Upstream tracking

- Project: https://github.com/robbietilton/Compositor
- License: MIT, copyright 2026 Wonder Assembly LLC (retained verbatim in LICENSE).
- Adopted baseline: Compositor 1.4.8, `22c7b8d5b23bb1e27a5746912061b23757c4f554`.
- Document format: 11, unchanged by the AI additions.
- Our default branch: `ai/integrated-assistant`. The fork's `main` is upstream history, not the AI product branch.

## Updating the baseline

Work in a separate branch and keep local edits intact. Add upstream if needed:

```sh
git remote add upstream https://github.com/robbietilton/Compositor.git
git fetch upstream
git switch -c maintenance/upstream-update
```

Inspect upstream changes, then merge the specific commit or release selected for adoption. Resolve session/UI hooks without copying upstream bundle identifiers, signing teams, Sparkle feeds or publishing destinations. Run `scripts/test.sh`, build the Release app, and smoke-test AI edits and `.comp` save/reopen. Update this baseline and CHANGELOG only after verification. Review file format changes separately; retain the native migration rules.

AI code is primarily in `Compositor/AI/`. Hooks are in EditorSession, ContentView and the app menus. Packaging is independent. Source integration removes dependence on an installed Compositor's screen layout, but still needs maintenance as the editor and operating system evolve.
