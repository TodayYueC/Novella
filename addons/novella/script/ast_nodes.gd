extends RefCounted

class_name NovellaAst

class AstNode:
	extends RefCounted
	var kind: StringName
	var line: int
	var children: Array = []

	func _init(p_kind: StringName = &"node", p_line: int = 0) -> void:
		kind = p_kind
		line = p_line

	func to_dict() -> Dictionary:
		var child_data: Array = []
		for child in children:
			child_data.append(child.to_dict())
		return {
			"kind": String(kind),
			"line": line,
			"children": child_data,
		}


class ScriptNode:
	extends AstNode
	var file_path: String = ""
	var labels: Dictionary = {}

	func _init(p_file_path: String = "") -> void:
		super(&"script", 1)
		file_path = p_file_path

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		data["file_path"] = file_path
		data["labels"] = labels.duplicate()
		return data


class DialogueNode:
	extends AstNode
	var speaker: String = ""
	var text: String = ""
	var inline_commands: Array = []

	func _init(p_speaker: String = "", p_text: String = "", p_line: int = 0) -> void:
		super(&"dialogue", p_line)
		speaker = p_speaker
		text = p_text

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		data.merge({"speaker": speaker, "text": text, "inline_commands": inline_commands.duplicate(true)}, true)
		return data


class NarrationNode:
	extends AstNode
	var text: String = ""

	func _init(p_text: String = "", p_line: int = 0) -> void:
		super(&"narration", p_line)
		text = p_text

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		data["text"] = text
		return data


class CommandNode:
	extends AstNode
	var command_name: StringName = &""
	var raw_arguments: String = ""

	func _init(p_command_name: StringName = &"", p_raw_arguments: String = "", p_line: int = 0) -> void:
		super(&"command", p_line)
		command_name = p_command_name
		raw_arguments = p_raw_arguments

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		data.merge({"command_name": String(command_name), "raw_arguments": raw_arguments}, true)
		return data


class LabelNode:
	extends AstNode
	var label_name: StringName = &""

	func _init(p_label_name: StringName = &"", p_line: int = 0) -> void:
		super(&"label", p_line)
		label_name = p_label_name

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		data["label_name"] = String(label_name)
		return data


class JumpNode:
	extends AstNode
	var target_label: StringName = &""

	func _init(p_target_label: StringName = &"", p_line: int = 0) -> void:
		super(&"jump", p_line)
		target_label = p_target_label

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		data["target_label"] = String(target_label)
		return data


class CallNode:
	extends AstNode
	var target_label: StringName = &""
	var arguments: Dictionary = {}

	func _init(p_target_label: StringName = &"", p_arguments: Dictionary = {}, p_line: int = 0) -> void:
		super(&"call", p_line)
		target_label = p_target_label
		arguments = p_arguments.duplicate(true)

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		data.merge({"target_label": String(target_label), "arguments": arguments.duplicate(true)}, true)
		return data


class ReturnNode:
	extends AstNode

	func _init(p_line: int = 0) -> void:
		super(&"return", p_line)


class ChoiceNode:
	extends AstNode
	var text: String = ""
	var condition: String = ""
	var actions: Array = []

	func _init(p_text: String = "", p_condition: String = "", p_actions: Array = [], p_line: int = 0) -> void:
		super(&"choice", p_line)
		text = p_text
		condition = p_condition
		actions = p_actions.duplicate()

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		var action_data: Array = []
		for action in actions:
			action_data.append(action.to_dict())
		data.merge({"text": text, "condition": condition, "actions": action_data}, true)
		return data


class MenuNode:
	extends AstNode
	var choices: Array = []

	func _init(p_choices: Array = [], p_line: int = 0) -> void:
		super(&"menu", p_line)
		choices = p_choices.duplicate()

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		var choice_data: Array = []
		for choice in choices:
			choice_data.append(choice.to_dict())
		data["choices"] = choice_data
		return data


class IfNode:
	extends AstNode
	var branches: Array = []

	func _init(p_line: int = 0) -> void:
		super(&"if", p_line)

	func add_branch(condition: String, actions: Array, branch_line: int) -> void:
		branches.append({
			"condition": condition,
			"actions": actions,
			"line": branch_line,
		})

	func to_dict() -> Dictionary:
		var data := super.to_dict()
		var branch_data: Array = []
		for branch in branches:
			var action_data: Array = []
			for action in branch["actions"]:
				action_data.append(action.to_dict())
			branch_data.append({
				"condition": branch["condition"],
				"actions": action_data,
				"line": branch["line"],
			})
		data["branches"] = branch_data
		return data
