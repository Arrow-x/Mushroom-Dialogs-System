extends Tree

export var _flowchart_tab: NodePath
onready var root: TreeItem
onready var current_block_label: Label = $"../inspectorHeader/inspectorHeaderHBoxContainer/CurrentBlock"
onready var commands_settings: Panel = $"../../CommandsSettings"
onready var FlowChartTab: Control = get_node(_flowchart_tab)
var current_block: block
var current_command: Command
var current_command_control: Control

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


func _on_CommandsTree_item_activated() -> void:
	if get_selected():
		if get_selected().get_meta("0") != null:
			if commands_settings.get_child_count() != 0:
				if commands_settings.get_child(0) != null:
					commands_settings.get_child(0).free()

			current_command = null
			current_command_control = null
			match get_selected().get_meta("0").type:
				"say":
					var say_control: Control = load("res://DialogManager/Editor/Commands/SayControl.tscn").instance()
					commands_settings.add_child(say_control, true)
					say_control.set_up(get_selected().get_meta("0"))

				"fork":
					var fork_control: Control = load("res://DialogManager/Editor/Commands/ForkControl.tscn").instance()
					current_command_control = fork_control
					commands_settings.add_child(fork_control, true)
					current_command = get_selected().get_meta("0")

					fork_control.add_choice_button.connect("pressed", self, "_add_choice", [0])

					_add_choice(current_command.choices)


func _add_choice(_new_choice) -> void:
	if _new_choice is int and _new_choice == 0:
		_new_choice = []
		var c_c: choice = choice.new()
		_new_choice.append(c_c)
		current_command.choices.append(c_c)

	if _new_choice.size() == 0:
		return

	for i in _new_choice.size():
		var _new_choice_control: Control = load("res://DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
		_new_choice_control.set_meta("command", _new_choice[i])

		current_command_control.choices_container.add_child(_new_choice_control)

		_new_choice_control.next_block_menu.connect(
			"about_to_show", self, "_fill_menu", [_new_choice_control.next_block_menu.get_popup()]
		)
		_new_choice_control.choice_text.connect(
			"text_changed",
			self,
			"_change_command_property",
			[_new_choice_control.get_meta("command"), "text"]
		)
		_new_choice_control.next_index_text.connect(
			"value_changed",
			self,
			"_change_command_property",
			[_new_choice_control.get_meta("command"), "next_index"]
		)
		_new_choice_control.next_block_menu.get_popup().connect(
			"index_pressed",
			self,
			"_change_next_block",
			[
				_new_choice_control.get_meta("command"),
				_new_choice_control.next_block_menu.get_popup(),
				_new_choice_control
			]
		)
		if _new_choice[i].next_block != null:
			_new_choice_control.next_block_menu.text = _new_choice[i].next_block.name
		_new_choice_control.choice_text.text = _new_choice[i].text
		_new_choice_control.next_index_text.value = _new_choice[i].next_index


func _change_command_property(new_property, cmd, current_property, obj = null):
	#This is for the say command text edit, it won't send the text so I send the whole object and get it myself
	if obj != null:
		cmd.set(current_property, obj.get(new_property))
		return

	cmd.set(current_property, new_property)


func _change_next_block(index, cmd: choice, pop: PopupMenu, c_control: Control) -> void:
	cmd.next_block = pop.get_item_metadata(index)
	c_control.next_block_menu.text = pop.get_item_text(index)
	#Create and Update the connection in the GraphNodes here


func _fill_menu(menu: PopupMenu):
	var _c: int
	menu.clear()
	for i in FlowChartTab.flowchart.nodes:
		if _c == null:
			_c = 0
		menu.add_item(i, _c)
		menu.set_item_metadata(_c, FlowChartTab.flowchart.nodes[i][1])
		_c = _c + 1
