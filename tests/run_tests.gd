extends SceneTree

const Lexer := preload("res://addons/novella/script/lexer.gd")
const Token := preload("res://addons/novella/script/token.gd")
const Constants := preload("res://addons/novella/core/constants.gd")
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
const RuntimeStageScene := preload("res://addons/novella/presentation/ui/runtime_stage.tscn")
const RuntimePlayerScene := preload("res://addons/novella/presentation/ui/runtime_player.tscn")
const CharacterManager := preload("res://addons/novella/presentation/characters/character_manager.gd")
const BackgroundManager := preload("res://addons/novella/presentation/backgrounds/background_manager.gd")
const EffectManager := preload("res://addons/novella/presentation/effects/effect_manager.gd")
const AudioManager := preload("res://addons/novella/presentation/audio/audio_manager.gd")
const CameraDirector := preload("res://addons/novella/presentation/camera/camera_director.gd")
const ChoiceManager := preload("res://addons/novella/interaction/choice_manager.gd")
const SaveManager := preload("res://addons/novella/state/save_manager.gd")
const SaveLoadPanelScene := preload("res://addons/novella/state/ui/save_load_panel.tscn")
const SettingsManager := preload("res://addons/novella/state/settings_manager.gd")
const SettingsPanelScene := preload("res://addons/novella/state/ui/settings_panel.tscn")
const RollbackManager := preload("res://addons/novella/state/rollback_manager.gd")
const SkipManager := preload("res://addons/novella/interaction/skip_manager.gd")
const AutoManager := preload("res://addons/novella/interaction/auto_manager.gd")
const BacklogManager := preload("res://addons/novella/state/backlog_manager.gd")
const QuickMenuManager := preload("res://addons/novella/interaction/quick_menu_manager.gd")
const EditorController := preload("res://addons/novella/editor/editor_controller.gd")
const OutlineBuilder := preload("res://addons/novella/editor/script_outline_builder.gd")
const TimelineModel := preload("res://addons/novella/editor/timeline_model.gd")
const TimelineEditorModel := preload("res://addons/novella/editor/timeline_editor_model.gd")
const ProductionWorkflow := preload("res://addons/novella/editor/production_workflow.gd")
const ScriptLanguageService := preload("res://addons/novella/editor/script_language_service.gd")
const TimelineEditorPanelScene := preload("res://addons/novella/editor/ui/timeline_editor_panel.tscn")
const ScriptDiagnostics := preload("res://addons/novella/editor/script_diagnostics.gd")
const TemplateLibrary := preload("res://addons/novella/editor/script_template_library.gd")
const AssetIndex := preload("res://addons/novella/editor/asset_index.gd")
const DeveloperTools := preload("res://addons/novella/debug/developer_tools.gd")
const FlowGraphBuilder := preload("res://addons/novella/debug/flow_graph_builder.gd")
const LocalizationManager := preload("res://addons/novella/meta/localization_manager.gd")
const GalleryManager := preload("res://addons/novella/meta/gallery_manager.gd")
const AchievementManager := preload("res://addons/novella/meta/achievement_manager.gd")
const OnDemandAssetLoader := preload("res://addons/novella/performance/on_demand_asset_loader.gd")
const ScriptMigration := preload("res://addons/novella/script/script_migration.gd")
const CompatibilityMatrix := preload("res://addons/novella/release/compatibility_matrix.gd")
const ReleaseManifest := preload("res://addons/novella/release/release_manifest.gd")
const ReleaseValidator := preload("res://addons/novella/release/release_validator.gd")

var failures: Array[String] = []

func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("Novella v1.3.0 tests passed.")
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
	_test_runtime_stage_view()
	_test_runtime_player_view()
	_test_v0_2_managers()
	_test_v0_3_interaction_managers()
	_test_v0_3_interaction_views()
	_test_v0_3_commands_and_vm_state()
	_test_v0_4_editor_models()
	_test_v0_4_editor_dock()
	_test_v0_5_meta_managers()
	_test_v0_5_meta_views()
	_test_v0_5_commands_and_localized_vm()
	_test_v1_0_script_control_flow()
	_test_v1_0_1_interactive_choice_resume()
	_test_v1_0_release_hardening()
	_test_v1_0_release_tools()
	_test_v1_2_production_workflow()
	_test_v1_3_developer_tooling()
	_test_vm_milestone_script()


func _test_lexer() -> void:
	var lexer := Lexer.new()
	var tokens := lexer.tokenize("@set affinity += 5\nlabel start:\nwhile affinity < 10:\n    continue")
	_assert(tokens.any(func(token): return token.type == Token.Type.COMMAND and token.literal == "set"), "Lexer should emit @set command token.")
	_assert(tokens.any(func(token): return token.type == Token.Type.KEYWORD and token.lexeme == "label"), "Lexer should emit label keyword.")
	_assert(tokens.any(func(token): return token.type == Token.Type.KEYWORD and token.lexeme == "while"), "Lexer should emit while keyword.")
	_assert(tokens.any(func(token): return token.type == Token.Type.KEYWORD and token.lexeme == "continue"), "Lexer should emit continue keyword.")
	_assert(lexer.errors.is_empty(), "Lexer should not report errors.")


