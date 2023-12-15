@tool
extends Command
class_name ConditionCommand

@export var condition_block: Resource
@export var conditionals: Array[ConditionResource]


func _init():
	condition_block = Block.new()
	conditionals.append(ConditionResource.new())


func preview() -> String:
	var ret := "if: "
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
	return load("res://addons/Mushroom/DialogManager/Editor/icons/condition_fork.png")


func get_class() -> String:
	return "ConditionCommand"


func is_class(c: String) -> bool:
	return c == "ConditionCommand"
