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


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/share1.png")


func get_class() -> String:
	return "JumpCommand"


func is_class(c: String) -> bool:
	return c == "JumpCommand"
