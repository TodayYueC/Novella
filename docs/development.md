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

## Versioned Roadmap After v1.3.0

Future iterations must follow this version order. Each feature version is completed as one milestone, then tested, packaged, committed, tagged, pushed, and published as a GitHub Release before moving to the next version.

Patch releases such as `v1.4.1` are reserved for urgent regressions only. Planned feature work should not be split into ad-hoc mini versions such as `v1.4.1`, `v1.4.2`, or `v1.4.3`; the next planned feature milestone remains the next minor version.

| Version | Target Window | Milestone |
| --- | --- | --- |
| `v1.4.0` | 2026-05-01 to 2026-05-03 | Editor live preview: run the current timeline, interact with choices, watch variables, and jump from preview state back to script lines. |
| `v1.5.0` | 2026-05-04 to 2026-05-07 | Production timeline editor: drag reorder, inline editing, collapse/expand, color coding, copy/paste/delete, and keyboard shortcuts. |
| `v1.6.0` | 2026-05-08 to 2026-05-11 | Character and asset editors: character resources, layered portraits, side portraits, voice folders, backgrounds, BGM, SE, and voice asset management. |
| `v1.7.0` | 2026-05-12 to 2026-05-15 | UI and skin system: `.tres` styles, default theme, confirm dialogs, toast notifications, quick menu configuration, and hide-dialogue behavior. |
| `v1.8.0` | 2026-05-16 to 2026-05-20 | Presentation completion: rendered characters/backgrounds, transition animation, camera animation, screen effects, and shader registration baseline. |
| `v1.9.0` | 2026-05-21 to 2026-05-24 | Audio and voice completion: BGM/SE/Voice playback, loop metadata, automatic voice association, and backlog voice replay. |
| `v1.10.0` | 2026-05-25 to 2026-05-28 | Save, rollback, skip, and auto polish: save import/export, optional encryption, arbitrary rollback targets, and persistent read-state tracking. |
| `v1.11.0` | 2026-05-29 to 2026-06-01 | Localization completion: locale typography, localized asset overrides, on-demand language packs, line split/merge support, and plural-form baseline. |
| `v1.12.0` | 2026-06-02 to 2026-06-05 | Gallery, music room, route map, and achievement UI: CG viewing, BGM list playback, clickable route nodes, and achievement toast flow. |
| `v1.13.0` | 2026-06-06 to 2026-06-09 | Debug and developer UI: variable panel, console panel, node inspector, performance panel, and visual flow graph view. |
| `v1.14.0` | 2026-06-10 to 2026-06-14 | Performance and platform work: on-demand loading implementation, audio streaming validation, memory/FPS baseline, touch input, and gamepad input. |
| `v1.15.0` | 2026-06-15 to 2026-06-18 | Documentation and example completion: full example VN project, bilingual API docs, command docs, and tutorial refresh. |
| `v1.16.0` | 2026-06-19 to 2026-06-23 | Compatibility matrix: Godot 4.3, 4.4, 4.5, and 4.6 validation and API compatibility fixes. |
| `v1.17.0` | 2026-06-24 to 2026-06-28 | Full PRD audit release: close remaining PRD gaps and raise targeted test coverage. |
| `v1.18.0` | 2026-06-29 to 2026-07-03 | Release candidate: freeze features, fix only bugs, polish packaging, and verify release artifacts. |
| `v2.0.0` | 2026-07-04 to 2026-07-07 | Full PRD official release: final acceptance, packaging, tag, GitHub Release, and public-ready artifact. |

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
