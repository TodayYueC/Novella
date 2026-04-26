# Novella

Novella is a Godot 4 visual novel / GalGame plugin. The current implementation includes the v0.1 script runtime core, the v0.2 Alpha presentation core, the v0.3 Alpha interaction/state core, the v0.4 Alpha editor authoring tools, and the v0.5 Alpha meta systems.

## Runtime Target

- Primary development runtime: Godot 4.6.
- Compatibility target: Godot 4.3+ in the Godot 4 line.
- Godot engine binaries, export templates, editor caches, and local user data are intentionally ignored and must not be committed.

## Run Tests

Use the wrapper script so Godot writes logs inside the ignored `.godot_user/` folder and avoids editor-import side effects:

```powershell
.\scripts\test-godot.ps1
```

The script uses the local Godot 4.6 executable under `GodotEngine/` by default. You can pass another executable path:

```powershell
.\scripts\test-godot.ps1 -GodotExe "C:\Path\To\Godot_v4.6-stable_win64_console.exe"
```

## Implemented Milestones

- v0.1 runtime core: parser, AST, VM, variable manager, command registry, basic flow commands.
- v0.2 Alpha presentation core: typewriter timing, rich text conversion, ADV/NVL printer state and scenes, layered portrait state, character manager, background manager, effect manager, audio state manager, camera director, and presentation commands.
- v0.3 Alpha interaction/state core: choice evaluation and UI, save/load state snapshots, quick save/load/autosave commands, rollback snapshots, skip/auto managers, backlog records, quick menu state, and basic interaction views.
- v0.4 Alpha editor tools: Godot editor dock, script outline, timeline model, diagnostics, script templates, asset indexing, and headless tests for authoring workflows.
- v0.5 Alpha meta systems: localization, gallery/CG unlocks, replay unlocks, achievement progress/unlocks, meta commands, quick menu meta actions, and basic meta UI views.

Not yet implemented: v1.0 release packaging polish, export presets, and expanded compatibility matrix verification beyond the local Godot 4.6 runtime.

## License

Novella is released under the MIT License. See [LICENSE](LICENSE).
