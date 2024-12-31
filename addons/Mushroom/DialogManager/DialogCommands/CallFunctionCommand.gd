@tool
extends Command
class_name CallFunctionCommand

@export var req_node: String = ""
@export var func_name: String = ""
@export var args: String = ""
@export var parsed_args: Array


func preview() -> String:
	return str(req_node + "." + func_name + "(" + args + ")")


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/gear.png")


func get_class() -> String:
	return "CallFunctionCommand"


func is_class(c: String) -> bool:
	return c == "CallFunctionCommand"
