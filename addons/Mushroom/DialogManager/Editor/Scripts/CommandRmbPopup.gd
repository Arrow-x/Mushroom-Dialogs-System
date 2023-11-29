@tool
extends PopupMenu

@export var i_rmb_add_menu: PackedScene

signal add_index_pressed(idx, menu)


func set_up() -> void:
	clear(true)
	var rmb_menu: PopupMenu = i_rmb_add_menu.instantiate()
	rmb_menu.name = "RMBAddCommandMenu"
	add_child(rmb_menu)
	add_submenu_item("add", "RMBAddCommandMenu")
	rmb_menu.index_pressed.connect(func(idx: int) -> void: add_index_pressed.emit(idx, rmb_menu))
	rmb_menu.ready_commands()
	add_item("delete")
