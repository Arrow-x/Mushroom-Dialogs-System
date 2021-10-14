extends Command
class_name animation_command
#this is a path to the animatiomnPlayer Node
var type := "animation"

export(String) var animation_path
export(String) var animation_name
export var custom_blend: float = -1
export var custom_speed: float = 1.0
export var from_end: bool = false

export(String, "Set Animation Type", "wait", "continue") var anim_type
