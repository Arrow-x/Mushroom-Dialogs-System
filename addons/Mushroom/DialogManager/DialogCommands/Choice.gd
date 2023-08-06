extends Resource
class_name choice

export(String, MULTILINE) var text setget set_choice_text

export var next_block: String setget set_next_block
export var next_index: int = 0 setget set_choice_next_index

export var is_cond: bool = false
export(String) var required_node
export var required_var: String
export var check_val: String
export(String) var condition_type = "=="


func set_next_block(next_text: String) -> void:
	next_block = next_text
	emit_changed()


func set_choice_text(new_text: String) -> void:
	text = new_text
	emit_changed()


func set_choice_next_index(new_idx: int) -> void:
	next_index = new_idx
	emit_changed()
