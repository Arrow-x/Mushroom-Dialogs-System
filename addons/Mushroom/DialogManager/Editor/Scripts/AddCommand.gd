tool
extends Button

var pop_up: Popup


func _ready():
	pop_up = get_node("AddCommandPopupMenu")
	connect("pressed", pop_up, "popit", [self])
	pop_up.connect("id_pressed", get_node("../../../CommandsTree"), "_on_add_command", [pop_up])
