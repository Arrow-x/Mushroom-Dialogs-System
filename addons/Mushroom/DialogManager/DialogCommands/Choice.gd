extends Resource
class_name Choice

@export var text: String
@export var next_block: String
@export var next_index: int = 0
@export var is_cond: bool = false
@export var conditionals: Array
@export var placeholder_args: Dictionary = {}


func get_class() -> String:
	return "Choice"


func is_class(c: String) -> bool:
	return c == "Choice"
