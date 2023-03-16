tool
extends Tree

export var _flowchart_tab: NodePath
onready var root: TreeItem
onready var current_block_label: Label = get_node(
	"../inspectorHeader/inspectorHeaderHBoxContainer/CurrentBlock"
)
onready var commands_settings: Panel = get_node("../../CommandsSettings")

onready var flowchart_tab: Control = get_node(_flowchart_tab)
var current_block: block
onready var undo_redo: UndoRedo = flowchart_tab.undo_redo
var current_node_block: String = ""

var current_command_item = -2
var current_command_column

# TODO: Set up drag and droping, multiselect...


func _ready():
	connect("button_pressed", self, "_on_Tree_button_pressed")


func _on_Tree_button_pressed(item: TreeItem, collumn: int, id: int):
	var cmd: Command = item.get_meta("0")
	undo_redo.create_action("delete_command")
	undo_redo.add_do_method(self, "delete_command", cmd)
	undo_redo.add_undo_method(self, "create_command", cmd, find_TreeItem(item))
	undo_redo.commit_action()


func on_GraphNode_clicked(graph_edit, node_name) -> void:
	undo_redo.create_action("seletect block")
	undo_redo.add_do_method(self, "create_commands", graph_edit, node_name)
	undo_redo.add_undo_method(self, "create_commands", graph_edit, current_node_block)
	undo_redo.commit_action()


func create_commands(graph_edit = null, node_name = null) -> void:
	full_clear()
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

	# TODO: don't update when it is the current block is selected ageain
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
	if current_block == null:
		# TODO: a warnin here
		return

	#Carful with the Conditional Command
	var _command: Command = pop_up.get_item_metadata(id).duplicate()
	undo_redo.create_action("Added Command")
	undo_redo.add_do_method(self, "create_command", _command)
	undo_redo.add_undo_method(self, "delete_command", _command)
	undo_redo.commit_action()


func create_command(command: Command, idx: int = -1) -> void:
	if idx != -1:
		current_block.commands.insert(idx, command)
	else:
		current_block.commands.append(command)
	add_command(command, idx)


func add_command(command: Command, idx: int = -1) -> void:
	if get_root() == null:
		root = self.create_item()
		self.set_hide_root(true)

	var _item: TreeItem = self.create_item(root, idx)
	_item.set_text(0, command.preview())
	_item.set_icon(0, command.get_icon())
	_item.set_meta("0", command)
	_item.add_button(
		0, load("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png")
	)
	flowchart_tab.changed_flowchart()


func delete_command(command: Command) -> void:
	for c in get_TreeItems(get_root()):
		if c.get_meta("0") == command:
			c.free()
			current_block.commands.erase(command)
			update_commad_tree(current_block)
			for c_s in commands_settings.get_children():
				if c_s.get_command() == command:
					c_s.queue_free()
			return


func get_TreeItems(root: TreeItem) -> Array:
	var item = root.get_children()
	var children = []
	while item:
		children.append(item)
		item = item.get_next()
	return children


func find_TreeItem(item: TreeItem) -> int:
	var treeitems: Array = get_TreeItems(get_root())
	for i in treeitems.size():
		if treeitems[i] == item:
			return i
	return -2


func get_TreeItem_from_index(idx: int) -> void:
	if idx == -2:
		print("can't find treeitem")
		return
	create_command_editor(get_TreeItems(get_root())[idx])


func update_commad_tree(block: block) -> void:
	flowchart_tab.changed_flowchart()
	self.clear()
	for i in block.commands:
		add_command(i)


func _on_CommandsTree_item_activated() -> void:
	var current_index: int = find_TreeItem(get_selected())
	undo_redo.create_action("selecting a command")
	undo_redo.add_do_method(self, "get_TreeItem_from_index", current_index)
	undo_redo.add_undo_method(self, "get_TreeItem_from_index", current_command_item)
	undo_redo.commit_action()

	current_command_item = current_index


func create_command_editor(item: TreeItem = null) -> void:
	if item == null:
		for c in commands_settings.get_children():
			c.queue_free()
		return

	var current_item = item.get_meta("0")

	for c in get_TreeItems(get_root()):
		c.deselect(0)

	item.select(0)

	if current_item != null:
		if !current_item.is_connected("changed", self, "update_commad_tree"):
			current_item.connect("changed", self, "update_commad_tree", [current_block])
		if commands_settings.get_child_count() != 0:
			if commands_settings.get_child(0) != null:
				commands_settings.get_child(0).free()

		if current_item is say_command:
			var say_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/SayControl.tscn").instance()
			commands_settings.add_child(say_control, true)
			say_control.set_up(current_item)

		elif current_item is fork_command:
			var fork_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ForkControl.tscn").instance()
			commands_settings.add_child(fork_control, true)
			fork_control.set_up(current_item, flowchart_tab, current_block, undo_redo)

		elif current_item is condition_command:
			var condition_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ConditionControl.tscn").instance()
			commands_settings.add_child(condition_control, true)
			condition_control.set_up(current_item)