func _test_parser() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_sample_script(), "sample.nvs")
	_assert(parser.errors.is_empty(), "Parser should not report errors: %s" % [parser.errors])
	_assert(ast.children.size() > 0, "Parser should create AST children.")
	_assert(ast.labels.has(&"start"), "Parser should collect start label.")
	_assert(ast.labels.has(&"greet_path"), "Parser should collect greet_path label.")
	_assert(ast.children.any(func(node): return node.kind == &"menu"), "Parser should create a menu node.")
	var control_ast = parser.parse(_v1_0_control_flow_script(), "control.nvs")
	_assert(parser.errors.is_empty(), "Parser should parse v1.0 control flow without errors: %s" % [parser.errors])
	_assert(control_ast.children.any(func(node): return node.kind == &"while"), "Parser should create while nodes.")


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
	_assert(registry.execute(&"if", "score == 5 then set score += 1", {"command_registry": registry})["ok"], "@if should execute conditional actions.")
	_assert(variables.get_variable(&"score") == 6, "@if should run nested commands when true.")
	_assert(registry.execute(&"if", "score < 0 then set score = 0", {"command_registry": registry})["skipped"], "@if should skip false branches.")
	var random_result := registry.execute(&"random", "win:100 lose:0 seed:1")
	_assert(random_result["jump"] == &"win", "@random should choose weighted jump targets.")
	_assert(registry.execute(&"bg", "school transition:dissolve time:1.0")["id"] == "school", "@bg should update background state.")
	_assert(registry.execute(&"play_music", "main_theme fade:1.0")["channel"] == "bgm", "@play_music should use BGM channel.")
	_assert(registry.execute(&"auto", "on delay:0.1")["enabled"], "@auto should start auto advance.")
	_assert(registry.execute(&"skip", "read")["mode"] == "read", "@skip should start read skip.")
	var settings_result := registry.execute(&"settings", "set text_speed:48 auto_delay:2.5 fullscreen:true")
	_assert(settings_result["changed"]["text_speed"] == 48.0, "@settings should update text speed.")
	_assert(settings_result["changed"]["fullscreen"] == true, "@settings should update toggles.")
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


func _test_runtime_stage_view() -> void:
	var stage_scene: PackedScene = RuntimeStageScene
	var stage = stage_scene.instantiate()
	stage.apply_background({"id": "school_day", "transition": "dissolve"})
	stage.apply_characters({
		&"Ryone": {"character_id": "Ryone", "attributes": ["uniform", "happy"], "position": 0.25, "focused": true},
		&"Mira": {"character_id": "Mira", "attributes": ["casual"], "position": 0.75, "focused": false},
	})
	stage.apply_line({"mode": "adv", "speaker": "Ryone", "text": "Hello"})
	stage.apply_effects({"active_effects": [{"effect": "flash", "target": "screen", "intensity": 0.8}]})
	stage.apply_audio({"channels": {&"bgm": {"playing": true, "id": "theme"}}})
	stage.apply_camera({"pos": Vector2(8, 4), "zoom": Vector2(1.1, 1.1)})
	_assert(stage.get_node("BackgroundLayer/BackgroundLabel").text == "school_day", "RuntimeStage should render background state.")
	_assert(stage.get_node("CharacterLayer").get_child_count() == 2, "RuntimeStage should render character markers.")
	_assert(stage.get_node("PrinterLayer/AdvPrinter/NameLabel").text == "Ryone", "RuntimeStage should render ADV dialogue.")
	_assert(stage.get_node("EffectLayer/EffectLabel").text.contains("flash"), "RuntimeStage should render effect labels.")
	_assert(stage.get_node("StatusLabel").text.contains("Camera"), "RuntimeStage should render camera state.")
	stage.clear()
	_assert(stage.get_node("CharacterLayer").get_child_count() == 0, "RuntimeStage should clear characters.")
	stage.free()


