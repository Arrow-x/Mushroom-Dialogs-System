@tool
extends Command
class_name ConditionCommand

@export var condition_block: Resource

@export var required_node: String
@export var required_var: String
@export var check_val: String
@export var condition_type: String = "=="


func _init():
	condition_block = Block.new()


func preview() -> String:
	return str("if " + required_var + " " + condition_type + " " + check_val)


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/condition_fork.png")


func get_class() -> String:
	return "ConditionCommand"


func is_class(c: String) -> bool:
	return c == "ConditionCommand"
