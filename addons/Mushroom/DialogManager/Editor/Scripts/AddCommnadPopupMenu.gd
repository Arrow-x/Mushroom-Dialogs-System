tool
extends PopupMenu


func ready_commands():
	clear()

	add_item("Say", 0)
	set_item_metadata(0, say_command.new())

	add_item("Conditional Say ", 1)
	set_item_metadata(1, cond_say.new())

	add_item("Animation", 2)
	set_item_metadata(2, animation_command.new())

	add_item("Fork", 3)
	set_item_metadata(3, fork_command.new())

	add_item("Conditional", 4)
	set_item_metadata(4, condition_command.new())

	add_item("Jump", 5)
	set_item_metadata(5, jump_command.new())

	add_item("Set Variable", 6)
	set_item_metadata(6, set_var_command.new())

	add_item("Play Sound", 7)
	set_item_metadata(7, sound_command.new())

	add_item("Change UI", 8)
	set_item_metadata(8, change_ui.new())


func popit(button: Button) -> void:
	ready_commands()
	popup(
		Rect2(
			button.rect_global_position.x,
			button.rect_global_position.y + button.rect_size.y,
			rect_size.x,
			rect_size.y
		)
	)