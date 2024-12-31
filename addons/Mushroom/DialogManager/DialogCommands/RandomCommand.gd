@tool
extends ContainerCommand
class_name RandomCommand

@export var container_block: Block
@export var collapse: bool


func _init() -> void:
	container_block = Block.new()


func preview() -> String:
	return "Random"


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/question.png")


func get_class() -> String:
	return "RandomCommand"


func is_class(c: String) -> bool:
	return c == "RandomCommand"
