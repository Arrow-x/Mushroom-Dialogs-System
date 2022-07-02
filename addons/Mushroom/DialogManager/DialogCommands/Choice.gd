extends Resource
class_name choice

export(String, MULTILINE) var text setget set_choice_text, get_choice_text

export var next_block: Resource
export var next_index: int = 0 setget set_choice_next_index, get_choice_next_index


func set_choice_text(new_text: String) -> void:
	text = new_text
	emit_signal("changed")


func get_choice_text() -> String:
	return text


func set_choice_next_index(new_idx: int) -> void:
	next_index = new_idx
	emit_signal("changed")


func get_choice_next_index() -> int:
	return text
