@tool
extends Resource
class_name ConditionResource

@export var required_node: String
@export var required_var: String
@export var check_val: String  # TODO: this so annoyung
@export var condition_type: String = "=="
@export var is_and: bool = true
@export var is_property: bool = true
@export var args: String


func get_class() -> String:
	return "ConditionResource"


func is_class(c: String) -> bool:
	return c == "ConditionResource"
