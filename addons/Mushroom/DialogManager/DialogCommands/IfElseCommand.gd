@tool
extends IfCommand
class_name IfElseCommand

@export var conditionals: Array
@export var container_block: Block
@export var collapse: bool


func _init() -> void:
	container_block = Block.new()


func preview() -> String:
	var ret := "elif: "
	for c in range(conditionals.size()):
		if c != 0:
			if conditionals[c].is_and == true:
				ret = ret + " and if: "
			else:
				ret = ret + " or if: "
		ret = ret + conditionals[c].required_var + " "
		ret = ret + conditionals[c].condition_type + " "
		ret = ret + conditionals[c].check_val

	return ret


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/conditional_icon.png")


func get_class() -> String:
	return "IfElseCommand"


func is_class(c: String) -> bool:
	return c == "IfElseCommand"
