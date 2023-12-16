@tool
extends ContainerCommand
class_name GeneralContainerCommand

@export var name: String = ""
@export var container_block: Block


func _init() -> void:
	container_block = Block.new()


func preview() -> String:
	return name


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")


func get_class() -> String:
	return "GeneralContainerCommand"


func is_class(c: String) -> bool:
	return c == "GeneralContainerCommand"
