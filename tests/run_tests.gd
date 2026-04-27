extends SceneTree

const Lexer := preload("res://addons/novella/script/lexer.gd")
const Token := preload("res://addons/novella/script/token.gd")
const Parser := preload("res://addons/novella/script/parser.gd")
const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const BasicCommands := preload("res://addons/novella/script/commands/basic_commands.gd")
const PresentationCommands := preload("res://addons/novella/script/commands/presentation_commands.gd")
const InteractionCommands := preload("res://addons/novella/script/commands/interaction_commands.gd")
const MetaCommands := preload("res://addons/novella/script/commands/meta_commands.gd")
const VM := preload("res://addons/novella/script/novella_vm.gd")
const RichTextParser := preload("res://addons/novella/presentation/rich_text_parser.gd")
const TypewriterEffect := preload("res://addons/novella/presentation/typewriter_effect.gd")
const PrinterManager := preload("res://addons/novella/presentation/printer_manager.gd")
const CharacterManager := preload("res://addons/novella/presentation/characters/character_manager.gd")
const BackgroundManager := preload("res://addons/novella/presentation/backgrounds/background_manager.gd")
const EffectManager := preload("res://addons/novella/presentation/effects/effect_manager.gd")
const AudioManager := preload("res://addons/novella/presentation/audio/audio_manager.gd")
const CameraDirector := preload("res://addons/novella/presentation/camera/camera_director.gd")
const ChoiceManager := preload("res://addons/novella/interaction/choice_manager.gd")
const SaveManager := preload("res://addons/novella/state/save_manager.gd")
const RollbackManager := preload("res://addons/novella/state/rollback_manager.gd")
const SkipManager := preload("res://addons/novella/interaction/skip_manager.gd")
const AutoManager := preload("res://addons/novella/interaction/auto_manager.gd")
const BacklogManager := preload("res://addons/novella/state/backlog_manager.gd")
const QuickMenuManager := preload("res://addons/novella/interaction/quick_menu_manager.gd")
const EditorController := preload("res://addons/novella/editor/editor_controller.gd")
const OutlineBuilder := preload("res://addons/novella/editor/script_outline_builder.gd")
const TimelineModel := preload("res://addons/novella/editor/timeline_model.gd")
const ScriptDiagnostics := preload("res://addons/novella/editor/script_diagnostics.gd")
const TemplateLibrary := preload("res://addons/novella/editor/script_template_library.gd")
const AssetIndex := preload("res://addons/novella/editor/asset_index.gd")
const LocalizationManager := preload("res://addons/novella/meta/localization_manager.gd")
const GalleryManager := preload("res://addons/novella/meta/gallery_manager.gd")
const AchievementManager := preload("res://addons/novella/meta/achievement_manager.gd")
const ReleaseManifest := preload("res://addons/novella/release/release_manifest.gd")
const ReleaseValidator := preload("res://addons/novella/release/release_validator.gd")

var failures: Array[String] = []

func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("Novella v1.0 alpha tests passed.")
		quit(0)
	else:
		push_error("Novella tests failed:\n%s" % "\n".join(failures))
		quit(1)


func _run_all() -> void:
	_test_lexer()
	_test_parser()
	_test_expression_evaluator()
	_test_variable_manager_and_commands()
	_test_text_presentation()
	_test_printer_manager()
	_test_printer_views()
	_test_v0_2_managers()
	_test_v0_3_interaction_managers()
	_test_v0_3_interaction_views()
	_test_v0_3_commands_and_vm_state()
	_test_v0_4_editor_models()
	_test_v0_4_editor_dock()
	_test_v0_5_meta_managers()
	_test_v0_5_meta_views()
	_test_v0_5_commands_and_localized_vm()
	_test_v1_0_release_tools()
	_test_vm_milestone_script()


func _test_lexer() -> void:
	var lexer := Lexer.new()
	var tokens := lexer.tokenize("@set affinity += 5\nlabel start:")
	_assert(tokens.any(func(token): return token.type == Token.Type.COMMAND and token.literal == "set"), "Lexer should emit @set command token.")
	_assert(tokens.any(func(token): return token.type == Token.Type.KEYWORD and token.lexeme == "label"), "Lexer should emit label keyword.")
	_assert(lexer.errors.is_empty(), "Lexer should not report errors.")


func _test_parser() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_sample_script(), "sample.nvs")
	_assert(parser.errors.is_empty(), "Parser should not report errors: %s" % [parser.errors])
	_assert(ast.children.size() > 0, "Parser should create AST children.")
	_assert(ast.labels.has(&"start"), "Parser should collect start label.")
	_assert(ast.labels.has(&"greet_path"), "Parser should collect greet_path label.")
	_assert(ast.children.any(func(node): return node.kind == &"menu"), "Parser should create a menu node.")


func _test_expression_evaluator() -> void:
	var variables := VariableManager.new()
	variables.declare_variable(&"affinity", 5)
	var evaluator := ExpressionEvaluator.new()
	_assert(evaluator.evaluate("affinity >= 5 and affinity < 10", variables, false) == true, "Expression evaluator should handle comparisons and logic.")
	_assert(evaluator.evaluate("affinity * 2 + 1", variables, 0) == 11, "Expression evaluator should handle arithmetic.")


