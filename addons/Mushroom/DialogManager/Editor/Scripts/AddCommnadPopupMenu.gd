@tool
extends PopupMenu


func ready_commands():
	clear()

	add_item("Say", 0)
	set_item_metadata(0, SayCommand.new())

	add_item("Animation", 1)
	set_item_metadata(1, AnimationCommand.new())

	add_item("Fork", 2)
	set_item_metadata(2, ForkCommand.new())

	add_item("Conditional", 3)
	set_item_metadata(3, ConditionCommand.new())

	add_item("Jump", 4)
	set_item_metadata(4, JumpCommand.new())

	add_item("Set Variable", 5)
	set_item_metadata(5, SetVarCommand.new())

	add_item("Play Sound", 6)
	set_item_metadata(6, SoundCommand.new())

	add_item("Change UI", 7)
	set_item_metadata(7, ChangeUICommand.new())


func popit(button: Button) -> void:
	ready_commands()
	popup(Rect2(button.global_position.x, button.global_position.y + button.size.y, size.x, size.y))
