tool
extends Command
class_name say_command

var type: String = "say"

export var name: String
export(String, MULTILINE) var say: String
export var portrait: Texture
export(String, "Left", "Right", "Center") var por_pos: String = "Right"

export var append_text: bool = false

export var is_cond: bool = false

export(String) var required_node
export var required_var: String
export var check_val: String
export(String) var condition_type


func preview() -> String:
	return String("Say: " + name + ": " + say)


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")
