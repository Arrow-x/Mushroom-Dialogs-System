@tool
extends Command
class_name AnimationCommand

@export var animation_path: String = ""
@export var animation_name: String = ""
@export var custom_blend: float = -1
@export var custom_speed: float = 1.0
@export var from_end: bool = false
@export var is_wait: bool = true


func preview() -> String:
	return str(
		(
			"Animate: "
			+ str(animation_path)
			+ "'s "
			+ str(animation_name)
			+ " with speed of "
			+ str(custom_speed)
			+ " blending at "
			+ str(custom_blend)
			+ " from end? "
			+ str(from_end)
		)
	)


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/fork_icon.png")


func get_class() -> String:
	return "AnimationCommand"


func is_class(c: String) -> bool:
	return c == "AnimationCommand"
