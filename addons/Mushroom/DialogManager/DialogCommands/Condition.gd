tool
extends Command
class_name condition_command

var type: String = "condition"

export var condition_block: Resource

export(String) var required_node
export var required_var: String
export(String) var check_val
export(String) var condition_type = "=="


func _init():
	condition_block = block.new()


func preview() -> String:
	return String("if " + required_var + " " + condition_type + " " + check_val)


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/condition_fork.png")
