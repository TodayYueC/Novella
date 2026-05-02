extends "res://addons/novella/core/novella_resource.gd"

class_name NovellaUISkinResource

@export var styles: Dictionary = {
	"root": {
		"font_color": "#f8fafc",
		"panel_color": "#111827dd",
		"accent_color": "#38bdf8",
		"padding": [16, 12, 16, 12],
	},
	"adv_box": {
		"panel_color": "#111827ee",
		"name_color": "#facc15",
		"text_color": "#f8fafc",
	},
	"choice_menu": {
		"panel_color": "#0f172add",
		"selected_color": "#38bdf8",
		"disabled_color": "#64748b",
	},
	"quick_menu": {
		"button_color": "#1f2937",
		"hover_color": "#334155",
		"confirm_color": "#f97316",
	},
	"toast": {
		"info_color": "#38bdf8",
		"success_color": "#22c55e",
		"warning_color": "#f59e0b",
		"error_color": "#ef4444",
	},
	"confirm_dialog": {
		"panel_color": "#111827f2",
		"accept_color": "#22c55e",
		"cancel_color": "#94a3b8",
	},
}

func style_for(role: StringName, overrides: Dictionary = {}) -> Dictionary:
	var result: Dictionary = styles.get("root", {}).duplicate(true)
	var role_style: Dictionary = styles.get(String(role), {}).duplicate(true)
	for key in role_style:
		result[key] = role_style[key]
	for key in overrides:
		result[key] = overrides[key]
	return result


func merge_style(role: StringName, patch: Dictionary) -> Dictionary:
	var key := String(role)
	if not styles.has(key):
		styles[key] = {}
	for patch_key in patch:
		styles[key][patch_key] = patch[patch_key]
	return style_for(role)


func apply_to_control(control: Control, role: StringName, overrides: Dictionary = {}) -> Dictionary:
	if control == null:
		return {"ok": false, "error": "Control is null."}
	var style := style_for(role, overrides)
	if style.has("font_color"):
		control.add_theme_color_override("font_color", _color(style["font_color"]))
	if style.has("text_color"):
		control.add_theme_color_override("font_color", _color(style["text_color"]))
	if style.has("panel_color"):
		var box := StyleBoxFlat.new()
		box.bg_color = _color(style["panel_color"])
		var padding: Array = style.get("padding", [])
		if padding.size() >= 4:
			box.content_margin_left = float(padding[0])
			box.content_margin_top = float(padding[1])
			box.content_margin_right = float(padding[2])
			box.content_margin_bottom = float(padding[3])
		control.add_theme_stylebox_override("panel", box)
	return {"ok": true, "role": String(role), "style": style}


func to_dict() -> Dictionary:
	var data := super.to_dict()
	data["styles"] = styles.duplicate(true)
	return data


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	styles = data.get("styles", styles).duplicate(true)


func _color(value: Variant) -> Color:
	if value is Color:
		return value
	return Color.html(str(value))
