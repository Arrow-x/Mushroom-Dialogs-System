@tool
extends PopupMenu


func ready_commands():
	clear(true)
	var command: Command
	command = SayCommand.new()
	add_icon_item(command.get_icon(), "Say", item_count)
	set_item_metadata(item_count - 1, command)

	command = AnimationCommand.new()
	add_icon_item(command.get_icon(), "Animation", item_count)
	set_item_metadata(item_count - 1, command)

	command = ForkCommand.new()
	add_icon_item(command.get_icon(), "Fork", item_count)
	set_item_metadata(item_count - 1, command)

	command = ConditionCommand.new()
	add_icon_item(command.get_icon(), "If", item_count)
	set_item_metadata(item_count - 1, command)

	command = ElseCommand.new()
	add_icon_item(command.get_icon(), "Else", item_count)
	set_item_metadata(item_count - 1, command)

	command = IfElseCommand.new()
	add_icon_item(command.get_icon(), "If Else", item_count)
	set_item_metadata(item_count - 1, command)

	command = SoundCommand.new()
	add_icon_item(command.get_icon(), "Play Sound", item_count)
	set_item_metadata(item_count - 1, command)

	command = ChangeUICommand.new()
	add_icon_item(command.get_icon(), "Change UI", item_count)
	set_item_metadata(item_count - 1, command)

	command = CallFunctionCommand.new()
	add_icon_item(command.get_icon(), "Call Function", item_count)
	set_item_metadata(item_count - 1, command)

	command = SignalCommand.new()
	add_icon_item(command.get_icon(), "Emit Signal", item_count)
	set_item_metadata(item_count - 1, command)

	command = GeneralContainerCommand.new()
	add_icon_item(command.get_icon(), "General Container", item_count)
	set_item_metadata(item_count - 1, command)

	command = JumpCommand.new()
	add_icon_item(command.get_icon(), "Jump", item_count)
	set_item_metadata(item_count - 1, command)

	command = SetVarCommand.new()
	add_icon_item(command.get_icon(), "Set Variable", item_count)
	set_item_metadata(item_count - 1, command)

	command = RandomCommand.new()
	add_icon_item(command.get_icon(), "Random", item_count)
	set_item_metadata(item_count - 1, command)

	command = ShowMediaCommand.new()
	add_icon_item(command.get_icon(), "ShowMedia", item_count)
	set_item_metadata(item_count - 1, command)