func _test_runtime_player_view() -> void:
	var managers := _make_v0_5_managers()
	var variables: VariableManager = managers["variable_manager"]
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	var presentation := PresentationCommands.new()
	var interaction := InteractionCommands.new()
	var meta := MetaCommands.new()
	basic.register_all(registry, variables)
	presentation.register_all(registry, managers)
	interaction.register_all(registry, managers)
	meta.register_all(registry, managers)
	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.printer_manager = managers["printer_manager"]
	vm.choice_manager = managers["choice_manager"]
	vm.save_manager = managers["save_manager"]
	vm.rollback_manager = managers["rollback_manager"]
	vm.skip_manager = managers["skip_manager"]
	vm.auto_manager = managers["auto_manager"]
	vm.backlog_manager = managers["backlog_manager"]
	vm.quick_menu_manager = managers["quick_menu_manager"]
	vm.localization_manager = managers["localization_manager"]
	vm.gallery_manager = managers["gallery_manager"]
	vm.achievement_manager = managers["achievement_manager"]
	vm.state_providers = _state_providers_from(managers)
	var player = RuntimePlayerScene.instantiate()
	var runtime_context := managers.duplicate()
	runtime_context["parser"] = Parser.new()
	runtime_context["vm"] = vm
	runtime_context["quick_menu_manager"] = managers["quick_menu_manager"]
	player.bind_runtime(runtime_context)
	var transcript = player.start_script(_v1_1_runtime_player_script(), "runtime_player.nvs")
	_assert(vm.pause_on_text, "RuntimePlayer should enable text pause mode.")
	_assert(not vm.auto_select_choices, "RuntimePlayer should disable automatic menu choices.")
	_assert(vm.waiting_for_advance, "RuntimePlayer should pause on the first dialogue line.")
	_assert(transcript.size() == 1 and transcript[0]["type"] == "dialogue", "RuntimePlayer should present the first line before waiting.")
	_assert(player.get_node("RuntimeStage/PrinterLayer/AdvPrinter/NameLabel").text == "Ryone", "RuntimePlayer should bind the stage to printer output.")
	player.advance()
	_assert(vm.waiting_for_choice, "RuntimePlayer should advance from text wait to choice wait.")
	_assert(player.get_node("ChoicePanel").visible, "RuntimePlayer should show choice buttons when the VM waits for a menu.")
	_assert(player.get_node("ChoicePanel/ChoiceList").get_child_count() == 2, "RuntimePlayer should create one button per choice.")
	player.choose_choice(1)
	_assert(variables.get_variable(&"path") == "right", "RuntimePlayer should route selected choice actions into the VM.")
	_assert(vm.waiting_for_advance, "RuntimePlayer should pause on the branch dialogue after choosing.")
	_assert(player.get_node("RuntimeStage/PrinterLayer/AdvPrinter/TextLabel").text.contains("Right path."), "RuntimePlayer should present the selected branch line.")
	player.advance()
	_assert(vm.is_finished(), "RuntimePlayer should finish after advancing the last line.")
	var quick_result: Dictionary = player.dispatch_quick_action(&"auto")
	_assert(bool(quick_result.get("ok", false)), "RuntimePlayer should dispatch quick menu actions.")
	player.free()


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
	save_manager.configure({"slot_count": 64, "page_size": 8, "chapter": "Intro"})
	save_manager.set_playtime(125.0)
	var saved := save_manager.save_game(&"slot1", {"variables": variables.snapshot()}, {"chapter": "intro"})
	_assert(saved["ok"], "SaveManager should save to memory storage.")
	_assert(saved["version"] == Constants.VERSION, "SaveManager should write the current plugin version.")
	_assert(saved["metadata"]["playtime"] == "00:02:05", "SaveManager should format playtime metadata.")
	_assert(save_manager.list_saves().size() == 1, "SaveManager should list memory saves.")
	save_manager.save_game(&"slot_1", {"index": 1}, {"title": "Opening", "summary": "Classroom", "thumbnail": "res://thumbs/opening.png"})
	var slot_page := save_manager.list_slots()
	_assert(slot_page.size() == 8, "SaveManager should build default 8-slot pages.")
	_assert(save_manager.page_count() == 8, "SaveManager should default to 8 pages of 8 slots.")
	_assert(slot_page[0]["occupied"], "SaveManager should mark occupied numbered slots.")
	_assert(slot_page[0]["title"] == "Opening", "SaveManager should expose slot titles.")
	_assert(not slot_page[1]["occupied"], "SaveManager should expose empty numbered slots.")
	_assert(save_manager.autosave_if(&"choice", {"choice": 1})["slot"] == "auto", "SaveManager should autosave enabled triggers.")
	_assert(save_manager.autosave_if(&"timed", {"tick": 1})["skipped"], "SaveManager should skip disabled autosave triggers.")
	_assert(not save_manager.capture_thumbnail(null, "user://missing.png")["ok"], "SaveManager should report missing thumbnail viewports.")
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

	var settings := SettingsManager.new()
	settings.set_setting(&"text_speed", 42)
	settings.set_setting(&"master_volume", 2.0)
	settings.set_setting(&"fullscreen", "true")
	settings.apply_to(variables, auto)
	_assert(settings.get_setting(&"master_volume") == 1.0, "SettingsManager should clamp volume values.")
	_assert(variables.get_variable(&"text_speed") == 42.0, "SettingsManager should expose settings variables.")
	_assert(settings.get_setting(&"fullscreen") == true, "SettingsManager should coerce boolean values.")


