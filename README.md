# Novella

Novella is a Godot 4 visual novel / GalGame plugin. The v0.1 alpha focuses on the script runtime core: services, resources, Novella Script parsing, variables, commands, and a small VM.

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

## License

Novella is released under the MIT License. See [LICENSE](LICENSE).