func _test_variable_manager_and_commands() -> void:
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	var presentation := PresentationCommands.new()
	var interaction := InteractionCommands.new()
	var meta := MetaCommands.new()
	var managers := _make_v0_5_managers()
	managers["variable_manager"] = variables
	var save_manager: SaveManager = managers["save_manager"]
	save_manager.enable_memory_storage(true)
	basic.register_all(registry, variables)
	presentation.register_all(registry, managers)
	interaction.register_all(registry, managers)
	meta.register_all(registry, managers)
	_assert(registry.execute(&"var", "score = 1")["ok"], "@var should execute.")
	_assert(registry.execute(&"set", "score += 4")["ok"], "@set should execute.")
	_assert(variables.get_variable(&"score") == 5, "VariableManager should store command updates.")
	_assert(registry.execute(&"flag", "set met_ryone")["ok"], "@flag set should execute.")
	_assert(variables.flags.check_flag(&"met_ryone"), "FlagSet should contain set flag.")
	_assert(registry.execute(&"mode", "nvl")["mode"] == &"nvl", "@mode should return a printer mode change.")
	_assert(registry.execute(&"bg", "school transition:dissolve time:1.0")["id"] == "school", "@bg should update background state.")
	_assert(registry.execute(&"play_music", "main_theme fade:1.0")["channel"] == "bgm", "@play_music should use BGM channel.")
	_assert(registry.execute(&"auto", "on delay:0.1")["enabled"], "@auto should start auto advance.")
	_assert(registry.execute(&"skip", "read")["mode"] == "read", "@skip should start read skip.")
	_assert(registry.execute(&"locale", "ja")["locale"] == "ja", "@locale should change language.")
	_assert(registry.execute(&"gallery", "unlock cg_school title:School asset:school.png")["unlocked"], "@gallery should unlock gallery items.")
	_assert(registry.execute(&"achievement", "unlock first_step title:First")["unlocked"], "@achievement should unlock achievements.")


func _test_text_presentation() -> void:
	var parser := RichTextParser.new()
	var parsed := parser.parse("{b}Hello{/b} {color=#ff0000}red{/color}{w=0.5}{nw}")
	_assert(parsed["bbcode"].contains("[b]Hello[/b]"), "RichTextParser should convert bold tags to BBCode.")
	_assert(parsed["bbcode"].contains("[color=#ff0000]red[/color]"), "RichTextParser should convert color tags to BBCode.")
	_assert(parsed["plain_text"] == "Hello red", "RichTextParser should strip visual and control tags.")
	_assert(parsed["controls"].size() == 2, "RichTextParser should collect wait/no-wait controls.")

	var typewriter := TypewriterEffect.new()
	typewriter.start("Hi!", 10.0)
	typewriter.advance(0.1)
	_assert(typewriter.get_visible_text() == "H", "TypewriterEffect should reveal characters over time.")
	typewriter.reveal_all()
	_assert(typewriter.get_visible_text() == "Hi!", "TypewriterEffect should reveal all text on request.")
	_assert(typewriter.estimate_duration("Hi!", 10.0) > 0.3, "TypewriterEffect should include punctuation delay.")


func _test_printer_manager() -> void:
	var manager := PrinterManager.new()
	var adv_payload := manager.present_dialogue("Ryone", "Hello")
	_assert(adv_payload["mode"] == "adv", "PrinterManager should start in ADV mode.")
	_assert(adv_payload["layout"] == "bottom_dialogue_box", "ADV printer should report bottom dialogue layout.")
	_assert(manager.set_mode(&"nvl"), "PrinterManager should switch to NVL mode.")
	var nvl_payload := manager.present_narration("A quiet wind passes.")
	_assert(nvl_payload["mode"] == "nvl", "PrinterManager should present narration in NVL mode after switch.")
	_assert(nvl_payload["layout"] == "fullscreen_text_page", "NVL printer should report fullscreen page layout.")


func _test_printer_views() -> void:
	var adv_scene: PackedScene = load("res://addons/novella/presentation/ui/adv_printer.tscn")
	var nvl_scene: PackedScene = load("res://addons/novella/presentation/ui/nvl_printer.tscn")
	var adv = adv_scene.instantiate()
	var nvl = nvl_scene.instantiate()
	adv.apply_payload({"speaker": "Ryone", "text": "Hello"})
	nvl.apply_payload({"page_lines": [{"speaker": "Ryone", "text": "Hello"}]})
	_assert(adv.get_node("NameLabel").text == "Ryone", "ADV view should display speaker name.")
	_assert(nvl.get_node("TextLabel").text.contains("Ryone: Hello"), "NVL view should display accumulated lines.")
	adv.free()
	nvl.free()


