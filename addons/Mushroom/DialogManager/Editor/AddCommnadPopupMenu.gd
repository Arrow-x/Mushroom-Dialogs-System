@tool
extends PopupMenu


func _ready() -> void:
	add_icon_item(
		SayCommand.get_icon(), "Say", item_count
	)

	add_icon_item(
		AnimationCommand.get_icon(),
		"Animation",
		item_count
	)

	add_icon_item(
		ForkCommand.get_icon(),
		"Fork",
		item_count
	)

	add_icon_item(
		ConditionCommand.get_icon(),
		"If",
		item_count
	)

	add_icon_item(
		ElseCommand.get_icon(),
		"Else",
		item_count
	)

	add_icon_item(
		IfElseCommand.get_icon(),
		"If Else",
		item_count
	)

	add_icon_item(
		SoundCommand.get_icon(),
		"Play Sound",
		item_count
	)

	add_icon_item(
		ChangeUICommand.get_icon(),
		"Change UI",
		item_count
	)

	add_icon_item(
		CallFunctionCommand.get_icon(),
		"Call Function",
		item_count
	)

	add_icon_item(
		SignalCommand.get_icon(),
		"Emit Signal",
		item_count
	)

	add_icon_item(
		GeneralContainerCommand.get_icon(),
		"General Container",
		item_count
	)

	add_icon_item(
		JumpCommand.get_icon(),
		"Jump",
		item_count
	)

	add_icon_item(
		SetVarCommand.get_icon(),
		"Set Variable",
		item_count
	)

	add_icon_item(
		RandomCommand.get_icon(),
		"Random",
		item_count
	)

	add_icon_item(
		ShowMediaCommand.get_icon(),
		"ShowMedia",
		item_count
	)
