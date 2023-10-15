tool
extends Command
class_name AnimationCommand

export(String) var animation_path
export(String) var animation_name
export var custom_blend: float = -1
export var custom_speed: float = 1.0
export var from_end: bool = false

export(String, "Set Animation Type", "wait", "continue") var anim_type


func preview() -> String:
	return String(
		(
			"Animate: "
			+ String(animation_path)
			+ "'s "
			+ String(animation_name)
			+ "with speed of "
			+ String(custom_speed)
			+ "blending at "
			+ String(custom_blend)
			+ "from end? "
			+ String(from_end)
		)
	)


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/fork_icon.png")


func get_class() -> String:
	return "AnimationCommand"


func is_class(c: String) -> bool:
	return c == "AnimationCommand"