func _test_v0_3_interaction_views() -> void:
	var choice_scene: PackedScene = load("res://addons/novella/interaction/ui/choice_menu.tscn")
	var backlog_scene: PackedScene = load("res://addons/novella/interaction/ui/backlog_panel.tscn")
	var quick_scene: PackedScene = load("res://addons/novella/interaction/ui/quick_menu.tscn")
	var save_load_scene: PackedScene = SaveLoadPanelScene
	var settings_scene: PackedScene = SettingsPanelScene
	var choice_view = choice_scene.instantiate()
	var backlog_view = backlog_scene.instantiate()
	var quick_view = quick_scene.instantiate()
	var save_load_view = save_load_scene.instantiate()
	var settings_view = settings_scene.instantiate()
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
	save_load_view.apply_slots([
		{"slot": "slot_1", "occupied": true, "title": "Opening", "summary": "Classroom", "saved_at": "2026-04-28 10:00"},
		{"slot": "slot_2", "occupied": false},
	], &"load", 0, 2)
	settings_view.apply_settings({
		"text_speed": 44.0,
		"auto_delay": 1.2,
		"master_volume": 0.8,
		"music_volume": 0.7,
		"voice_volume": 0.6,
		"sfx_volume": 0.5,
		"fullscreen": true,
		"skip_unread": true,
		"locale": "zh_CN",
	})
	_assert(choice_view.get_node("ChoiceList").get_child_count() == 2, "Choice menu view should create buttons.")
	_assert(backlog_view.get_node("TextLabel").text.contains("Ryone: Hello"), "Backlog panel should render dialogue lines.")
	_assert(quick_view.get_node("ActionBar").get_child_count() == 2, "Quick menu view should create action buttons.")
	_assert(save_load_view.get_node("Root/SlotGrid").get_child_count() == 2, "Save/load panel should render slot cards.")
	_assert(save_load_view.get_node("Root/Footer/PageLabel").text == "Page 1 / 2", "Save/load panel should render page state.")
	var requested := {"delete": &""}
	save_load_view.slot_delete_requested.connect(func(slot): requested["delete"] = slot)
	save_load_view.request_confirmation(&"delete", &"slot_1")
	_assert(save_load_view.get_node("Root/ConfirmPanel").visible, "Save/load panel should show confirmations.")
	save_load_view.confirm_pending()
	_assert(requested["delete"] == &"slot_1", "Save/load panel should emit confirmed delete requests.")
	var changed := {"key": &"", "value": null}
	settings_view.setting_changed.connect(func(key, value): changed["key"] = key; changed["value"] = value)
	settings_view._on_slider_changed(50.0, &"text_speed")
	_assert(changed["key"] == &"text_speed" and changed["value"] == 50.0, "Settings panel should emit changed slider values.")
	_assert(settings_view.get_node("Root/fullscreenToggle").button_pressed, "Settings panel should apply toggle state.")
	choice_view.free()
	backlog_view.free()
	quick_view.free()
	save_load_view.free()
	settings_view.free()


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
	var timeline_editor := TimelineEditorModel.new()
	timeline_editor.load_events(timeline["events"])
	timeline_editor.add_event(&"dialogue", {"speaker": "Ryone", "text": "Inserted", "line": 99}, 1)
	_assert(timeline_editor.get_events()[1]["text"] == "Inserted", "TimelineEditorModel should insert event blocks.")
	_assert(timeline_editor.move_event(1, 2)["moved"], "TimelineEditorModel should reorder event blocks.")
	_assert(timeline_editor.update_event(2, {"text": "Updated"})["text"] == "Updated", "TimelineEditorModel should edit event blocks.")
	_assert(timeline_editor.duplicate_event(2)["ok"], "TimelineEditorModel should duplicate event blocks.")
	_assert(timeline_editor.delete_event(3)["ok"], "TimelineEditorModel should delete event blocks.")
	_assert(timeline_editor.undo()["ok"], "TimelineEditorModel should support undo.")
	_assert(timeline_editor.redo()["ok"], "TimelineEditorModel should support redo.")
	_assert(timeline_editor.to_script().contains("Ryone: Updated"), "TimelineEditorModel should serialize events back to script text.")
	_assert(timeline_editor.find_events("Updated").size() == 1, "TimelineEditorModel should search event fields.")
	var replaced := timeline_editor.replace_text("Updated", "Timeline")
	_assert(replaced["replaced"] == 1, "TimelineEditorModel should replace text across events.")
	_assert(timeline_editor.to_script().contains("Ryone: Timeline"), "TimelineEditorModel should serialize replaced text.")

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
	_assert(indexer.find_by_id(index, "ryone", ["characters"]).get("path", "").contains("ryone"), "AssetIndex should find assets by folder or id tags.")
	var reference_report := indexer.validate_references(index, [{"id": "school", "categories": ["backgrounds"]}, {"id": "missing", "categories": ["audio"]}])
	_assert(reference_report["valid_assets"].size() == 1, "AssetIndex should validate known references.")
	_assert(reference_report["missing_assets"].size() == 1, "AssetIndex should report missing references.")


func _test_v0_4_editor_dock() -> void:
	var dock_scene: PackedScene = load("res://addons/novella/editor/ui/novella_editor_dock.tscn")
	var dock = dock_scene.instantiate()
	var panel = TimelineEditorPanelScene.instantiate()
	var controller := EditorController.new()
	var analysis := controller.analyze_source(_v0_4_sample_script(), "res://story/chapter_01.nvs", _known_commands_for_tests())
	dock.apply_templates(controller.templates.list_templates())
	dock.apply_analysis(analysis)
	_assert(dock.get_node("Root/Tabs/Outline").get_root().get_child_count() > 0, "Editor dock should render outline rows.")
	_assert(dock.get_node("Root/Tabs/Timeline").get_root().get_child_count() > 0, "Editor dock should render timeline rows.")
	_assert(dock.get_node("Root/Tabs/Visual/Root/EventList").item_count > 0, "Editor dock should render visual timeline event blocks.")
	_assert(dock.get_node("Root/Tabs/Diagnostics").text.contains("Errors: 0"), "Editor dock should render diagnostic counts.")
	_assert(dock.get_node("Root/Tabs/Templates").item_count >= 4, "Editor dock should render template entries.")
	panel.apply_events(analysis["timeline"]["events"])
	var moved := {"from": -1, "to": -1}
	panel.event_moved.connect(func(from_index, to_index): moved["from"] = from_index; moved["to"] = to_index)
	panel.get_node("Root/EventList").select(1)
	panel._on_item_selected(1)
	panel._on_move_up_pressed()
	_assert(moved["from"] == 1 and moved["to"] == 0, "TimelineEditorPanel should emit move events.")
	panel.set_mode(&"text")
	_assert(panel.get_node("Root/Toolbar/ModeButton").text.contains("text"), "TimelineEditorPanel should toggle editing modes.")
	dock.free()
	panel.free()


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
	var csv := localization.export_csv(&"en")
	_assert(csv.contains("hello,Hello {player}."), "LocalizationManager should export CSV entries.")
	var imported := localization.import_csv(&"fr", "key,text\nhello,\"Bonjour {player}.\"\nquote,\"A \"\"quoted\"\" line\"\n", true)
	_assert(imported["imported"] == 2, "LocalizationManager should import CSV rows.")
	localization.set_locale(&"fr")
	_assert(localization.translate(&"hello", variables) == "Bonjour Yue.", "LocalizationManager should use imported CSV translations.")
	_assert(localization.translate(&"quote") == "A \"quoted\" line", "LocalizationManager should unescape quoted CSV fields.")
	var template := localization.export_template([&"hello", &"missing"], &"fr")
	_assert(template.contains("hello,\"Bonjour {player}.\"") or template.contains("hello,Bonjour {player}."), "LocalizationManager should export translator templates.")
	var coverage := localization.coverage_report([&"hello", &"missing"], [&"fr"])
	_assert(coverage["locales"]["fr"]["translated"] == 1, "LocalizationManager should report translation coverage.")
	localization.translate(&"missing")
	_assert(localization.merge_missing_keys(&"fr")["added"] >= 1, "LocalizationManager should merge missing keys into a locale catalog.")

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


