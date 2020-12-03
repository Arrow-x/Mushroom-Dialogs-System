extends Command
class_name say_command

var type : String = "say"

export var name : String
export (String, MULTILINE) var say : String
export var portrait : Texture
export (String, "Left", "Right", "Center") var por_pos : String = "Right"

export var append_text : bool = false
