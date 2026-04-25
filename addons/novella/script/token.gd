extends RefCounted

class_name NovellaToken

enum Type {
	EOF,
	NEWLINE,
	INDENT,
	DEDENT,
	IDENTIFIER,
	KEYWORD,
	STRING,
	NUMBER,
	BOOL,
	COMMAND,
	SYMBOL,
	TEXT,
}

var type: Type
var lexeme: String
var literal: Variant
var line: int
var column: int

func _init(p_type: Type = Type.EOF, p_lexeme: String = "", p_literal: Variant = null, p_line: int = 0, p_column: int = 0) -> void:
	type = p_type
	lexeme = p_lexeme
	literal = p_literal
	line = p_line
	column = p_column


func _to_string() -> String:
	return "Token(%s, '%s', line=%s, column=%s)" % [Type.keys()[type], lexeme, line, column]
