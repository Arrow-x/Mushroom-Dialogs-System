@tool
extends Resource
class_name ConditionResource

@export var required_node: String
@export var required_var: String
@export var check_val: String  # TODO: this so annoyung
@export var condition_type: String = "=="
@export var is_and: bool = true
