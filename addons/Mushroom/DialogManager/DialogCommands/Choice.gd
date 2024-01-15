@tool
class_name Choice extends Resource

@export var next_block: String
@export var next_index: int = 0
@export var is_cond: bool = false
@export var conditionals: Array
@export var placeholder_args: Dictionary = {}
@export var tr_code: StringName

var choice_text: String


func get_class() -> String:
	return "Choice"


func is_class(c: String) -> bool:
	return c == "Choice"
