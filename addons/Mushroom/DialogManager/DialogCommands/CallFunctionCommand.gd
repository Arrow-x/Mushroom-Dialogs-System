@tool
extends Command
class_name CallFunctionCommand

@export var req_node: String = ""
@export var func_name: String = ""
@export var args: String = ""
@export var parsed_args: Array


func preview() -> String:
	return str(req_node + "." + func_name + "(" + args + ")")


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")


func get_class() -> String:
	return "CallFunctionCommand"


func is_class(c: String) -> bool:
	return c == "CallFunctionCommand"