func _test_v0_2_managers() -> void:
	var managers := _make_v0_2_managers()
	var characters: CharacterManager = managers["character_manager"]
	var backgrounds: BackgroundManager = managers["background_manager"]
	var effects: EffectManager = managers["effect_manager"]
	var audio: AudioManager = managers["audio_manager"]
	var camera: CameraDirector = managers["camera_director"]

	characters.register_character(&"Ryone", {
		"layers": [
			{"group": "body", "attribute": "uniform", "path": "ryone/uniform.png", "order": 0},
			{"group": "expression", "attribute": "happy", "path": "ryone/happy.png", "order": 1},
			{"group": "expression", "attribute": "sad", "path": "ryone/sad.png", "order": 1},
		],
		"side_portraits": {&"default": "ryone/side/default.png", &"happy": "ryone/side/happy.png"},
	})
	var shown := characters.show_character(&"Ryone", ["uniform", "happy"], {"pos": "left", "enter": "slide"})
	_assert(shown["position_name"] == "left", "CharacterManager should place characters by named position.")
	_assert(shown["layers"].size() == 2, "LayeredSprite should select visible layers.")
	var moved := characters.move_character(&"Ryone", "right", {"time": "0.5"})
	_assert(moved["position_name"] == "right", "CharacterManager should move visible characters.")
	characters.focus_character(&"Ryone")
	_assert(characters.get_character_state(&"Ryone")["focused"], "CharacterManager should focus speakers.")

	var bg := backgrounds.show_background(&"school", {"transition": "dissolve", "time": "1.5"})
	_assert(bg["transition"] == "dissolve", "BackgroundManager should store transitions.")
	_assert(backgrounds.set_environment(&"rain", {"intensity": "0.3"})["ok"], "BackgroundManager should store environment effects.")

	_assert(effects.trigger_effect(&"shake", "screen", {"intensity": "0.5"})["ok"], "EffectManager should trigger built-in effects.")
	_assert(audio.play(&"bgm", &"main_theme", {"fade": "2.0"})["playing"], "AudioManager should play BGM state.")
	_assert(audio.play(&"voice", &"voice_001", {"wait": "true"})["channel"] == "voice", "AudioManager should play voice state.")
	_assert(camera.move_camera({"pos": "10,20", "zoom": "1.2"})["zoom"] == Vector2(1.2, 1.2), "CameraDirector should parse zoom.")
	_assert(camera.shake({"intensity": "0.4"})["ok"], "CameraDirector should shake camera.")


func _test_v0_3_interaction_managers() -> void:
	var variables := VariableManager.new()
	variables.declare_variable(&"affinity", 7)
	var choice_manager := ChoiceManager.new()
	choice_manager.variable_manager = variables
	var choices := choice_manager.build_choices([
		{"text": "Talk ({affinity})", "condition": "affinity >= 5", "line": 10},
		{"text": "Leave", "condition": "affinity < 5", "line": 11},
	], 9)
	_assert(choices.size() == 1, "ChoiceManager should hide choices whose condition is false.")
	_assert(choices[0]["text"] == "Talk (7)", "ChoiceManager should interpolate choice text.")
	_assert(choice_manager.select_choice(choices, 0)["ok"], "ChoiceManager should select an enabled choice.")

	var save_manager := SaveManager.new()
	save_manager.enable_memory_storage(true)
	var saved := save_manager.save_game(&"slot1", {"variables": variables.snapshot()}, {"chapter": "intro"})
	_assert(saved["ok"], "SaveManager should save to memory storage.")
	_assert(save_manager.list_saves().size() == 1, "SaveManager should list memory saves.")
	var loaded := save_manager.load_game(&"slot1")
	_assert(loaded["state"]["variables"]["game"][&"affinity"] == 7, "SaveManager should load saved state.")
	_assert(save_manager.quick_save({"value": 1})["slot"] == "quick", "SaveManager should write quick saves.")
	_assert(save_manager.quick_load()["state"]["value"] == 1, "SaveManager should load quick saves.")
	_assert(save_manager.delete_save(&"slot1")["deleted"], "SaveManager should delete memory saves.")

	var rollback := RollbackManager.new()
	rollback.configure({"limit": 2})
	rollback.push_snapshot({"index": 1})
	rollback.push_snapshot({"index": 2})
	rollback.push_snapshot({"index": 3})
	_assert(rollback.get_state()["snapshots"].size() == 2, "RollbackManager should enforce its snapshot limit.")
	_assert(rollback.rollback()["state"]["index"] == 3, "RollbackManager should return the latest snapshot.")
	rollback.prevent_rollback()
	_assert(not rollback.can_rollback(), "RollbackManager should honor rollback prevention.")

	var skip := SkipManager.new()
	skip.mark_read("line-1")
	_assert(skip.start_skip(&"read")["ok"], "SkipManager should start read skip mode.")
	_assert(skip.should_skip("line-1"), "SkipManager should skip read lines.")
	_assert(not skip.should_skip("line-2", true), "SkipManager should not skip unread lines in read mode.")
	skip.start_skip(&"all")
	_assert(skip.should_skip("line-2", true), "SkipManager should skip unread lines in all mode.")

	var auto := AutoManager.new()
	auto.start({"delay": "0.1", "per_character": "0.0"})
	_assert(auto.advance(0.2, "Hello"), "AutoManager should advance after delay.")
	auto.start({"delay": "0.1"})
	_assert(not auto.advance(0.2, "Hello", true), "AutoManager should wait for voice when configured.")

	var backlog := BacklogManager.new()
	backlog.configure({"max_entries": 2})
	backlog.add_dialogue("Ryone", "One", 1)
	backlog.add_narration("Two", 2)
	backlog.add_choice("Three", 3, 0)
	_assert(backlog.get_entries().size() == 2, "BacklogManager should cap entries.")
	_assert(backlog.get_entries()[1]["type"] == "choice", "BacklogManager should record choices.")

	var quick := QuickMenuManager.new()
	var called := {"value": false}
	quick.register_action_handler(&"save", func(_context): called["value"] = true; return {"ok": true, "saved": true})
	_assert(quick.dispatch_action(&"save")["saved"], "QuickMenuManager should dispatch registered handlers.")
	_assert(called["value"], "QuickMenuManager should call registered handlers.")
	quick.set_action_enabled(&"save", false)
	_assert(quick.dispatch_action(&"save")["disabled"], "QuickMenuManager should honor disabled actions.")