func _test_v1_0_script_control_flow() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_v1_0_control_flow_script(), "v1_0_control_flow.nvs")
	_assert(parser.errors.is_empty(), "Parser should accept v1.0 control flow syntax: %s" % [parser.errors])
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	basic.register_all(registry, variables)
	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.load_script(ast)
	var transcript := vm.run()
	_assert(not transcript.any(func(entry): return entry.get("type", "") == "error"), "VM control flow should not emit runtime errors: %s" % [transcript])
	_assert(variables.get_variable(&"count") == 3, "VM should execute while loops with break/continue.")
	_assert(variables.get_variable(&"inline_count") == 3, "VM should execute inline commands after dialogue and narration.")
	_assert(transcript.any(func(entry): return str(entry.get("text", "")).contains("Count 1")), "VM should present loop dialogue before continue.")
	_assert(not transcript.any(func(entry): return str(entry.get("text", "")).contains("Count 2")), "VM should skip dialogue when continue is executed.")
	_assert(transcript.any(func(entry): return str(entry.get("text", "")).contains("Count 3")), "VM should present dialogue before break.")
	_assert(transcript.any(func(entry): return str(entry.get("text", "")).contains("Done.")), "@random should jump to the selected weighted label.")
	_assert(not transcript.any(func(entry): return str(entry.get("text", "")).contains("Wrong.")), "@random should avoid zero-weight branches.")


func _test_v1_0_1_interactive_choice_resume() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_v1_0_1_interactive_choice_script(), "v1_0_1_interactive_choice.nvs")
	_assert(parser.errors.is_empty(), "Parser should accept v1.0.1 interactive choice script: %s" % [parser.errors])
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	basic.register_all(registry, variables)
	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.choice_manager = ChoiceManager.new()
	vm.auto_select_choices = false
	vm.load_script(ast)
	var transcript := vm.run()
	_assert(vm.waiting_for_choice, "VM should pause at menu when auto_select_choices is false.")
	_assert(transcript.size() == 1 and transcript[0]["type"] == "dialogue", "VM should stop before appending a choice transcript.")
	var pending := vm.get_pending_choice()
	_assert(pending["choices"].size() == 2, "VM should expose pending choices for UI.")
	_assert(pending["available_indices"].has(1), "VM should expose available choice indices.")
	var snapshot := vm.snapshot_state()
	var restored_variables := VariableManager.new()
	var restored_registry := CommandRegistry.new()
	var restored_basic := BasicCommands.new()
	restored_basic.register_all(restored_registry, restored_variables)
	var restored_vm := VM.new()
	restored_vm.variable_manager = restored_variables
	restored_vm.command_registry = restored_registry
	restored_vm.choice_manager = ChoiceManager.new()
	restored_vm.auto_select_choices = false
	restored_vm.load_script(ast)
	restored_vm.restore_state(snapshot)
	_assert(restored_vm.waiting_for_choice, "VM should restore pending choice state from snapshots.")
	var chosen := restored_vm.choose(1)
	_assert(chosen["ok"], "VM should accept a valid pending choice: %s" % [chosen])
	_assert(not restored_vm.waiting_for_choice, "VM should clear the pending choice after choose().")
	_assert(restored_vm.is_finished(), "VM should finish after resolving the chosen branch.")
	_assert(restored_variables.get_variable(&"path") == "right", "VM should execute actions for the selected pending choice.")
	_assert(restored_vm.transcript.any(func(entry): return entry.get("type", "") == "choice" and entry.get("index", -1) == 1), "VM should append the selected choice to transcript.")
	_assert(restored_vm.transcript.any(func(entry): return str(entry.get("text", "")).contains("Path: right.")), "VM should continue execution after choose().")
	var invalid := restored_vm.choose(0)
	_assert(not invalid["ok"], "VM should reject choose() when not waiting for a choice.")


