@tool
extends Command
class_name SayCommand

@export var character: Resource
@export_multiline var say: String
@export var portrait_id: String
@export var portrait: CompressedTexture2D
@export_enum("Left", "Right", "Center") var por_pos: String = "Right"
@export var append_text: bool = false
@export var is_cond: bool = false
@export var conditionals: Array[ConditionResource]
@export var follow_through: bool = false
@export var placeholder_args: Dictionary = {}


func preview() -> String:
	var prev: String
	prev = str("Say: " + say)
	if character != null:
		prev = str(prev + " by: " + character.name)
	return prev


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")


func get_class() -> String:
	return "SayCommand"


func is_class(c: String) -> bool:
	return c == "SayCommand"
