@tool
extends ContainerCommand
class_name GeneralContainerCommand

@export var name: String = ""
@export var container_block: Block
@export var collapse: bool


func _init() -> void:
	container_block = Block.new()


func preview() -> String:
	return name


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/basket.png")


func get_class() -> String:
	return "GeneralContainerCommand"


func is_class(c: String) -> bool:
	return c == "GeneralContainerCommand"
