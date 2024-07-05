@tool
extends Button

@export var commands_tree: Tree
@export var i_rmb_add_menu: PackedScene
var popup: PopupMenu


func _ready():
	popup = i_rmb_add_menu.instantiate()
	add_child(popup)
	popup.index_pressed.connect(commands_tree._on_add_command)
	self.pressed.connect(popit)


func popit():
	if commands_tree.current_block == null:
		push_error("CommandsTree: there is no block selected")
		return
	popup.popup_on_parent(Rect2i(global_position.x, global_position.y + size.y, size.x, size.y))
