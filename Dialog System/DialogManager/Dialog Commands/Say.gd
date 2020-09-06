extends Command
class_name say_command

var type : String = "say"

export var name : String
export (String, MULTILINE) var say 
export var portrait : Texture
export (String, "Set facing", "Left", "Right", "Center") var por_pos = "Right"

export var append_text : bool = false

