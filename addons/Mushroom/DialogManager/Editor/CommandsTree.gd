tool
extends Tree

export var _flowchart_tab: NodePath
onready var root: TreeItem
onready var current_block_label: Label = $"../inspectorHeader/inspectorHeaderHBoxContainer/CurrentBlock"
onready var commands_settings: Panel = $"../../CommandsSettings"
onready var flowchart_tab: Control = get_node(_flowchart_tab)
var current_block: block
onready var undo_redo: UndoRedo = flowchart_tab.undo_redo
var current_node_block: String = ""

# TODO Set up drag and droping, multiselect...


func on_GraphNode_clicked(graph_edit, node_name) -> void:
	undo_redo.create_action("seletect block")
	undo_redo.add_do_method(self, "create_commands", graph_edit, node_name)
	undo_redo.add_undo_method(self, "create_commands", graph_edit, current_node_block)
	undo_redo.commit_action()


func create_commands(graph_edit = null, node_name = null) -> void:
	self.clear()
	var node
	if graph_edit and node_name:
		for g in graph_edit.get_children():
			if g is GraphNode:
				if g.get_title() == node_name:
					node = g
	else:
		return
	if node == null:
		return

	var meta = node.get_meta("block")
	flowchart_tab.graph_edit.set_selected(node)
	commands_settings._currnet_title = meta.name
	current_block = meta
	current_node_block = node.title
	current_block_label.text = "current block: " + meta.name

	# TODO don't update when it is the current block is selected ageain
	if commands_settings.get_child_count() != 0:
		if commands_settings.get_child(0) != null:
			commands_settings.get_child(0).free()

	for i in meta.commands:
		add_command(i)


func full_clear() -> void:
	self.clear()
	if commands_settings:
		commands_settings._currnet_title = ""
	current_block = null
	current_node_block = ""
	if current_block_label:
		current_block_label.text = ""


func _on_add_command(id: int, pop_up: Popup) -> void:
	var _command: Command
	if current_block == null:
		# TODO a warnin here
		return

	_command = pop_up.get_item_metadata(id)
	var _getter: Command = pop_up.get_item_metadata(id)
	_command = _getter.duplicate()  #Carful with the Conditional Command
	undo_redo.create_action("Added Command")
	undo_redo.add_do_method(self, "add_command", _command)
	undo_redo.add_undo_method(self, "delete_command", _command)
	undo_redo.commit_action()
	current_block.commands.append(_command)
	flowchart_tab.changed_flowchart()


func add_command(command: Command) -> void:
	if get_root() == null:
		root = self.create_item()
		self.set_hide_root(true)

	var _item: TreeItem = self.create_item(root)
	_item.set_text(0, command.preview())
	_item.set_meta("0", command)
	#set the new item as the selected one


func delete_command(command: Command) -> void:
	var item = get_root().get_children()
	var children = []
	while item:
		children.append(item)
		item = item.get_next()
	for c in children:
		if c.get_meta("0") == command:
			c.free()
	current_block.commands.erase(command)
	update_commad_tree(current_block)


func update_commad_tree(block: block) -> void:
	flowchart_tab.changed_flowchart()
	self.clear()
	for i in block.commands:
		add_command(i)


func _on_CommandsTree_item_activated() -> void:
	var current_item = get_selected().get_meta("0")
	if current_item != null:
		if !current_item.is_connected("changed", self, "update_commad_tree"):
			current_item.connect("changed", self, "update_commad_tree", [current_block])
		if commands_settings.get_child_count() != 0:
			if commands_settings.get_child(0) != null:
				commands_settings.get_child(0).free()

		if current_item is say_command:
			var say_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/SayControl.tscn").instance()
			commands_settings.add_child(say_control, true)
			say_control.set_up(get_selected().get_meta("0"))

		elif current_item is fork_command:
			var fork_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ForkControl.tscn").instance()
			commands_settings.add_child(fork_control, true)
			fork_control.set_up(
				get_selected().get_meta("0"), flowchart_tab, current_block, undo_redo
			)
