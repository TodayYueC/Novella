# Novella

Novella is a Godot 4 visual novel / GalGame plugin. The current implementation includes the v0.1 script runtime core plus the first v0.2 text presentation slice.

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
- v0.2 text presentation slice: typewriter timing, rich text conversion, ADV/NVL printer state, `@mode adv/nvl`, VM printer dispatch.

Not yet implemented: visual UI scenes, portraits, backgrounds, audio, camera, save/load, rollback, localization, and editor timeline tools.

## License

Novella is released under the MIT License. See [LICENSE](LICENSE).