func _test_v1_0_release_hardening() -> void:
	var migration := ScriptMigration.new()
	var legacy_source := """@language ja
label start:
    @achieve unlock first_step title:First
    Ryone: Hello."""
	var migrated := migration.migrate(legacy_source)
	_assert(migrated["ok"], "ScriptMigration should migrate supported legacy scripts.")
	_assert(migrated["from_version"] == "legacy", "ScriptMigration should detect scripts without version headers as legacy.")
	_assert(str(migrated["source"]).begins_with("# novella_version: 1.0"), "ScriptMigration should add a script version header.")
	_assert(str(migrated["source"]).contains("@locale ja"), "ScriptMigration should rewrite @language to @locale.")
	_assert(str(migrated["source"]).contains("@achievement unlock"), "ScriptMigration should rewrite @achieve to @achievement.")
	_assert(migration.check_source(migrated["source"])["ok"], "ScriptMigration should accept migrated scripts.")

	var matrix := CompatibilityMatrix.new()
	var validation := matrix.validate_primary()
	_assert(validation["ok"], "CompatibilityMatrix should include declared min and primary versions: %s" % [validation["issues"]])
	_assert(matrix.get_targets().size() == 4, "CompatibilityMatrix should list Godot 4.3 through 4.6 targets.")
	_assert(matrix.get_minimum_target()["version"] == "4.3", "CompatibilityMatrix should expose Godot 4.3 as the minimum target.")
	_assert(matrix.get_primary_target()["version"] == "4.6", "CompatibilityMatrix should expose Godot 4.6 as the primary target.")
	_assert(matrix.runtime_status({"major": 4, "minor": 6})["primary"], "CompatibilityMatrix should mark Godot 4.6 as primary.")
	_assert(matrix.runtime_status({"major": 4, "minor": 3})["supported"], "CompatibilityMatrix should support Godot 4.3.")
	_assert(not matrix.runtime_status({"major": 3, "minor": 5})["supported"], "CompatibilityMatrix should reject Godot 3.x.")


func _test_v1_0_release_tools() -> void:
	var manifest := ReleaseManifest.new()
	var manifest_data := manifest.to_dict()
	_assert(manifest_data["version"] == Constants.VERSION, "ReleaseManifest should expose the current v1.0 version.")
	_assert(manifest_data["release_channel"] == "stable", "ReleaseManifest should expose the stable channel for v1.0.1.")
	_assert(manifest_data["required_files"].has("addons/novella/script/script_migration.gd"), "ReleaseManifest should require script migration.")
	_assert(manifest_data["required_files"].has("addons/novella/release/compatibility_matrix.gd"), "ReleaseManifest should require compatibility matrix.")
	_assert(manifest_data["required_files"].has("docs/api.md"), "ReleaseManifest should require API docs.")
	_assert(manifest.package_name() == "novella-%s.zip" % Constants.VERSION, "ReleaseManifest should build the package name.")
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
	_assert(package_files.has("tests/run_tests.gd"), "ReleaseValidator should include the test runner in package files.")
	_assert(not package_files.has("GodotEngine/Godot.exe"), "ReleaseValidator should exclude engine files from package files.")
	var bad_result := validator.validate_release(file_list + ["GodotEngine/Godot.exe", "Novella_项目需求文档.md"], plugin_cfg_text)
	_assert(not bad_result["ok"], "ReleaseValidator should reject forbidden tracked paths.")
	var mismatch := validator.validate_version_pair(plugin_cfg_text.replace(Constants.VERSION, "0.5.0-alpha"))
	_assert(not mismatch["ok"], "ReleaseValidator should reject version mismatches.")


func _test_v1_2_production_workflow() -> void:
	var asset_paths := [
		"res://art/backgrounds/school_day.png",
		"res://art/characters/ryone/uniform_happy.png",
		"res://audio/bgm/main_theme.ogg",
		"res://story/chapter_01.nvs",
	]
	var source := _v1_2_production_workflow_script()
	var workflow := ProductionWorkflow.new()
	var index := workflow.build_project_index(asset_paths)
	_assert(workflow.asset_index.summarize(index)["total"] == 4, "ProductionWorkflow should build a complete project asset index.")
	var analysis := workflow.analyze_script(source, "chapter_01.nvs", _known_commands_for_tests(), asset_paths)
	_assert(analysis["ok"], "ProductionWorkflow should analyze a valid production script: %s" % [analysis])
	_assert(analysis["assets"]["missing_assets"].is_empty(), "ProductionWorkflow should validate referenced assets.")
	_assert(analysis["localization"]["keys"].has("line.greeting"), "ProductionWorkflow should extract translation command keys.")
	_assert(analysis["localization"]["keys"].has("choice.stay"), "ProductionWorkflow should extract localized choice keys.")
	var missing_assets := workflow.validate_asset_references(source, asset_paths.slice(0, 2), "chapter_01.nvs")
	_assert(missing_assets["missing_assets"].any(func(item): return item.get("id", "") == "main_theme"), "ProductionWorkflow should report missing referenced audio.")

	var template := workflow.export_localization_template([{"source": source, "file_path": "chapter_01.nvs"}], &"zh")
	_assert(template.contains("line.greeting"), "ProductionWorkflow should export localization templates.")
	var imported := workflow.import_localization_csv(&"zh", "key,text\nline.greeting,Localized hello.\nchoice.stay,Localized stay\n", false)
	_assert(imported["imported"] == 2, "ProductionWorkflow should import localization CSV files.")
	var preview := workflow.preview_localized_source(source, &"zh", "chapter_01.nvs")
	_assert(str(preview["script"]).contains("Localized hello."), "ProductionWorkflow should preview localized dialogue.")
	_assert(str(preview["script"]).contains("\"Localized stay\""), "ProductionWorkflow should preview localized menu choices.")

	var session := workflow.create_timeline_session(source, "chapter_01.nvs")
	_assert(session["ok"] and session["events"].size() > 0, "ProductionWorkflow should create timeline edit sessions.")
	var session_events: Array = session["events"]
	session_events[7] = session_events[7].duplicate(true)
	session_events[7]["text"] = "Hello from timeline."
	var exported := workflow.export_timeline_script(session_events)
	_assert(exported.contains("Hello from timeline."), "ProductionWorkflow should export edited timeline scripts.")
	var roundtrip := workflow.roundtrip_script(source, "chapter_01.nvs")
	_assert(roundtrip["ok"], "ProductionWorkflow should round-trip editable scripts without parse errors: %s" % [roundtrip])


