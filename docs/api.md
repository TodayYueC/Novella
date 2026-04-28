# Novella API Reference

This document summarizes the public runtime surface for Novella 1.0.

## Autoload

Enable `res://addons/novella/novella.gd` as an autoload named `Novella`.

Common services:

- `Novella.variables`
- `Novella.commands`
- `Novella.parser`
- `Novella.vm`
- `Novella.printer_manager`
- `Novella.character_manager`
- `Novella.background_manager`
- `Novella.effect_manager`
- `Novella.audio_manager`
- `Novella.camera_director`
- `Novella.choice_manager`
- `Novella.save_manager`
- `Novella.settings_manager`
- `Novella.rollback_manager`
- `Novella.skip_manager`
- `Novella.auto_manager`
- `Novella.backlog_manager`
- `Novella.quick_menu_manager`
- `Novella.localization_manager`
- `Novella.gallery_manager`
- `Novella.achievement_manager`
- `Novella.script_migration`
- `Novella.compatibility_matrix`

## Script Execution

```gdscript
var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
var transcript := Novella.run_script(source, "res://story/chapter_01.nvs")
```

For custom rendering, connect to VM signals and translate transcript payloads into your own UI.

## Custom Commands

```gdscript
func _ready() -> void:
	Novella.register_command(&"screen_tint", Callable(self, "_screen_tint"))

func _screen_tint(raw_arguments: String, context: Dictionary) -> Dictionary:
	return {"ok": true, "raw": raw_arguments}
```

Command handlers should return dictionaries. Use `{"ok": true}` for successful side effects, `{"jump": &"label"}` for flow changes, or `{"error": "message"}` for recoverable script errors.

## Migration

```gdscript
var migration := Novella.script_migration.migrate(old_source)
if migration["ok"]:
	var updated_source: String = migration["source"]
```

The migration helper adds a `# novella_version: 1.0` header and rewrites known deprecated aliases such as `@language` and `@achieve`.
