@tool
extends MenuButton

var popup := get_popup()


func _ready():
	popup.id_pressed.connect(get_node("../../../CommandsTree")._on_add_command.bind(popup))


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

	popup.add_item("Jump", 4)
	popup.set_item_metadata(4, JumpCommand.new())

	popup.add_item("Set Variable", 5)
	popup.set_item_metadata(5, SetVarCommand.new())

	popup.add_item("Play Sound", 6)
	popup.set_item_metadata(6, SoundCommand.new())

	popup.add_item("Change UI", 7)
	popup.set_item_metadata(7, ChangeUICommand.new())
