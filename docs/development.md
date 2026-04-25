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
