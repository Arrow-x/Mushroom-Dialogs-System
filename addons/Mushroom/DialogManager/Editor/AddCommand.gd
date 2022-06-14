tool
extends MenuButton

var pop_up: Popup


func _ready():
	connect("about_to_show", self, "ready_commands")
	pop_up = get_popup()
	pop_up.connect("id_pressed", get_node("../../../CommandsTree"), "_on_add_command", [pop_up])


func ready_commands():
	pop_up.clear()

	pop_up.add_item("Say", 0)
	pop_up.set_item_metadata(0, say_command.new())

	pop_up.add_item("Conditional Say ", 1)
	pop_up.set_item_metadata(1, cond_say.new())

	pop_up.add_item("Animation", 2)
	pop_up.set_item_metadata(2, animation_command.new())

	pop_up.add_item("Fork", 3)
	pop_up.set_item_metadata(3, fork_command.new())

	pop_up.add_item("Conditional", 4)
	pop_up.set_item_metadata(4, condition_command.new())

	pop_up.add_item("Jump", 5)
	pop_up.set_item_metadata(5, jump_command.new())

	pop_up.add_item("Set Variable", 6)
	pop_up.set_item_metadata(6, set_var_command.new())

	pop_up.add_item("Play Sound", 7)
	pop_up.set_item_metadata(7, sound_command.new())

	pop_up.add_item("Change UI", 8)
	pop_up.set_item_metadata(8, change_ui.new())
