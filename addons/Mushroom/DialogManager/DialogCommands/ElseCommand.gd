@tool
extends ContainerCommand
class_name ElseCommand

@export var container_block: Block
@export var collapse: bool


func _init() -> void:
	container_block = Block.new()


func preview() -> String:
	return "Else"


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/condition_fork.png")


func get_class() -> String:
	return "ElseCommand"


func is_class(c: String) -> bool:
	return c == "ElseCommand"