func _test_v1_3_developer_tooling() -> void:
	var source := _v1_3_tooling_script()
	var asset_paths := [
		"res://art/backgrounds/school_day.png",
		"res://art/characters/ryone/uniform_happy.png",
		"res://audio/bgm/main_theme.ogg",
	]
	var indexer := AssetIndex.new()
	var index := indexer.build(asset_paths)
	var language := ScriptLanguageService.new()
	var language_report := language.analyze(source, "tooling.nvs", _known_commands_for_tests(), index)
	_assert(language_report["ok"], "ScriptLanguageService should analyze valid scripts.")
	_assert(language_report["syntax_tokens"].any(func(token): return token.get("kind", "") == "command" and token.get("text", "") == "bg"), "ScriptLanguageService should emit command syntax tokens.")
	_assert(language_report["symbols"]["labels"].any(func(symbol): return symbol.get("name", "") == "stay_path"), "ScriptLanguageService should collect label symbols.")
	_assert(language_report["symbols"]["variables"].any(func(symbol): return symbol.get("name", "") == "affinity"), "ScriptLanguageService should collect variable symbols.")
	_assert(language.complete_at("@", 1, 2, {"commands": _known_commands_for_tests()}).any(func(item): return item.get("insert_text", "") == "@var"), "ScriptLanguageService should complete commands.")
	_assert(language.complete_at(source, 13, 18, {"file_path": "tooling.nvs"}).any(func(item): return item.get("insert_text", "") == "stay_path"), "ScriptLanguageService should complete jump targets.")
	_assert(language.definition_at(source, 13, 20, "tooling.nvs").get("line", 0) == 17, "ScriptLanguageService should jump to label definitions.")
	_assert(language.find_references(source, "affinity").size() >= 2, "ScriptLanguageService should find variable references.")

	var parser := Parser.new()
	var ast = parser.parse(source, "tooling.nvs")
	var graph_builder := FlowGraphBuilder.new()
	var graph := graph_builder.build(ast)
	_assert(graph["stats"]["by_type"]["label"] == 3, "FlowGraphBuilder should create label route nodes.")
	_assert(graph["edges"].any(func(edge): return edge.get("to", "") == "label:stay_path"), "FlowGraphBuilder should connect choices to jump targets.")
	_assert(graph_builder.reachable_labels(graph).has("label:leave_path"), "FlowGraphBuilder should calculate reachable route labels.")
	_assert(graph_builder.unlock_node(graph, "label:stay_path")["nodes"].any(func(node): return node.get("id", "") == "label:stay_path" and node.get("unlocked", false)), "FlowGraphBuilder should mark route nodes as unlocked.")

	var workflow := ProductionWorkflow.new()
	var production := workflow.analyze_script(source, "tooling.nvs", _known_commands_for_tests(), asset_paths)
	var plan := workflow.build_asset_load_plan(source, asset_paths, "tooling.nvs", {"dry_run": true})
	_assert(plan["ok"], "OnDemandAssetLoader should build valid asset load plans: %s" % [plan])
	_assert(plan["summary"]["total"] == 3, "OnDemandAssetLoader should queue referenced background, character, and audio assets.")
	var loader := OnDemandAssetLoader.new()
	var load_result := loader.load_next(plan, {"dry_run": true})
	_assert(load_result["ok"] and loader.get_loaded_assets().size() == 1, "OnDemandAssetLoader should dry-run load queued assets.")
	_assert(loader.release_unused([])["released"].size() == 1, "OnDemandAssetLoader should release unused assets.")
	_assert(workflow.language_report(source, "tooling.nvs", _known_commands_for_tests(), asset_paths)["symbols"]["labels"].size() == 3, "ProductionWorkflow should expose language service reports.")
	_assert(workflow.build_flow_graph(source, "tooling.nvs")["stats"]["nodes"] >= 3, "ProductionWorkflow should expose flow graph reports.")
	_assert(production["assets"]["missing_assets"].is_empty(), "ProductionWorkflow should still validate assets in v1.3.0.")

	var tools := DeveloperTools.new()
	var variables := VariableManager.new()
	variables.declare_variable(&"affinity", 1)
	_assert(tools.variable_watch(variables)["game"]["affinity"] == 1, "DeveloperTools should watch runtime variables.")
	_assert(tools.set_variable(variables, &"affinity", 5)["value"] == 5, "DeveloperTools should edit runtime variables.")
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	basic.register_all(registry, variables)
	_assert(tools.execute_console("@set affinity += 2", registry, {"variables": variables})["ok"], "DeveloperTools should execute console commands.")
	_assert(variables.get_variable(&"affinity") == 7, "DeveloperTools console should mutate variables through command registry.")
	var vm := VM.new()
	vm.pause_on_text = true
	vm.load_script(parser.parse("label start:\n    Ryone: Trace me.", "trace.nvs"))
	vm.run()
	_assert(tools.trace_vm(vm)["waiting_for_advance"], "DeveloperTools should trace VM wait state.")
	_assert(tools.performance_snapshot(null)["ok"], "DeveloperTools should report performance snapshots.")


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


