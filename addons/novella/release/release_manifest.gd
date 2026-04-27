extends RefCounted

class_name NovellaReleaseManifest

const Constants := preload("res://addons/novella/core/constants.gd")

const ADDON_ROOT := "addons/novella"
const REPOSITORY := "https://github.com/TodayYueC/Novella"
const LICENSE := "MIT"
const RELEASE_CHANNEL := "alpha"

const REQUIRED_FILES := [
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

const REQUIRED_DIRECTORIES := [
	"addons/novella/core",
	"addons/novella/script",
	"addons/novella/presentation",
	"addons/novella/interaction",
	"addons/novella/editor",
	"addons/novella/meta",
	"addons/novella/release",
	"docs",
	"examples",
	"scripts",
	"tests",
]

const PACKAGE_ROOTS := [
	"addons/novella",
	"docs",
	"examples",
	"scripts",
	"README.md",
	"LICENSE",
	"project.godot",
]

const FORBIDDEN_PATH_MARKERS := [
	"GodotEngine/",
	".godot/",
	".godot_user/",
	"export_templates/",
	"templates/",
	"build/",
	"dist/",
	"exports/",
	".mono/",
	".vs/",
	"Novella_",
	"需求文档",
	"进度文档",
]

const FORBIDDEN_EXTENSIONS := [
	".exe",
	".dll",
	".dylib",
	".so",
	".pck",
	".apk",
	".aab",
	".ipa",
	".zip",
	".log",
	".tmp",
]

func to_dict() -> Dictionary:
	return {
		"name": "Novella",
		"version": Constants.VERSION,
		"release_channel": RELEASE_CHANNEL,
		"repository": REPOSITORY,
		"license": LICENSE,
		"addon_root": ADDON_ROOT,
		"godot": {
			"minimum": "%s.%s" % [Constants.MIN_GODOT_MAJOR, Constants.MIN_GODOT_MINOR],
			"primary": "%s.%s" % [Constants.PRIMARY_GODOT_MAJOR, Constants.PRIMARY_GODOT_MINOR],
		},
		"required_files": REQUIRED_FILES.duplicate(),
		"required_directories": REQUIRED_DIRECTORIES.duplicate(),
		"package_roots": PACKAGE_ROOTS.duplicate(),
		"forbidden_path_markers": FORBIDDEN_PATH_MARKERS.duplicate(),
		"forbidden_extensions": FORBIDDEN_EXTENSIONS.duplicate(),
	}


func package_name(version: String = Constants.VERSION) -> String:
	return "novella-%s.zip" % version


func should_package_path(path: String) -> bool:
	var normalized := _normalize_path(path)
	if _is_forbidden_path(normalized):
		return false
	for root in PACKAGE_ROOTS:
		var normalized_root := _normalize_path(root)
		if normalized == normalized_root or normalized.begins_with("%s/" % normalized_root):
			return true
	return false


func _is_forbidden_path(path: String) -> bool:
	for marker in FORBIDDEN_PATH_MARKERS:
		if path.contains(marker):
			return true
	for extension in FORBIDDEN_EXTENSIONS:
		if path.to_lower().ends_with(extension):
			return true
	return false


func _normalize_path(path: String) -> String:
	return path.replace("\\", "/").trim_prefix("./").strip_edges()