func _test_v0_3_interaction_views() -> void:
	var choice_scene: PackedScene = load("res://addons/novella/interaction/ui/choice_menu.tscn")
	var backlog_scene: PackedScene = load("res://addons/novella/interaction/ui/backlog_panel.tscn")
	var quick_scene: PackedScene = load("res://addons/novella/interaction/ui/quick_menu.tscn")
	var choice_view = choice_scene.instantiate()
	var backlog_view = backlog_scene.instantiate()
	var quick_view = quick_scene.instantiate()
	choice_view.apply_choices([
		{"index": 0, "text": "First", "enabled": true},
		{"index": 1, "text": "Second", "disabled": true},
	])
	backlog_view.apply_entries([
		{"type": "dialogue", "speaker": "Ryone", "text": "Hello"},
		{"type": "choice", "text": "First"},
	])
	quick_view.apply_actions([
		{"id": &"save", "label": "Save", "enabled": true, "visible": true},
		{"id": &"load", "label": "Load", "enabled": false, "visible": true},
	])
	_assert(choice_view.get_node("ChoiceList").get_child_count() == 2, "Choice menu view should create buttons.")
	_assert(backlog_view.get_node("TextLabel").text.contains("Ryone: Hello"), "Backlog panel should render dialogue lines.")
	_assert(quick_view.get_node("ActionBar").get_child_count() == 2, "Quick menu view should create action buttons.")
	choice_view.free()
	backlog_view.free()
	quick_view.free()


func _test_v0_3_commands_and_vm_state() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_v0_3_sample_script(), "v0_3_demo.nvs")
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	var presentation := PresentationCommands.new()
	var interaction := InteractionCommands.new()
	var managers := _make_v0_3_managers()
	var save_manager: SaveManager = managers["save_manager"]
	var rollback_manager: RollbackManager = managers["rollback_manager"]
	var backlog_manager: BacklogManager = managers["backlog_manager"]
	var choice_manager: ChoiceManager = managers["choice_manager"]
	var skip_manager: SkipManager = managers["skip_manager"]
	var auto_manager: AutoManager = managers["auto_manager"]
	var quick_menu_manager: QuickMenuManager = managers["quick_menu_manager"]
	var printer_manager: PrinterManager = managers["printer_manager"]
	save_manager.enable_memory_storage(true)
	choice_manager.variable_manager = variables
	basic.register_all(registry, variables)
	presentation.register_all(registry, managers)
	interaction.register_all(registry, managers)

	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.printer_manager = printer_manager
	vm.choice_manager = choice_manager
	vm.save_manager = save_manager
	vm.rollback_manager = rollback_manager
	vm.backlog_manager = backlog_manager
	vm.skip_manager = skip_manager
	vm.auto_manager = auto_manager
	vm.quick_menu_manager = quick_menu_manager
	vm.state_providers = _state_providers_from(managers)
	vm.load_script(ast)
	var transcript := vm.run()
	_assert(not transcript.any(func(entry): return entry.get("type", "") == "error"), "VM v0.3 script should not emit runtime errors: %s" % [transcript])
	_assert(backlog_manager.get_entries().size() >= 3, "VM should record dialogue and choices into backlog.")
	_assert(rollback_manager.get_state()["snapshots"].size() > 0, "VM should push rollback snapshots.")
	_assert(skip_manager.get_state()["read_lines"].size() > 0, "VM should mark dialogue lines as read.")
	_assert(save_manager.quick_load()["state"]["variables"]["game"][&"affinity"] == 5, "Interaction commands should quick save VM state.")
	_assert(auto_manager.enabled, "Interaction commands should enable auto mode.")
	_assert(quick_menu_manager.visible == false, "Interaction commands should hide the quick menu.")

	var snapshot := vm.snapshot_state()
	variables.set_variable(&"affinity", 99)
	vm.restore_state(snapshot)
	_assert(variables.get_variable(&"affinity") == 5, "VM restore_state should restore variables.")