func _v1_0_control_flow_script() -> String:
	return """@var count = 0
@var inline_count = 0

label start:
    while count < 4:
        @set count += 1
        @if count == 2 then continue
        Ryone: Count {count}. @set inline_count += 1
        @if count >= 3 then break
    endwhile
    @random done:100 other:0 seed:1

label other:
    Ryone: Wrong.
    return

label done:
    Done. @set inline_count += 1"""


func _v1_0_1_interactive_choice_script() -> String:
	return """@var path = ""

label start:
    Ryone: Choose a path.
    menu:
        "Left":
            @set path = "left"
            jump ending
        "Right":
            @set path = "right"
            jump ending

label ending:
    Ryone: Path: {path}."""


func _v1_1_runtime_player_script() -> String:
	return """@var path = ""

label start:
    Ryone: Pick one.
    menu:
        "Left":
            @set path = "left"
            jump left_path
        "Right":
            @set path = "right"
            jump right_path

label left_path:
    Ryone: Left path.
    return

label right_path:
    Ryone: Right path."""


func _v1_2_production_workflow_script() -> String:
	return """@var affinity = 1

label start:
    @translation en line.greeting text:"Welcome {player}."
    @translation en choice.stay text:"Stay"
    @bg school_day transition:dissolve
    @char ryone uniform happy pos:left
    @play_music main_theme fade:1.0
    Ryone: $line.greeting
    menu:
        "$choice.stay" if affinity > 0:
            @set affinity += 1
            Ryone: $choice.stay"""


func _v1_3_tooling_script() -> String:
	return """@var affinity = 1
@var path = ""

label start:
    @translation en line.hello text:"Hello."
    @bg school_day transition:dissolve
    @char ryone uniform happy pos:left
    @play_music main_theme fade:1.0
    Ryone: $line.hello
    menu:
        "Stay" if affinity > 0:
            @set path = "stay"
            jump stay_path
        "Leave":
            jump leave_path

label stay_path:
    Ryone: Stayed.
    return

label leave_path:
    Ryone: Left."""


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
	managers["settings_manager"] = SettingsManager.new()
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
		&"settings": managers["settings_manager"],
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
		&"var", &"set", &"flag", &"wait", &"mode", &"if", &"random", &"jump", &"call", &"return",
		&"char", &"char_remove", &"char_move", &"char_emotion", &"char_effect",
		&"bg", &"bg_remove", &"scene", &"env",
		&"play_music", &"stop_music", &"play_se", &"play_voice", &"stop_voice", &"ambience",
		&"camera", &"camera_shake", &"camera_reset",
		&"shake", &"flash", &"fade", &"effect", &"nvl_clear",
		&"save", &"load", &"quick_save", &"quick_load", &"auto_save", &"settings", &"config",
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
		"addons/novella/debug/developer_tools.gd",
		"addons/novella/debug/flow_graph_builder.gd",
		"addons/novella/editor/production_workflow.gd",
		"addons/novella/editor/script_language_service.gd",
		"addons/novella/editor/timeline_editor_model.gd",
		"addons/novella/performance/on_demand_asset_loader.gd",
		"addons/novella/editor/ui/timeline_editor_panel.tscn",
		"addons/novella/editor/ui/timeline_editor_panel.gd",
		"addons/novella/release/compatibility_matrix.gd",
		"addons/novella/release/release_manifest.gd",
		"addons/novella/release/release_validator.gd",
		"addons/novella/presentation/ui/runtime_player.tscn",
		"addons/novella/presentation/ui/runtime_player.gd",
		"addons/novella/presentation/ui/runtime_stage.tscn",
		"addons/novella/presentation/ui/runtime_stage.gd",
		"addons/novella/script/script_migration.gd",
		"addons/novella/script/novella_vm.gd",
		"addons/novella/script/commands/basic_commands.gd",
		"addons/novella/script/commands/presentation_commands.gd",
		"addons/novella/script/commands/interaction_commands.gd",
		"addons/novella/script/commands/meta_commands.gd",
		"addons/novella/state/save_manager.gd",
		"addons/novella/state/settings_manager.gd",
		"addons/novella/state/ui/settings_panel.tscn",
		"addons/novella/state/ui/settings_panel_view.gd",
		"addons/novella/state/ui/save_load_panel.tscn",
		"addons/novella/state/ui/save_load_panel_view.gd",
		"docs/api.md",
		"docs/commands.md",
		"docs/compatibility.md",
		"docs/development.md",
		"docs/release.md",
		"docs/tutorial_zh.md",
		"docs/v1.0-alpha.md",
		"docs/v1.0-rc.1.md",
		"docs/v1.0-rc.2.md",
		"docs/v1.0-rc.3.md",
		"docs/v1.0-rc.4.md",
		"docs/v1.0-rc.5.md",
		"docs/v1.0-rc.6.md",
		"docs/v1.0.0.md",
		"docs/v1.0.1.md",
		"docs/v1.1.0.md",
		"docs/v1.2.0.md",
		"docs/v1.3.0.md",
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
version="1.3.0"
script="novella_editor_plugin.gd"
"""


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
