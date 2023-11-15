@tool
extends PopupMenu

# This is a general menut that I will add stuffto it
func set_up() -> void:
	clear()
	add_submenu_item("adding", "AddCommandRmbPopupMenu", -1)
	$AddCommandRmbPopupMenu.ready_commands()