func _test_v0_4_editor_models() -> void:
	var controller := EditorController.new()
	var analysis := controller.analyze_source(_v0_4_sample_script(), "res://story/chapter_01.nvs", _known_commands_for_tests())
	_assert(analysis["ok"], "EditorController should analyze a valid script without errors: %s" % [analysis["diagnostics"]])
	var outline: Dictionary = analysis["outline"]
	var timeline: Dictionary = analysis["timeline"]
	var diagnostics: Dictionary = analysis["diagnostics"]
	_assert(outline["stats"]["labels"] == 3, "OutlineBuilder should count labels.")
	_assert(outline["stats"]["choices"] == 2, "OutlineBuilder should count menu choices.")
	_assert(outline["items"].any(func(item): return item.get("kind", "") == "choice" and str(item.get("title", "")).contains("Stay")), "OutlineBuilder should include choices.")
	_assert(timeline["counts"]["background"] >= 1, "TimelineModel should categorize background commands.")
	_assert(timeline["counts"]["character"] >= 1, "TimelineModel should categorize character commands.")
	_assert(timeline["counts"]["choice"] == 1, "TimelineModel should include menu events.")
	_assert(timeline["segments"].size() == 3, "TimelineModel should create label segments.")
	_assert(not diagnostics["has_errors"], "ScriptDiagnostics should report no errors for valid flow.")

	var bad_analysis := controller.analyze_source("label start:\n    jump missing\n    @unknown value\n", "bad.nvs", _known_commands_for_tests())
	_assert(bad_analysis["diagnostics"]["has_errors"], "ScriptDiagnostics should catch missing jump targets.")
	_assert(bad_analysis["diagnostics"]["issues"].any(func(issue): return str(issue.get("message", "")).contains("Unknown command")), "ScriptDiagnostics should warn about unknown commands.")

	var template_library := TemplateLibrary.new()
	var rendered := template_library.render(&"adv_scene", {"character": "Mira", "background": "roof"})
	_assert(rendered.contains("Mira:"), "TemplateLibrary should replace character placeholders.")
	_assert(rendered.contains("@bg roof"), "TemplateLibrary should replace background placeholders.")
	_assert(template_library.list_templates().size() >= 4, "TemplateLibrary should expose starter templates.")

	var indexer := AssetIndex.new()
	var index := indexer.build([
		"res://art/backgrounds/school.png",
		"res://art/characters/ryone/happy.png",
		"res://audio/bgm/theme.ogg",
		"res://story/chapter_01.nvs",
		"res://ui/title.tscn",
	])
	_assert(index["backgrounds"].size() == 1, "AssetIndex should classify background art.")
	_assert(index["characters"].size() == 1, "AssetIndex should classify character art.")
	_assert(index["audio"].size() == 1, "AssetIndex should classify audio.")
	_assert(indexer.suggest_for_command(index, &"char").size() == 1, "AssetIndex should suggest character assets for @char.")


func _test_v0_4_editor_dock() -> void:
	var dock_scene: PackedScene = load("res://addons/novella/editor/ui/novella_editor_dock.tscn")
	var dock = dock_scene.instantiate()
	var controller := EditorController.new()
	var analysis := controller.analyze_source(_v0_4_sample_script(), "res://story/chapter_01.nvs", _known_commands_for_tests())
	dock.apply_templates(controller.templates.list_templates())
	dock.apply_analysis(analysis)
	_assert(dock.get_node("Root/Tabs/Outline").get_root().get_child_count() > 0, "Editor dock should render outline rows.")
	_assert(dock.get_node("Root/Tabs/Timeline").get_root().get_child_count() > 0, "Editor dock should render timeline rows.")
	_assert(dock.get_node("Root/Tabs/Diagnostics").text.contains("Errors: 0"), "Editor dock should render diagnostic counts.")
	_assert(dock.get_node("Root/Tabs/Templates").item_count >= 4, "Editor dock should render template entries.")
	dock.free()


func _test_v0_5_meta_managers() -> void:
	var variables := VariableManager.new()
	variables.declare_variable(&"player", "Yue")
	var localization := LocalizationManager.new()
	localization.add_translation(&"en", &"hello", "Hello {player}.")
	localization.add_translation(&"ja", &"hello", "こんにちは {player}.")
	localization.set_locale(&"ja")
	_assert(localization.translate(&"hello", variables) == "こんにちは Yue.", "LocalizationManager should translate and format text.")
	_assert(localization.localize_text("$hello", variables).contains("Yue"), "LocalizationManager should localize $key text.")
	_assert(localization.translate(&"missing_key") == "missing_key", "LocalizationManager should return missing keys as text.")
	_assert(localization.get_missing_keys().has("ja"), "LocalizationManager should record missing translations.")

	var gallery := GalleryManager.new()
	gallery.register_item(&"cg_school", {"type": "cg", "title": "School", "asset": "school.png"})
	_assert(not gallery.is_unlocked(&"cg_school"), "GalleryManager should register locked gallery items.")
	gallery.unlock_item(&"cg_school")
	gallery.unlock_replay(&"intro_replay", &"start", {"title": "Intro"})
	_assert(gallery.is_unlocked(&"cg_school"), "GalleryManager should unlock gallery items.")
	_assert(gallery.list_items("replay", false).size() == 1, "GalleryManager should unlock replay entries.")
	gallery.mark_viewed(&"cg_school")
	_assert(gallery.get_item(&"cg_school")["viewed"], "GalleryManager should mark viewed items.")

	var achievements := AchievementManager.new()
	achievements.register_achievement(&"reader", {"title": "Reader", "target": 3})
	achievements.add_progress(&"reader", 1)
	_assert(not achievements.is_unlocked(&"reader"), "AchievementManager should keep partial achievements locked.")
	achievements.add_progress(&"reader", 2)
	_assert(achievements.is_unlocked(&"reader"), "AchievementManager should unlock achievements at target progress.")
	variables.declare_variable(&"affinity", 5)
	achievements.register_achievement(&"friend", {"condition": "affinity >= 5"})
	_assert(achievements.evaluate_conditions(variables).size() == 1, "AchievementManager should unlock condition achievements.")


