# Contributing

Open issues and pull requests against `ai/integrated-assistant`, the default branch. Include the problem, resulting behavior and validation. Use Xcode 26.6+ on Apple Silicon/macOS 26+ and run `scripts/test.sh` before submitting native changes. Preserve the upstream MIT notice and American spelling in UI/code.

## Adding AI commands

Define an explicit command in AIEditorCommands, document units/ranges in AICodexBackend instructions, add the enum value to the generated schema, and validate the complete sequence before mutation. Reuse the native editor/history methods. Test invalid input, stale plans, undo/redo and any relevant mask/adjustment behavior. Do not allow model-produced shell code or arbitrary selectors.

Account-dependent AI checks are optional local smoke tests. Do not add credentials to CI, source, fixtures or screenshots. Bug reports should use non-sensitive example images. Chat and canvas input may contain personal data; do not attach them without reviewing them yourself.

## Roadmap

- Developer ID signing and Apple notarization for public distribution.
- More typed editor commands (groups, selections, crop and export).
- Provider-independent model adapter and optional API-key configuration.
- Multi-step preview/verification for visual tasks.
- Tested upstream release upgrades.
