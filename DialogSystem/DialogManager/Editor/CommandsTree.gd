extends Tree

export var _flowchart_tab: NodePath
onready var root: TreeItem
onready var current_block_label: Label = $"../inspectorHeader/inspectorHeaderHBoxContainer/CurrentBlock"
onready var commands_settings: Panel = $"../../CommandsSettings"
onready var FlowChartTab: Control = get_node(_flowchart_tab)
var current_block: block

#Set up drag and droping, multiselect...


func _on_GraphNode_graph_node_meta(meta, title) -> void:
	commands_settings._currnet_title = title
	current_block = meta
	current_block_label.text = "current block: " + title
	self.clear()
	for i in meta.commands:
		_add_command(i)


func _on_add_command(id: int, pop_up: Popup) -> void:
	var _command: Command
	if current_block == null:
		return

	_command = pop_up.get_item_metadata(id)
	var _getter: Command = pop_up.get_item_metadata(id)
	_command = _getter.duplicate()  #Carful with the Conditional Command
	_add_command(_command)
	current_block.commands.append(_command)


func _add_command(command: Command) -> void:
	if get_root() == null:
		root = self.create_item()
		self.set_hide_root(true)

	var _item: TreeItem = self.create_item(root)
	_item.set_text(0, command.type)
	_item.set_meta("0", command)
	#set the new item as the selected one


func _on_CommandsTree_item_activated() -> void:
	if get_selected():
		if get_selected().get_meta("0") != null:
			if commands_settings.get_child_count() != 0:
				if commands_settings.get_child(0) != null:
					commands_settings.get_child(0).free()

			match get_selected().get_meta("0").type:
				"say":
					var say_control: Control = load("res://DialogManager/Editor/Commands/SayControl.tscn").instance()
					commands_settings.add_child(say_control, true)
					say_control.set_up(get_selected().get_meta("0"))

				"fork":
					var fork_control: Control = load("res://DialogManager/Editor/Commands/ForkControl.tscn").instance()
					commands_settings.add_child(fork_control, true)
					fork_control.set_up(get_selected().get_meta("0"),FlowChartTab.flowchart)

