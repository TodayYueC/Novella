extends RefCounted

class_name NovellaTypewriterEffect

const DEFAULT_PUNCTUATION_DELAYS := {
	".": 0.18,
	",": 0.08,
	";": 0.12,
	":": 0.12,
	"!": 0.2,
	"?": 0.2,
	"。": 0.18,
	"，": 0.08,
	"；": 0.12,
	"：": 0.12,
	"！": 0.2,
	"？": 0.2,
	"…": 0.22,
}

var cps: float = 35.0
var punctuation_delays: Dictionary = DEFAULT_PUNCTUATION_DELAYS.duplicate()
var elapsed: float = 0.0
var source_text: String = ""
var visible_characters: int = 0
var finished: bool = true

func start(text: String, p_cps: float = 35.0) -> void:
	source_text = text
	cps = max(p_cps, 1.0)
	elapsed = 0.0
	visible_characters = 0
	finished = source_text.is_empty()


func advance(delta: float) -> int:
	if finished:
		return visible_characters
	elapsed += max(delta, 0.0)
	while visible_characters < source_text.length():
		var delay := _delay_for_char(source_text[visible_characters])
		if elapsed < delay:
			break
		elapsed -= delay
		visible_characters += 1
	if visible_characters >= source_text.length():
		finished = true
	return visible_characters


func reveal_all() -> void:
	visible_characters = source_text.length()
	finished = true


func get_visible_text() -> String:
	return source_text.substr(0, visible_characters)


func estimate_duration(text: String, p_cps: float = 35.0) -> float:
	var duration := 0.0
	var speed := max(p_cps, 1.0)
	for i in range(text.length()):
		duration += (1.0 / speed) + float(punctuation_delays.get(text[i], 0.0))
	return duration


func _delay_for_char(character: String) -> float:
	return (1.0 / cps) + float(punctuation_delays.get(character, 0.0))
