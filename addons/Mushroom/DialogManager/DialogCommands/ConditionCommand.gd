@tool
extends Command
class_name ConditionCommand

@export var condition_block: Resource
@export var conditionals: Array[ConditionResource]


func _init():
	condition_block = Block.new()
	conditionals.append(ConditionResource.new())


func preview() -> String:
	# return str("if " + required_var + " " + condition_type + " " + check_val)
	return "if command"


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/condition_fork.png")


func get_class() -> String:
	return "ConditionCommand"


func is_class(c: String) -> bool:
	return c == "ConditionCommand"
