@tool
extends PopupMenu


func _ready() -> void:
	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png"), "Say", item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"Animation",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/fork_icon.png"),
		"Fork",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/conditional_icon.png"),
		"If",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/conditional_icon.png"),
		"Else",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/conditional_icon.png"),
		"If Else",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"Play Sound",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"Change UI",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"Call Function",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"Emit Signal",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/general_container_icon.png"),
		"General Container",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"Jump",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"Set Variable",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"Random",
		item_count
	)

	add_icon_item(
		preload("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png"),
		"ShowMedia",
		item_count
	)
