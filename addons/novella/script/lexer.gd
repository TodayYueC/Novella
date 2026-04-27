extends RefCounted

class_name NovellaLexer

const Token := preload("res://addons/novella/script/token.gd")

const KEYWORDS := {
	"label": true,
	"jump": true,
	"call": true,
	"return": true,
	"menu": true,
	"if": true,
	"elif": true,
	"else": true,
	"endif": true,
	"while": true,
	"endwhile": true,
	"break": true,
	"continue": true,
	"and": true,
	"or": true,
	"not": true,
}

var errors: Array[String] = []

func tokenize(source: String) -> Array:
	errors.clear()
	var tokens: Array = []
	var lines := source.replace("\r\n", "\n").replace("\r", "\n").split("\n", false)
	for line_index in range(lines.size()):
		_tokenize_line(lines[line_index], line_index + 1, tokens)
	tokens.append(Token.new(Token.Type.EOF, "", null, lines.size() + 1, 1))
	return tokens


func _tokenize_line(line_text: String, line_number: int, tokens: Array) -> void:
	var index := 0
	var column := 1
	while index < line_text.length():
		var ch := line_text[index]
		if ch == "#":
			break
		if ch == " " or ch == "\t":
			index += 1
			column += 1
			continue
		if ch == "\"":
			var result := _read_string(line_text, index, line_number, column)
			tokens.append(Token.new(Token.Type.STRING, result["lexeme"], result["literal"], line_number, column))
			column += str(result["lexeme"]).length()
			index = int(result["next_index"])
			continue
		if ch == "@":
			var start := index
			index += 1
			while index < line_text.length() and _is_identifier_part(line_text[index]):
				index += 1
			var lexeme := line_text.substr(start, index - start)
			tokens.append(Token.new(Token.Type.COMMAND, lexeme, lexeme.trim_prefix("@"), line_number, column))
			column += lexeme.length()
			continue
		if _is_digit(ch):
			var start := index
			while index < line_text.length() and (_is_digit(line_text[index]) or line_text[index] == "."):
				index += 1
			var number_text := line_text.substr(start, index - start)
			var literal: Variant = float(number_text) if number_text.contains(".") else int(number_text)
			tokens.append(Token.new(Token.Type.NUMBER, number_text, literal, line_number, column))
			column += number_text.length()
			continue
		if _is_identifier_start(ch):
			var start := index
			while index < line_text.length() and _is_identifier_part(line_text[index]):
				index += 1
			var word := line_text.substr(start, index - start)
			if word == "true" or word == "false":
				tokens.append(Token.new(Token.Type.BOOL, word, word == "true", line_number, column))
			elif KEYWORDS.has(word):
				tokens.append(Token.new(Token.Type.KEYWORD, word, word, line_number, column))
			else:
				tokens.append(Token.new(Token.Type.IDENTIFIER, word, word, line_number, column))
			column += word.length()
			continue
		tokens.append(Token.new(Token.Type.SYMBOL, ch, ch, line_number, column))
		index += 1
		column += 1
	tokens.append(Token.new(Token.Type.NEWLINE, "\n", null, line_number, max(column, 1)))


func _read_string(line_text: String, start_index: int, line_number: int, column: int) -> Dictionary:
	var index := start_index + 1
	var value := ""
	while index < line_text.length():
		var ch := line_text[index]
		if ch == "\\" and index + 1 < line_text.length():
			var next := line_text[index + 1]
			match next:
				"n":
					value += "\n"
				"t":
					value += "\t"
				_:
					value += next
			index += 2
			continue
		if ch == "\"":
			index += 1
			return {"lexeme": line_text.substr(start_index, index - start_index), "literal": value, "next_index": index}
		value += ch
		index += 1
	errors.append("Unterminated string at line %s column %s." % [line_number, column])
	return {"lexeme": line_text.substr(start_index), "literal": value, "next_index": line_text.length()}


func _is_digit(ch: String) -> bool:
	return ch >= "0" and ch <= "9"


func _is_identifier_start(ch: String) -> bool:
	return ch == "_" or ch.unicode_at(0) > 127 or (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z")


func _is_identifier_part(ch: String) -> bool:
	return _is_identifier_start(ch) or _is_digit(ch)
