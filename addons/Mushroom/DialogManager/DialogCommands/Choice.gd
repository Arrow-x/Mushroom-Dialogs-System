extends Resource
class_name Choice

@export var text : String: set = set_choice_text

@export var next_block: String: set = set_next_block
@export var next_index: int = 0: set = set_choice_next_index

@export var is_cond: bool = false
@export var required_node: String
@export var required_var: String
@export var check_val: String
@export var condition_type: String = "=="


func set_next_block(next_text: String) -> void:
	next_block = next_text
	emit_changed()


func set_choice_text(new_text: String) -> void:
	text = new_text
	emit_changed()


func set_choice_next_index(new_idx: int) -> void:
	next_index = new_idx
	emit_changed()


func get_class() -> String:
	return "Choice"


func is_class(c: String) -> bool:
	return c == "Choice"
