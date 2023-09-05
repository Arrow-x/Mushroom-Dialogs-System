tool
extends Tree

onready var current_block_label: Label = get_node(
	"../inspectorHeader/inspectorHeaderHBoxContainer/CurrentBlock"
)
onready var commands_settings: Panel = get_node("../../CommandsSettings")

var flowchart_tab: Control
var current_block: block
var undo_redo: UndoRedo
var current_node_block: String = ""
var graph_edit: GraphEdit

var current_command_item: Command
var current_command_column

signal moved(item, to_item, shift)
enum resault { success = 1, not_found = -2 }


func _ready():
	connect("button_pressed", self, "_on_Tree_button_pressed")
	var rmb_pop = get_node("CommandRmbPopup/AddCommandRmbPopupMenu")
	rmb_pop.connect("index_pressed", self, "_on_add_command", [rmb_pop, true])
	connect("moved", self, "_on_move_treeitem")


func _on_Tree_button_pressed(item: TreeItem, _collumn: int, _id: int):
	var cmd: Command = item.get_meta("command")
	var parent_command: Command = null
	var idx: int = find_TreeItem(item)
	var parent: TreeItem = null

	if item.get_parent().has_meta("command"):
		var parent_meta = item.get_parent().get_meta("command")
		if parent_meta is condition_command:
			parent_command = parent_meta
			idx = parent_meta.condition_block.commands.find(cmd)
			parent = item.get_parent()

	undo_redo.create_action("delete_command")
	undo_redo.add_do_method(self, "delete_command", cmd, parent)
	undo_redo.add_undo_method(self, "create_command", cmd, idx, parent_command)
	undo_redo.commit_action()


func create_commands(meta: block) -> void:
	if meta == current_block or meta == null:
		return
	full_clear()
	commands_settings._currnet_title = meta.name
	current_block = meta
	current_node_block = meta.name
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
		push_error("there is no block selected")
		return

	var _command: Command = pop_up.get_item_metadata(id).duplicate()

	var idx: int = -1
	var p: Command = null

	if is_rmb:
		var selec_m: Command = get_selected().get_meta("command")
		if selec_m is condition_command:
			p = selec_m
		else:
			var selec_p := get_selected().get_parent()
			if selec_p == get_root():
				idx = find_TreeItem(get_selected()) + 1
			else:
				idx = selec_p.get_meta("command").condition_block.commands.find(selec_m) + 1
				p = selec_p.get_meta("command")

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


func add_command(command: Command, idx: int = -1, parent: TreeItem = null) -> TreeItem:
	var l_parent := parent
	if get_root() == null:
		l_parent = self.create_item()
		self.set_hide_root(true)

	var _item: TreeItem = self.create_item(l_parent, idx)
	_item.set_text(0, command.preview())
	_item.set_icon(0, command.get_icon())
	_item.set_meta("command", command)
	_item.add_button(
		0, load("res://addons/Mushroom/DialogManager/Editor/icons/outline_close_white_18dp.png")
	)
	flowchart_tab.changed_flowchart()
	return _item


func delete_command(command: Command, tree: TreeItem = null) -> int:
	var d_tree: Array
	var d_block: block

	if tree:
		d_tree = get_TreeItems(tree)
		d_block = tree.get_meta("command").condition_block
	else:
		d_tree = get_TreeItems(get_root())
		d_block = current_block

	for c in d_tree.size():
		var d_c = d_tree[c]
		if d_c.get_meta("command") == command:
			d_c.free()
			d_block.commands.remove(c)
			delete_command_clean(command)
			return resault.success
		elif d_c.get_meta("command") is condition_command:
			var b = delete_command(command, d_c)
			if b != resault.not_found:
				delete_command_clean(command)
				return resault.success
	return resault.not_found


func delete_command_clean(command: Command) -> void:
	update_commad_tree(current_block)
	for c_s in commands_settings.get_children():
		if c_s.get_command() == command:
			c_s.queue_free()


func get_drag_data(_position: Vector2) -> TreeItem:  # begin drag
	var preview := Label.new()
	preview.text = get_selected().get_text(0)

	set_drag_preview(preview)  # not necessary

	return get_selected()  # TreeItem


func can_drop_data(position: Vector2, data) -> bool:
	if not data is TreeItem:
		return false
	var to_item := get_item_at_position(position)
	if to_item is TreeItem:
		if to_item.get_meta("command") is condition_command:
			set_drop_mode_flags(DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM)
		else:
			set_drop_mode_flags(DROP_MODE_INBETWEEN)
	return true


func drop_data(position: Vector2, item: TreeItem) -> void:  # end drag
	var to_item := get_item_at_position(position)
	var shift := get_drop_section_at_position(position)
	# shift == 0 if dropping on item, -1, +1 if in between
	emit_signal("moved", item, to_item, shift)


func _on_move_treeitem(item: TreeItem, to_item: TreeItem, shift: int) -> void:
	var item_idx: int = find_TreeItem(item)
	var parent_item: TreeItem = item.get_parent() if item != null else get_root()
	var c_p_to_item: Array = (
		current_block.commands
		if parent_item == get_root()
		else parent_item.get_meta("command").condition_block.commands
	)

	if not to_item == null:
		if to_item.get_parent() == item:
			push_error("can't dragge into self")
			return

	undo_redo.create_action("drag command")
	undo_redo.add_do_method(self, "move_treeitem", item, to_item, shift)
	undo_redo.add_undo_method(
		self, "undo_move_treeitem", item.get_meta("command"), c_p_to_item, item_idx
	)
	undo_redo.commit_action()


