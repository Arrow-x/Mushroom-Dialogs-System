@tool
extends Button

@onready var pop_up: Popup = $AddCommandPopupMenu


func _ready():
	pressed.connect(pop_up.popit.bind(self))
	pop_up.id_pressed.connect(get_node("../../../CommandsTree")._on_add_command.bind(pop_up))
