@tool
extends MenuButton

@export var commands_tree: Tree

var popup := get_popup()


func _ready():
	popup.id_pressed.connect(commands_tree._on_add_command.bind(popup))
	about_to_popup.connect(_on_about_to_popup)


func _on_about_to_popup() -> void:
	popup.clear()

	popup.add_item("Say", 0)
	popup.set_item_metadata(0, SayCommand.new())

	popup.add_item("Animation", 1)
	popup.set_item_metadata(1, AnimationCommand.new())

	popup.add_item("Fork", 2)
	popup.set_item_metadata(2, ForkCommand.new())

	popup.add_item("Conditional", 3)
	popup.set_item_metadata(3, ConditionCommand.new())

	popup.add_item("Else", 4)
	popup.set_item_metadata(4, ElseCommand.new())

	popup.add_item("Set Variable", 5)
	popup.set_item_metadata(5, SetVarCommand.new())

	popup.add_item("Play Sound", 6)
	popup.set_item_metadata(6, SoundCommand.new())

	popup.add_item("Change UI", 7)
	popup.set_item_metadata(7, ChangeUICommand.new())

	popup.add_item("Call Function", 8)
	popup.set_item_metadata(8, CallFunctionCommand.new())

	popup.add_item("Emit Signal", 9)
	popup.set_item_metadata(9, SignalCommand.new())

	popup.add_item("General Container", 10)
	popup.set_item_metadata(10, GeneralContainerCommand.new())

	popup.add_item("Jump", 11)
	popup.set_item_metadata(11, JumpCommand.new())