func move_treeitem(item: TreeItem, to_item: TreeItem = null, shift: int = -100) -> void:
	var to_item_idx: int = find_TreeItem(to_item)
	var item_idx: int = find_TreeItem(item)
	var c_item := item.get_meta("command") as Command
	var c_to_item: Command = to_item.get_meta("command") if to_item != null else null
	var p_to_item: TreeItem = to_item.get_parent() if to_item != null else get_root()
	var c_p_to_item: Array = (
		current_block.commands
		if p_to_item == get_root()
		else p_to_item.get_meta("command").condition_block.commands
	)
	if item_idx == resault.not_found:
		return

	match shift:
		-1:
			c_p_to_item.insert(to_item_idx, c_item)
		0:
			c_to_item.condition_block.commands.append(c_item)
		1:
			if c_to_item is condition_command:
				c_to_item.condition_block.commands.insert(0, c_item)
			else:
				if to_item_idx + 1 > c_p_to_item.size():
					c_p_to_item.append(c_item)
				else:
					c_p_to_item.insert(to_item_idx + 1, c_item)
		-100:
			c_p_to_item.append(c_item)

	if not to_item_idx == resault.not_found:
		if not shift == 0:
			if item.get_parent() == p_to_item:
				if not shift == 1 and not c_to_item is condition_command:
					if item_idx > to_item_idx:
						item_idx = item_idx + 1

	if item.get_parent() == get_root():
		current_block.commands.remove(item_idx)
	else:
		item.get_parent().get_meta("command").condition_block.commands.remove(item_idx)

	update_commad_tree(current_block)


func undo_move_treeitem(og_item_command: Command, og_parent_commands: Array, og_idx: int):
	var to_item := get_TreeItems_from_Command(og_item_command)
	var p_to_item := to_item.get_parent()
	var c_p_to_item: Command = (
		p_to_item.get_meta("command")
		if p_to_item.has_meta("command")
		else null
	)
	var item_idx := find_TreeItem(to_item)

	if item_idx == resault.not_found:
		push_error("can't find it")
		return
	if to_item == null or p_to_item == get_root():
		current_block.commands.remove(item_idx)
	elif c_p_to_item is condition_command:
		c_p_to_item.condition_block.commands.remove(item_idx)
	og_parent_commands.insert(og_idx, og_item_command)
	update_commad_tree(current_block)


func get_TreeItems(parent: TreeItem) -> Array:
	var item = parent.get_children()
	var children = []
	while item:
		children.append(item)
		item = item.get_next()
	return children


func find_TreeItem(item: TreeItem, parent: TreeItem = null) -> int:
	var treeitems: Array
	if item == null:
		return resault.not_found
	if parent == null:
		treeitems = get_TreeItems(get_root())
	else:
		treeitems = get_TreeItems(parent)

	for i in treeitems.size():
		if treeitems[i] == item:
			return i
		elif treeitems[i].get_meta("command") is condition_command:
			var r: int = find_TreeItem(item, treeitems[i])
			if r != resault.not_found:
				return r
	return resault.not_found


func prepare_command_editor(cmd: Command) -> void:
# TODO: why does this exit?
	if cmd == null:
		push_error("can't find treeitem")
		return
	create_command_editor(get_TreeItems_from_Command(cmd))


func get_TreeItems_from_Command(command: Command, parent: TreeItem = null) -> TreeItem:
	var tree: Array
	if parent == null:
		tree = get_TreeItems(get_root())
	else:
		tree = get_TreeItems(parent)
	for t in tree:
		var t_cmd: Command = t.get_meta("command")
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
	var sel_c: Command = get_selected().get_meta("command")
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

	var current_item = item.get_meta("command")

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
			say_control.set_up(current_item, undo_redo)

		elif current_item is fork_command:
			var fork_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ForkControl.tscn").instance()
			commands_settings.add_child(fork_control, true)
			fork_control.set_up(current_item, flowchart_tab, current_block, undo_redo, graph_edit)

		elif current_item is condition_command:
			var condition_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ConditionControl.tscn").instance()
			commands_settings.add_child(condition_control, true)
			condition_control.set_up(current_item)

		elif current_item is set_var_command:
			var set_var_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/SetVar.tscn").instance()
			commands_settings.add_child(set_var_control, true)
			set_var_control.set_up(current_item)

		elif current_item is animation_command:
			var animation_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/AnimationControl.tscn").instance()
			commands_settings.add_child(animation_control, true)
			animation_control.set_up(current_item, undo_redo)

		elif current_item is jump_command:
			var jump_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/JumpControl.tscn").instance()
			commands_settings.add_child(jump_control, true)
			jump_control.set_up(current_item, undo_redo, flowchart_tab.flowchart)


func _on_CommandsTree_item_rmb_selected(position: Vector2) -> void:
	var pop: PopupMenu = get_node("CommandRmbPopup")
	pop.set_up()
	var gmp := get_global_mouse_position()
	pop.popup(Rect2(gmp.x, gmp.y, pop.rect_size.x, pop.rect_size.y))
