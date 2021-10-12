extends Command
class_name cond_say

var type: String = "cond_say"

export var name: String
export(String, MULTILINE) var say
export var portrait: Texture
export(String, "Set facing", "Left", "Right", "Center") var por_pos = "Right"

export var append_text: bool = false

export(String) var required_node
export var required_var: String
export var check_val: int
export(String) var condition_type
