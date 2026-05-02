# Development Notes

## Why v0.1 Uses GDScript

Godot supports native extensions through C++ / GDExtension, and Novella can adopt that later for performance-sensitive modules. The v0.1 alpha is intentionally written in GDScript because:

- EditorPlugin, Resource, Signal, Control, and SceneTree integration are native Godot workflows in GDScript.
- Users can install and inspect the plugin without compiling C++ toolchains per platform.
- Godot Asset Library distribution is simpler when the first milestone is script-only.
- The current bottleneck is correctness and API shape, not native execution speed.
- The parser, bytecode compiler, and VM can be moved behind the same public interfaces later if profiling shows a real need.

The planned split is:

- Keep editor UI, authoring tools, resources, and service wiring in GDScript.
- Consider C++ / GDExtension for parser hot paths, bytecode execution, expression evaluation, or large-scale asset processing after the API stabilizes.

## Versioned Roadmap After v1.5.0

`v1.4.0` completed the editor, asset, and UI production-tools phase. `v1.5.0` completed the presentation, audio, and save-system phase. Future iterations must follow this version order. Each phase version is completed as one milestone, then tested, packaged, committed, tagged, pushed, and published as a GitHub Release before moving to the next phase.

Patch releases such as `v1.4.1` are reserved for urgent regressions only. Planned feature work should not be split into ad-hoc mini versions such as `v1.4.1`, `v1.4.2`, or `v1.4.3`; the next planned feature milestone remains the next phase version.

| Version | Phase | Milestone |
| --- | --- | --- |
| `v1.6.0` | Meta systems, debugging, and performance completed | Complete localization typography and asset overrides, on-demand language packs, line split/merge support, plural-form baseline, gallery/music room/route map/achievement UI, debug panels, command console UI, node inspector, performance panel, visual flow graph, on-demand loading implementation, audio streaming validation, memory/FPS baseline, touch input, and gamepad input. |
| `v1.7.0` | Documentation, examples, compatibility, and PRD audit | Complete the full example VN project, bilingual API docs, command docs, tutorial refresh, Godot 4.3/4.4/4.5/4.6 compatibility matrix, API compatibility fixes, full PRD audit, remaining gap closure, and targeted test coverage improvements. |
| `v2.0.0` | Full PRD official release | Final acceptance, release-candidate stabilization, packaging polish, artifact verification, tag, GitHub Release, and public-ready full PRD release. |

Every milestone uses the same release checklist:

1. Implement the planned version scope.
2. Add or update tests and docs.
3. Run `scripts/test-godot.ps1`.
4. Run `scripts/validate-release.ps1`.
5. Run `scripts/package-addon.ps1`.
6. Inspect the generated package for forbidden paths.
7. Commit, tag, push, and create the GitHub Release.

## Avoiding Godot Crash Popups During Tests

During early verification, running full editor import from a sandboxed environment caused Godot 4.6.2 Mono to try writing editor settings and logs outside the workspace. When those writes were blocked, the Godot executable crashed and Windows showed an access-violation dialog like:

```text
0x... 指令引用了 0x... 内存。该内存不能为 read。
```

This is an engine/editor startup crash triggered by the execution environment, not a Novella runtime assertion. For routine tests, use:

```powershell
.\scripts\test-godot.ps1
```

That command runs only the headless GDScript test runner and writes the log to `.godot_user/godot-tests.log`, which is ignored by Git.

Use editor import checks only from a normal desktop session where Godot can write its editor settings, or run them with the required filesystem permissions. Do not commit generated `.godot/`, `.godot_user/`, engine binaries, export templates, or local editor settings.
