@tool
extends Command
class_name JumpCommand

@export var jump_block: Resource
@export var jump_index: int = 0
@export var global: bool = false


func get_block_name() -> String:
	if jump_block == null:
		return "null"
	else:
		return jump_block.name


func preview() -> String:
	if global:
		return str("Jump to: " + get_block_name() + " at: " + str(jump_index))
	else:
		return str("Jump local index: " + str(jump_index))


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/fork_icon.png")


func get_class() -> String:
	return "JumpCommand"


func is_class(c: String) -> bool:
	return c == "JumpCommand"
