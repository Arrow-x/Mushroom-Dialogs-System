tool
extends Command
class_name fork_command

var type: String = "fork"
export var f_color: Color
export(Array, Resource) var choices


func _init():
	f_color = Color(randf(), randf(), randf())


func preview():
	if choices.empty():
		return String("Fork")
	else:
		var choices_str: Array
		for c in choices:
			choices_str.append(c.next_block.name)
		return String("Fork to: " + String(choices_str))
