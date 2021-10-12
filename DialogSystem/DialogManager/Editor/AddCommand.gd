extends MenuButton

var pop_up: Popup


func _ready():
	pop_up = get_popup()

	pop_up.add_item("Say Conmmand", 0)
	pop_up.set_item_metadata(0, say_command.new())

	pop_up.add_item("Conditional Say Conmmand", 1)
	pop_up.set_item_metadata(1, cond_say.new())

	pop_up.add_item("Animation Command", 2)
	pop_up.set_item_metadata(2, animation_command.new())

	pop_up.add_item("Fork Command", 3)
	pop_up.set_item_metadata(3, fork_command.new())

	pop_up.add_item("Conditional Conmmand", 4)
	pop_up.set_item_metadata(4, condition_command.new())

	pop_up.add_item("Jump Conmmand", 5)
	pop_up.set_item_metadata(5, jump_command.new())

	pop_up.add_item("Set Variable Conmmand", 6)
	pop_up.set_item_metadata(6, set_var_command.new())

	pop_up.add_item("Sound Conmmand", 7)
	pop_up.set_item_metadata(7, sound_command.new())

	pop_up.add_item("Change UI Conmmand", 8)
	pop_up.set_item_metadata(8, change_ui.new())

	pop_up.connect("id_pressed", get_node("../../../CommandsTree"), "_on_add_command", [pop_up])
