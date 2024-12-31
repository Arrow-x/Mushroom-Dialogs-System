@tool
extends Command
class_name SignalCommand

@export var req_node: String = ""
@export var signal_name: String = ""
@export var signal_args: String = ""
@export var singal_args_parsed: Array


func preview() -> String:
	return str("Emit: " + req_node + "." + signal_name + "(" + signal_args + ")")


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/signal3.png")


func get_class() -> String:
	return "SignalCommand"


func is_class(c: String) -> bool:
	return c == "SignalCommand"
