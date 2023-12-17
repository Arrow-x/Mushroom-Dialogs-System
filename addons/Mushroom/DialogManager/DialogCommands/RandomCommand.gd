@tool
extends ContainerCommand
class_name RandomCommand

@export var container_block: Block


func _init() -> void:
	container_block = Block.new()


func preview() -> String:
	return "Random"


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/condition_fork.png")


func get_class() -> String:
	return "RandomCommand"


func is_class(c: String) -> bool:
	return c == "RandomCommand"
