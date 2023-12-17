@tool
extends Button

@export var commands_tree: Tree
@export var i_rmb_add_menu: PackedScene
var popup: PopupMenu


func _ready():
	popup = i_rmb_add_menu.instantiate()
	add_child(popup)
	popup.index_pressed.connect(func(idx: int) -> void: commands_tree._on_add_command(idx, popup))
	self.pressed.connect(popit)


func popit():
	popup.ready_commands()
	popup.popup_on_parent(Rect2i(global_position.x, global_position.y + size.y, size.x, size.y))