func _test_v0_5_meta_views() -> void:
	var language_scene: PackedScene = load("res://addons/novella/meta/ui/language_menu.tscn")
	var gallery_scene: PackedScene = load("res://addons/novella/meta/ui/gallery.tscn")
	var achievement_scene: PackedScene = load("res://addons/novella/meta/ui/achievement_list.tscn")
	var language_view = language_scene.instantiate()
	var gallery_view = gallery_scene.instantiate()
	var achievement_view = achievement_scene.instantiate()
	language_view.apply_locales(["en", "ja"], &"ja")
	gallery_view.apply_items([
		{"id": "cg_school", "title": "School", "unlocked": true},
		{"id": "cg_secret", "title": "Secret", "unlocked": false},
	])
	achievement_view.apply_achievements([
		{"id": "reader", "title": "Reader", "progress": 3, "target": 3, "unlocked": true},
		{"id": "collector", "title": "Collector", "progress": 1, "target": 5, "unlocked": false},
	])
	_assert(language_view.get_node("LocaleOptions").item_count == 2, "Language menu view should render locale options.")
	_assert(gallery_view.get_node("ItemList").item_count == 2, "Gallery view should render gallery items.")
	_assert(achievement_view.get_node("ItemList").item_count == 2, "Achievement view should render achievements.")
	language_view.free()
	gallery_view.free()
	achievement_view.free()


func _test_v0_5_commands_and_localized_vm() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_v0_5_sample_script(), "v0_5_demo.nvs")
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	var presentation := PresentationCommands.new()
	var interaction := InteractionCommands.new()
	var meta := MetaCommands.new()
	var managers := _make_v0_5_managers()
	managers["variable_manager"] = variables
	var localization: LocalizationManager = managers["localization_manager"]
	var gallery: GalleryManager = managers["gallery_manager"]
	var achievements: AchievementManager = managers["achievement_manager"]
	var choice_manager: ChoiceManager = managers["choice_manager"]
	var printer_manager: PrinterManager = managers["printer_manager"]
	localization.add_translation(&"en", &"line.greeting", "Hello {player}.")
	localization.add_translation(&"en", &"choice.unlock", "Unlock memory")
	localization.add_translation(&"ja", &"line.greeting", "やあ {player}.")
	localization.add_translation(&"ja", &"choice.unlock", "思い出を開く")
	choice_manager.variable_manager = variables
	choice_manager.localization_manager = localization
	basic.register_all(registry, variables)
	presentation.register_all(registry, managers)
	interaction.register_all(registry, managers)
	meta.register_all(registry, managers)

	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.printer_manager = printer_manager
	vm.choice_manager = choice_manager
	vm.localization_manager = localization
	vm.gallery_manager = gallery
	vm.achievement_manager = achievements
	vm.state_providers = _state_providers_from(managers)
	vm.load_script(ast)
	var transcript := vm.run()
	_assert(not transcript.any(func(entry): return entry.get("type", "") == "error"), "VM v0.5 script should not emit runtime errors: %s" % [transcript])
	_assert(transcript.any(func(entry): return str(entry.get("text", "")).contains("やあ Yue")), "VM should localize dialogue text.")
	_assert(transcript.any(func(entry): return str(entry.get("text", "")).contains("思い出を開く")), "VM should localize choice text.")
	_assert(gallery.is_unlocked(&"cg_school"), "Meta commands should unlock gallery items.")
	_assert(gallery.is_unlocked(&"intro_replay"), "Meta commands should unlock replay items.")
	_assert(achievements.is_unlocked(&"first_memory"), "Meta commands should unlock achievements.")
	_assert(achievements.is_unlocked(&"collector"), "Meta commands should progress achievements.")


