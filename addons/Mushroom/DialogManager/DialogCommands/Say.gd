tool
extends Command
class_name say_command

var type: String = "say"

export var name: String setget set_say_name, get_say_name
export(String, MULTILINE) var say: String setget set_say_text, get_say_text
export var portrait: Texture
export(String, "Left", "Right", "Center") var por_pos: String = "Right"

export var append_text: bool = false


func preview() -> String:
	return String("Say: " + name + ": " + say)


func set_say_name(new_name) -> void:
	name = new_name
	emit_signal("changed")


func get_say_name() -> String:
	return name


func set_say_text(new_say) -> void:
	say = new_say
	emit_signal("changed")


func get_say_text() -> String:
	return say