@tool
extends Command
class_name SetVarCommand

@export var var_path: String
@export var var_name: String
@export var var_value: String


func preview() -> String:
	return str(var_path + "." + var_name + "= " + str(var_value))


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")


func get_class() -> String:
	return "SetVarCommand"


func is_class(c: String) -> bool:
	return c == "SetVarCommand"
