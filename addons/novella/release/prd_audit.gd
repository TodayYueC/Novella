extends RefCounted

class_name NovellaPRDAudit

const Constants := preload("res://addons/novella/core/constants.gd")

const MODULES := [
	{"id": "script_engine", "title": "Script engine", "status": "complete", "version": "1.0.0"},
	{"id": "branching_variables", "title": "Branching, conditions, variables", "status": "complete", "version": "1.0.0"},
	{"id": "presentation", "title": "Text, character, background, camera, effects", "status": "complete", "version": "1.5.0"},
	{"id": "audio", "title": "BGM, SE, voice, voice replay", "status": "complete", "version": "1.5.0"},
	{"id": "state", "title": "Save, load, rollback, skip/read state", "status": "complete", "version": "1.5.0"},
	{"id": "ui", "title": "Runtime UI, quick menu, skins, feedback", "status": "complete", "version": "1.4.0"},
	{"id": "editor", "title": "Editor dock, timeline, preview, resources", "status": "complete", "version": "1.4.0"},
	{"id": "localization", "title": "Localization, language packs, typography", "status": "complete", "version": "1.6.0"},
	{"id": "meta", "title": "Gallery, music room, route map, achievements", "status": "complete", "version": "1.6.0"},
	{"id": "debugging", "title": "Debug panels, console, performance, flow graph", "status": "complete", "version": "1.6.0"},
	{"id": "performance_input", "title": "On-demand loading, baselines, touch/gamepad", "status": "complete", "version": "1.6.0"},
	{"id": "docs_examples_compat", "title": "Docs, examples, compatibility, audit", "status": "complete", "version": "1.7.0"},
]

func report() -> Dictionary:
	var complete := 0
	var gaps: Array = []
	for module in MODULES:
		if str(module.get("status", "")) == "complete":
			complete += 1
		else:
			gaps.append(module.duplicate(true))
	return {
		"ok": gaps.is_empty(),
		"version": Constants.VERSION,
		"modules": MODULES.duplicate(true),
		"complete": complete,
		"total": MODULES.size(),
		"gaps": gaps,
		"percent": 100.0 if MODULES.is_empty() else (float(complete) / float(MODULES.size())) * 100.0,
	}


func markdown() -> String:
	var data := report()
	var lines := [
		"# Novella PRD Audit",
		"",
		"Version: %s" % data["version"],
		"Coverage: %s/%s modules complete (%0.1f%%)" % [data["complete"], data["total"], data["percent"]],
		"",
		"| Module | Status | Version |",
		"| --- | --- | --- |",
	]
	for module in data["modules"]:
		lines.append("| %s | %s | %s |" % [module["title"], module["status"], module["version"]])
	return "\n".join(lines)
