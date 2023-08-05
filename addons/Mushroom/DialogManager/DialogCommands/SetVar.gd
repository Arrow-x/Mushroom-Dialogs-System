tool
extends Command
class_name set_var_command

var type: String = "set_var"

export(String) var var_path: String
export(String) var var_name: String
export(String) var var_value


func preview() -> String:
	return String(var_path + "." + var_name + "= " + String(var_value))


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")