func _test_v1_0_release_tools() -> void:
	var manifest := ReleaseManifest.new()
	var manifest_data := manifest.to_dict()
	_assert(manifest_data["version"] == "1.0.0-alpha", "ReleaseManifest should expose the v1.0 alpha version.")
	_assert(manifest.package_name() == "novella-1.0.0-alpha.zip", "ReleaseManifest should build the package name.")
	_assert(manifest.should_package_path("addons/novella/plugin.cfg"), "ReleaseManifest should package addon files.")
	_assert(not manifest.should_package_path("GodotEngine/Godot.exe"), "ReleaseManifest should reject engine paths.")
	_assert(not manifest.should_package_path(".godot/imported/cache"), "ReleaseManifest should reject Godot cache paths.")

	var validator := ReleaseValidator.new()
	var file_list := _release_file_list_for_tests()
	var plugin_cfg_text := _plugin_cfg_text_for_tests()
	var result := validator.validate_release(file_list, plugin_cfg_text)
	_assert(result["ok"], "ReleaseValidator should accept the release file set: %s" % [result["issues"]])
	var package_files := validator.package_files(file_list)
	_assert(package_files.has("addons/novella/plugin.cfg"), "ReleaseValidator should include plugin.cfg in package files.")
	_assert(not package_files.has("GodotEngine/Godot.exe"), "ReleaseValidator should exclude engine files from package files.")
	var bad_result := validator.validate_release(file_list + ["GodotEngine/Godot.exe", "Novella_项目需求文档.md"], plugin_cfg_text)
	_assert(not bad_result["ok"], "ReleaseValidator should reject forbidden tracked paths.")
	var mismatch := validator.validate_version_pair(plugin_cfg_text.replace("1.0.0-alpha", "0.5.0-alpha"))
	_assert(not mismatch["ok"], "ReleaseValidator should reject version mismatches.")


func _test_vm_milestone_script() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_sample_script(), "v0_2_demo.nvs")
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	var presentation := PresentationCommands.new()
	var managers := _make_v0_2_managers()
	var printer_manager: PrinterManager = managers["printer_manager"]
	var character_manager: CharacterManager = managers["character_manager"]
	var background_manager: BackgroundManager = managers["background_manager"]
	var effect_manager: EffectManager = managers["effect_manager"]
	var audio_manager: AudioManager = managers["audio_manager"]
	var camera_director: CameraDirector = managers["camera_director"]
	basic.register_all(registry, variables)
	presentation.register_all(registry, managers)
	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.printer_manager = printer_manager
	vm.load_script(ast)
	var transcript := vm.run()
	_assert(not transcript.any(func(entry): return entry.get("type", "") == "error"), "VM should not emit runtime errors: %s" % [transcript])
	_assert(variables.get_variable(&"affinity") == 5, "VM should execute @set affinity += 5.")
	_assert(transcript.any(func(entry): return entry.get("type", "") == "dialogue" and str(entry.get("text", "")).contains("Affinity: 5")), "VM should interpolate affinity into dialogue.")
	_assert(transcript.any(func(entry): return entry.get("presentation", {}).get("mode", "") == "nvl"), "VM should dispatch dialogue to NVL printer after @mode nvl: %s" % [transcript])
	_assert(background_manager.get_state()["background"]["id"] == "sunset", "VM should execute background commands.")
	_assert(character_manager.get_character_state(&"Ryone")["position_name"] == "right", "VM should execute character move commands.")
	_assert(effect_manager.get_state()["active_effects"].size() >= 2, "VM should execute screen and character effects.")
	_assert(audio_manager.get_state()["channels"][&"bgm"]["playing"] == false, "VM should execute music stop command.")
	_assert(audio_manager.get_state()["channels"][&"voice"]["playing"] == false, "VM should execute voice stop command.")
	_assert(camera_director.get_state()["zoom"] == Vector2.ONE, "VM should execute camera reset command.")
	_assert(transcript.back().get("text", "") == "Demo end.", "VM should finish at end_path dialogue.")


func _sample_script() -> String:
	return """@var affinity = 0

label start:
    @bg school transition:dissolve time:1.5
    @char Ryone uniform happy pos:left enter:slide
    @play_music main_theme fade:2.0 volume:0.8
    @camera pos:10,20 zoom:1.2 time:0.5
    Ryone: Welcome to Novella.
    @set affinity += 5
    menu:
        "Greet" if affinity >= 0:
            jump greet_path
        "Ignore":
            jump ignore_path

label greet_path:
    Ryone: Nice to meet you! Affinity: {affinity}
    @char_emotion Ryone happy
    @char_move Ryone pos:right time:0.5
    @char_effect Ryone shake intensity:0.5 duration:0.2
    @shake intensity:0.4 duration:0.2
    @play_se door_open volume:0.7
    @play_voice ryone_001 wait:true
    @mode nvl
    Ryone: {b}This line uses NVL mode.{/b}
    @nvl_clear
    @bg sunset transition:fade time:0.8
    @camera_reset time:0.2
    @stop_music fade:0.5
    @stop_voice
    jump end_path

label ignore_path:
    Ryone: Why ignore me? Affinity: {affinity}
    jump end_path

label end_path:
    @mode adv
    Ryone: Demo end."""


func _v0_3_sample_script() -> String:
	return """@var affinity = 0

label start:
    Ryone: Begin.
    @set affinity += 5
    @quick_save
    @auto on delay:0.1
    @skip read
    menu:
        "Continue {affinity}" if affinity >= 5:
            Ryone: Chosen.
    @quick_menu hide
    Ryone: Done."""


