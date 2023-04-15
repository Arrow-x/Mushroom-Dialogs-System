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
onready var undo_redo: UndoRedo
var current_node_block: String = ""
var graph_edit: GraphEdit

var current_command_item: Command
var current_command_column

# TODO: Set up drag and droping, multiselect...


func _ready():
	connect("button_pressed", self, "_on_Tree_button_pressed")
	var rmb_pop = get_node("CommandRmbPopup/AddCommandRmbPopupMenu")
	rmb_pop.connect("index_pressed", self, "_on_add_command", [rmb_pop, true])


func _on_Tree_button_pressed(item: TreeItem, _collumn: int, _id: int):
	var cmd: Command = item.get_meta("0")
	var parent_command: Command = null
	var idx: int = find_TreeItem(item)
	var parent: TreeItem = null

	if item.get_parent().has_meta("0"):
		var parent_meta = item.get_parent().get_meta("0")
		if parent_meta is condition_command:
			parent_command = parent_meta
			idx = parent_meta.condition_block.commands.find(cmd)
			parent = item.get_parent()

	undo_redo.create_action("delete_command")
	undo_redo.add_do_method(self, "delete_command", cmd, parent)
	undo_redo.add_undo_method(self, "create_command", cmd, idx, parent_command)
	undo_redo.commit_action()


func on_GraphNode_clicked(graph_edit, node_name) -> void:
	undo_redo.create_action("seletect block")
	undo_redo.add_do_method(self, "create_commands", graph_edit, node_name)
	undo_redo.add_undo_method(self, "create_commands", graph_edit, current_node_block)
	undo_redo.commit_action()


func create_commands(graph_edit = null, node_name = null) -> void:
	# TODO:  why is this so complicated? the graph node should just send it's block
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
	# Don't update if the clicked g_node is already selected
	if meta == current_block:
		return

	full_clear()
	# flowchart_tab.graph_edit.set_selected(node)
	commands_settings._currnet_title = meta.name
	current_block = meta
	current_node_block = node.title
	current_block_label.text = "current block: " + meta.name

	if commands_settings.get_child_count() != 0:
		if commands_settings.get_child(0) != null:
			commands_settings.get_child(0).free()

	update_commad_tree(meta)


func full_clear() -> void:
	self.clear()
	if commands_settings:
		commands_settings._currnet_title = ""
	current_block = null
	current_node_block = ""
	if current_block_label:
		current_block_label.text = ""


func _on_add_command(id: int, pop_up: Popup, is_rmb = false) -> void:
	if current_block == null:
		print("there is no block selected")
		return

	var _command: Command = pop_up.get_item_metadata(id).duplicate()

	var idx: int = -1
	var p: Command = null

	if is_rmb:
		var selec_m: Command = get_selected().get_meta("0")
		if selec_m is condition_command:
			p = selec_m
		else:
			var selec_p := get_selected().get_parent()
			if selec_p == get_root():
				idx = find_TreeItem(get_selected()) + 1
			else:
				idx = selec_p.get_meta("0").condition_block.commands.find(selec_m) + 1
				p = selec_p.get_meta("0")

	undo_redo.create_action("Added Command")
	undo_redo.add_do_method(self, "create_command", _command, idx, p)
	undo_redo.add_undo_method(self, "delete_command", _command)
	undo_redo.commit_action()


func create_command(command: Command, idx: int = -1, parent = null) -> void:
	if parent == null or parent == get_root():
		var cbc: Array = current_block.commands
		if idx == -1:
			cbc.append(command)
		else:
			cbc.insert(idx, command)

	else:
		if parent is condition_command:
			var prc: Array = parent.condition_block.commands
			if idx == -1:
				prc.append(command)
			else:
				prc.insert(idx, command)

	update_commad_tree(current_block)


func add_command(command: Command, idx: int = -1, parent = null) -> TreeItem:
	if get_root() == null:
		parent = self.create_item()
		self.set_hide_root(true)

	var p = parent
	if parent != null:
		p = parent

	var _item: TreeItem = self.create_item(p, idx)
	_item.set_text(0, command.preview())
	_item.set_icon(0, command.get_icon())
	_item.set_meta("0", command)
	_item.add_button(
		0, load("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png")
	)
	flowchart_tab.changed_flowchart()
	return _item


func delete_command(command: Command, tree: TreeItem = null) -> void:
	var d_tree: Array
	var d_block: block

	if tree:
		d_tree = get_TreeItems(tree)
		d_block = tree.get_meta("0").condition_block
	else:
		d_tree = get_TreeItems(get_root())
		d_block = current_block

	for c in d_tree:
		if c.get_meta("0") == command:
			c.free()
			d_block.commands.erase(command)
		elif c.get_meta("0") is condition_command:
			delete_command(command, c)
			continue
		else:
			continue

		update_commad_tree(current_block)
		for c_s in commands_settings.get_children():
			if c_s.get_command() == command:
				c_s.queue_free()
		return


func get_TreeItems(parent: TreeItem) -> Array:
	var item = parent.get_children()
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


func prepare_command_editor(cmd: Command) -> void:
	if cmd == null:
		print("can't find treeitem")
		return
	create_command_editor(get_TreeItems_from_Command(cmd))


func get_TreeItems_from_Command(command: Command, parent: TreeItem = null) -> TreeItem:
	var tree: Array
	if parent == null:
		tree = get_TreeItems(get_root())
	else:
		tree = get_TreeItems(parent)
	for t in tree:
		var t_cmd: Command = t.get_meta("0")
		if t_cmd == command:
			return t
		elif t_cmd is condition_command:
			var s := get_TreeItems_from_Command(command, t)
			if s != null:
				return s
	return null


func update_commad_tree(block: block, parent: TreeItem = null) -> void:
	if parent == null:
		self.clear()
	for i in block.commands:
		var created_item: TreeItem = add_command(i, -1, parent)
		if i is condition_command:
			update_commad_tree(i.condition_block, created_item)


func _on_CommandsTree_item_activated() -> void:
	var sel_c: Command = get_selected().get_meta("0")
	undo_redo.create_action("selecting a command")
	undo_redo.add_do_method(self, "prepare_command_editor", sel_c)
	undo_redo.add_undo_method(self, "prepare_command_editor", current_command_item)
	undo_redo.commit_action()

	current_command_item = sel_c


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
			fork_control.set_up(current_item, flowchart_tab, current_block, undo_redo, graph_edit)

		elif current_item is condition_command:
			var condition_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ConditionControl.tscn").instance()
			commands_settings.add_child(condition_control, true)
			condition_control.set_up(current_item)


func _on_CommandsTree_item_rmb_selected(position: Vector2) -> void:
	var pop: PopupMenu = get_node("CommandRmbPopup")
	pop.set_up()
	var gmp := get_global_mouse_position()
	pop.popup(Rect2(gmp.x, gmp.y, pop.rect_size.x, pop.rect_size.y))
