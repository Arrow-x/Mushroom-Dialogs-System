tool
extends Command
class_name say_command

var type: String = "say"

export(Resource) var character: Resource
export(String, MULTILINE) var say: String
export var portrait_id: String
export var portrait: StreamTexture
export(String, "Left", "Right", "Center") var por_pos: String = "Right"

export var append_text: bool = false

export var is_cond: bool = false

export(String) var required_node
export var required_var: String
export var check_val: String
export(String) var condition_type = "=="


func preview() -> String:
	var prev: String = String("Say: " + say)
	if character != null:
		prev = String(prev + " by: " + character.name)

	return prev


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")
