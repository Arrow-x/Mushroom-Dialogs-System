tool
extends Command
class_name SetVarCommand

export(String) var var_path: String
export(String) var var_name: String
export(String) var var_value


func preview() -> String:
	return String(var_path + "." + var_name + "= " + String(var_value))


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")


func get_class() -> String:
	return "SetVarCommand"


func is_class(c: String) -> bool:
	return c == "SetVarCommand"