func _v0_4_sample_script() -> String:
	return """label start:
    @bg school_day transition:dissolve
    @char Ryone uniform happy pos:left
    Ryone: Welcome.
    menu:
        "Stay":
            jump stay_path
        "Leave":
            jump leave_path

label stay_path:
    @play_music main_theme
    Ryone: Thank you.
    jump leave_path

label leave_path:
    @camera_reset
    Ryone: See you."""


func _v0_5_sample_script() -> String:
	return """@var player = "Yue"

label start:
    @locale ja
    Ryone: $line.greeting
    menu:
        "$choice.unlock":
            @gallery unlock cg_school type:cg title:School asset:school.png
            @replay unlock intro_replay label:start title:Intro
            @achievement register collector title:Collector target:2
            @achievement progress collector amount:1
            @achievement progress collector amount:1
            @achievement unlock first_memory title:FirstMemory
            Ryone: Done."""


func _make_v0_2_managers() -> Dictionary:
	return {
		"printer_manager": PrinterManager.new(),
		"character_manager": CharacterManager.new(),
		"background_manager": BackgroundManager.new(),
		"effect_manager": EffectManager.new(),
		"audio_manager": AudioManager.new(),
		"camera_director": CameraDirector.new(),
	}


func _make_v0_3_managers() -> Dictionary:
	var managers := _make_v0_2_managers()
	managers["choice_manager"] = ChoiceManager.new()
	managers["save_manager"] = SaveManager.new()
	managers["rollback_manager"] = RollbackManager.new()
	managers["skip_manager"] = SkipManager.new()
	managers["auto_manager"] = AutoManager.new()
	managers["backlog_manager"] = BacklogManager.new()
	managers["quick_menu_manager"] = QuickMenuManager.new()
	return managers


func _make_v0_5_managers() -> Dictionary:
	var managers := _make_v0_3_managers()
	managers["localization_manager"] = LocalizationManager.new()
	managers["gallery_manager"] = GalleryManager.new()
	managers["achievement_manager"] = AchievementManager.new()
	managers["variable_manager"] = VariableManager.new()
	return managers


func _state_providers_from(managers: Dictionary) -> Dictionary:
	var providers := {
		&"printer": managers["printer_manager"],
		&"characters": managers["character_manager"],
		&"background": managers["background_manager"],
		&"effects": managers["effect_manager"],
		&"audio": managers["audio_manager"],
		&"camera": managers["camera_director"],
		&"choices": managers["choice_manager"],
		&"skip": managers["skip_manager"],
		&"auto": managers["auto_manager"],
		&"backlog": managers["backlog_manager"],
		&"quick_menu": managers["quick_menu_manager"],
	}
	if managers.has("localization_manager"):
		providers[&"localization"] = managers["localization_manager"]
	if managers.has("gallery_manager"):
		providers[&"gallery"] = managers["gallery_manager"]
	if managers.has("achievement_manager"):
		providers[&"achievements"] = managers["achievement_manager"]
	return providers


func _known_commands_for_tests() -> Array:
	return [
		&"var", &"set", &"flag", &"wait", &"mode", &"jump", &"call", &"return",
		&"char", &"char_remove", &"char_move", &"char_emotion", &"char_effect",
		&"bg", &"bg_remove", &"scene", &"env",
		&"play_music", &"stop_music", &"play_se", &"play_voice", &"stop_voice", &"ambience",
		&"camera", &"camera_shake", &"camera_reset",
		&"shake", &"flash", &"fade", &"effect", &"nvl_clear",
		&"save", &"load", &"quick_save", &"quick_load", &"auto_save",
		&"rollback", &"prevent_rollback", &"allow_rollback", &"fix_rollback",
		&"skip", &"prevent_skip", &"allow_skip",
		&"auto", &"prevent_auto", &"allow_auto",
		&"backlog_clear", &"choice_timeout", &"quick_menu", &"input",
		&"locale", &"language", &"translation", &"tr_var",
		&"gallery", &"replay", &"achievement", &"achieve", &"meta_check",
	]


func _release_file_list_for_tests() -> Array:
	return [
		"README.md",
		"LICENSE",
		"project.godot",
		"addons/novella/plugin.cfg",
		"addons/novella/novella.gd",
		"addons/novella/novella_editor_plugin.gd",
		"addons/novella/core/constants.gd",
		"addons/novella/script/novella_vm.gd",
		"addons/novella/script/commands/basic_commands.gd",
		"addons/novella/script/commands/presentation_commands.gd",
		"addons/novella/script/commands/interaction_commands.gd",
		"addons/novella/script/commands/meta_commands.gd",
		"addons/novella/release/release_manifest.gd",
		"addons/novella/release/release_validator.gd",
		"docs/development.md",
		"docs/release.md",
		"docs/v1.0-alpha.md",
		"examples/scripts/v1_0_showcase.nvs",
		".github/workflows/release-check.yml",
		"scripts/test-godot.ps1",
		"scripts/validate-release.ps1",
		"scripts/package-addon.ps1",
		"tests/run_tests.gd",
	]


func _plugin_cfg_text_for_tests() -> String:
	return """[plugin]

name="Novella"
description="Commercial-grade visual novel / GalGame framework for Godot 4."
author="TodayYueC"
version="1.0.0-alpha"
script="novella_editor_plugin.gd"
"""


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
