@tool
extends Command
class_name SetVarCommand

@export var var_path: String
@export var var_name: String
@export var var_value: String
@export var parsed_var_value: Array


func preview() -> String:
	return str(var_path + "." + var_name + "= " + str(var_value))


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/wrench.png")


func get_class() -> String:
	return "SetVarCommand"


func is_class(c: String) -> bool:
	return c == "SetVarCommand"
