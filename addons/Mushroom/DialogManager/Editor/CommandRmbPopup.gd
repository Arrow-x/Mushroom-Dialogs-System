@tool
extends PopupMenu

@export var i_rmb_add_menu: PackedScene

signal add_index_pressed(idx: int, on_item: bool)


func set_up(paste: bool, on_item: bool) -> void:
	clear(true)
	var rmb_menu: PopupMenu = i_rmb_add_menu.instantiate()
	rmb_menu.name = "RMBAddCommandMenu"
	add_child(rmb_menu)
	add_submenu_item("Add", "RMBAddCommandMenu")
	rmb_menu.index_pressed.connect(func(idx: int) -> void: add_index_pressed.emit(idx, on_item))
	if on_item == true:
		add_item("Copy")
		add_item("Cut")
	if paste == true:
		add_item("Paste")
	if on_item == true:
		add_item("Delete")
