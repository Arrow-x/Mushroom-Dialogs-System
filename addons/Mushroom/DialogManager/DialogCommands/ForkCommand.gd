tool
extends Command
class_name ForkCommand

export var f_color: Color
export(Array, Resource) var choices
export var origin_block: String


func _init():
	f_color = Color(randf(), randf(), randf())


func preview():
	if choices.empty():
		return String("Fork")
	else:
		var choices_str: Array
		for c in choices:
			if c.next_block == null:
				choices_str.append("Empty")
				continue
			choices_str.append(c.next_block)
		return String("Fork to: " + String(choices_str))


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/fork_icon.png")


func get_class() -> String:
	return "ForkCommand"


func is_class(c: String) -> bool:
	return c == "ForkCommand"
