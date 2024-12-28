@tool
extends Command
class_name ForkCommand

@export var f_color: Color
@export var choices: Array
@export var origin_block_name: String


func _init():
	f_color = Color(randf(), randf(), randf())


func preview():
	if choices.is_empty():
		return "Fork"
	var choices_str: Array
	for c in choices:
		if c.next_block == null:
			choices_str.append("Empty")
			continue
		choices_str.append(c.next_block)
	return str("Fork to: " + str(choices_str))


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/fork_icon.png")


func get_class() -> String:
	return "ForkCommand"


func is_class(c: String) -> bool:
	return c == "ForkCommand"
