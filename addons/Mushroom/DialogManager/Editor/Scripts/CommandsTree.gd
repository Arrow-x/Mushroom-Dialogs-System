@tool
extends Tree

@export var current_block_label: Label
@export var commands_settings: Panel
@export var add_rmb_pop: PopupMenu
@export var rmb_pop: PopupMenu

var flowchart_tab: Control
var current_block: Block
var undo_redo: EditorUndoRedoManager
var graph_edit: GraphEdit

var prev_selected_Command: Command

enum resault { success = 1, not_found = -2 }

signal moved(item, to_item, shift)


func _ready():
	button_clicked.connect(_on_tree_item_x_button_pressed)
	add_rmb_pop.index_pressed.connect(_on_add_command.bind(rmb_pop, true))
	moved.connect(_on_moved)


func _on_tree_item_x_button_pressed(item: TreeItem, _collumn: int, _id: int, mouse_idx: int):
	if mouse_idx != 1:
		return
	var cmd: Command = item.get_meta("command")
	var parent_command: Command = null
	var idx: int = find_tree_item(item)
	var parent: TreeItem = null

	if item.get_parent().has_meta("command"):
		var parent_meta = item.get_parent().get_meta("command")
		if parent_meta is ConditionCommand:
			parent_command = parent_meta
			idx = parent_meta.condition_block.commands.find(cmd)
			parent = item.get_parent()

	undo_redo.create_action("delete_command")
	undo_redo.add_do_method(self, "delete_command", cmd, parent)
	undo_redo.add_undo_method(self, "add_command_to_block", cmd, idx, parent_command)
	undo_redo.commit_action()


func initiate_tree_from_block(meta: Block) -> void:
	if meta == current_block or meta == null:
		return
	full_clear()
	commands_settings._currnet_title = meta.name
	current_block = meta
	current_block_label.text = "current block: " + meta.name

	for c in commands_settings.get_children():
		c.queue_free()

	create_tree_from_block(meta)


func full_clear() -> void:
	self.clear()
	if commands_settings:
		commands_settings._currnet_title = ""
	current_block = null
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
		if selec_m is ConditionCommand:
			p = selec_m
		else:
			var selec_p := get_selected().get_parent()
			if selec_p == get_root():
				idx = find_tree_item(get_selected()) + 1
			else:
				idx = selec_p.get_meta("command").condition_block.commands.find(selec_m) + 1
				p = selec_p.get_meta("command")

	undo_redo.create_action("Added Command")
	undo_redo.add_do_method(self, "add_command_to_block", _command, idx, p)
	undo_redo.add_undo_method(self, "delete_command", _command)
	undo_redo.commit_action()


func add_command_to_block(command: Command, idx: int = -1, parent = null) -> void:
	if parent == null or parent == get_root():
		var cbc: Array = current_block.commands
		if idx == -1:
			cbc.append(command)
		else:
			cbc.insert(idx, command)

	else:
		if parent is ConditionCommand:
			var prc: Array = parent.condition_block.commands
			if idx == -1:
				prc.append(command)
			else:
				prc.insert(idx, command)
	if command is ForkCommand:
		current_block.outputs.append(command)
	create_tree_from_block(current_block)
	graph_edit.connect_block_outputs(current_block, true)


func create_tree_item_from_command(
	command: Command, idx: int = -1, parent: TreeItem = null
) -> TreeItem:
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
	var d_block: Block
	if command is ForkCommand:
		graph_edit.delete_output(current_block.name, command)

	if tree:
		d_tree = tree.get_children()
		d_block = tree.get_meta("command").condition_block
	else:
		d_tree = get_root().get_children()
		d_block = current_block
	for c in d_tree.size():
		var d_c = d_tree[c]
		if d_c.get_meta("command") == command:
			d_c.free()
			d_block.commands.remove_at(c)
			free_Command_editor(command)
			create_tree_from_block(current_block)
			return resault.success
		elif d_c.get_meta("command") is ConditionCommand:
			var b = delete_command(command, d_c)
			if b != resault.not_found:
				free_Command_editor(command)
				create_tree_from_block(current_block)
				return resault.success
	return resault.not_found


func free_Command_editor(command: Command) -> void:
	for c_s in commands_settings.get_children():
		if c_s.get_command() == command:
			c_s.queue_free()


func _get_drag_data(_position: Vector2):
	var preview := Label.new()
	preview.text = get_selected().get_text(0)

	set_drag_preview(preview)

	return get_selected()


func _can_drop_data(position: Vector2, data) -> bool:
	if not data is TreeItem:
		return false
	var to_item := get_item_at_position(position)
	if to_item is TreeItem:
		if to_item.get_meta("command") is ConditionCommand:
			set_drop_mode_flags(DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM)
		else:
			set_drop_mode_flags(DROP_MODE_INBETWEEN)
	return true


func _drop_data(position: Vector2, item) -> void:
	var to_item := get_item_at_position(position)
	var shift := get_drop_section_at_position(position)
	# shift == 0 if dropping on item, -1, +1 if in between
	moved.emit(item, to_item, shift)


func _on_moved(item: TreeItem, to_item: TreeItem, shift: int) -> void:
	var item_idx: int = find_tree_item(item)
	if item_idx == resault.not_found:
		push_error("can't find dragged TreeItem")
		return

	if to_item != null:
		if to_item.get_parent() == item:
			push_error("can't dragge into self")
			return

	var parent_item: TreeItem = item.get_parent() if item != null else get_root()
	var to_item_parent_commands: Array = (
		current_block.commands
		if parent_item == get_root()
		else parent_item.get_meta("command").condition_block.commands
	)
	var item_command := item.get_meta("command") as Command
	var to_item_command := to_item.get_meta("command") as Command if to_item != null else null

	undo_redo.create_action("drag command")
	undo_redo.add_do_method(self, "move_tree_item", item_command, item_idx, to_item_command, shift)
	undo_redo.add_undo_method(
		self, "undo_move_tree_item", item.get_meta("command"), to_item_parent_commands, item_idx
	)
	undo_redo.commit_action()


func move_tree_item(
	item_command: Command, item_idx: int, to_item_command: Command = null, shift: int = -100
) -> void:
	var item := get_tree_item_from_command(item_command)
	var to_item := get_tree_item_from_command(to_item_command)
	var to_item_idx: int = find_tree_item(to_item)
	var to_itme_parent: TreeItem = to_item.get_parent() if to_item != null else get_root()
	var to_item_parent_commands: Array = (
		current_block.commands
		if to_itme_parent == get_root()
		else to_itme_parent.get_meta("command").condition_block.commands
	)

	match shift:
		-1:
			to_item_parent_commands.insert(to_item_idx, item_command)
		0:
			to_item_command.condition_block.commands.append(item_command)
		1:
			if to_item_command is ConditionCommand:
				to_item_command.condition_block.commands.insert(0, item_command)
			else:
				if to_item_idx + 1 > to_item_parent_commands.size():
					to_item_parent_commands.append(item_command)
				else:
					to_item_parent_commands.insert(to_item_idx + 1, item_command)
		-100:
			to_item_parent_commands.append(item_command)

	if to_item_idx != resault.not_found:
		if shift != 0 or shift != 1:
			if item.get_parent() == to_itme_parent:
				if not to_item_command is ConditionCommand:
					if item_idx > to_item_idx:
						item_idx = item_idx + 1

	if item.get_parent() == get_root():
		current_block.commands.remove_at(item_idx)
	else:
		item.get_parent().get_meta("command").condition_block.commands.remove_at(item_idx)

	create_tree_from_block(current_block)


func undo_move_tree_item(og_item_command: Command, og_parent_commands: Array, og_idx: int):
	var to_item := get_tree_item_from_command(og_item_command)
	var item_idx := find_tree_item(to_item)
	if item_idx == resault.not_found:
		push_error("can't find it")
		return
	var to_item_parent := to_item.get_parent()
	var to_item_parent_commands: Command = (
		to_item_parent.get_meta("command") if to_item_parent.has_meta("command") else null
	)

	if to_item == null or to_item_parent == get_root():
		current_block.commands.remove_at(item_idx)
	elif to_item_parent_commands is ConditionCommand:
		to_item_parent_commands.condition_block.commands.remove_at(item_idx)

	og_parent_commands.insert(og_idx, og_item_command)
	create_tree_from_block(current_block)


func find_tree_item(item: TreeItem, parent: TreeItem = null) -> int:
	var treeitems: Array
	if item == null:
		return resault.not_found
	if parent == null:
		treeitems = get_root().get_children()
	else:
		treeitems = parent.get_children()

	for i in treeitems.size():
		if treeitems[i] == item:
			return i
		elif treeitems[i].get_meta("command") is ConditionCommand:
			var r: int = find_tree_item(item, treeitems[i])
			if r != resault.not_found:
				return r
	return resault.not_found


func get_tree_item_from_command(command: Command, parent: TreeItem = null) -> TreeItem:
	var tree: Array
	if command == null:
		return null
	if parent == null:
		tree = get_root().get_children()
	else:
		tree = parent.get_children()
	for t in tree:
		var t_cmd: Command = t.get_meta("command")
		if t_cmd == command:
			return t
		elif t_cmd is ConditionCommand:
			var s := get_tree_item_from_command(command, t)
			if s != null:
				return s
	return null


func create_tree_from_block(block: Block, parent: TreeItem = null) -> void:
	if parent == null:
		self.clear()
	for i in block.commands:
		var created_item: TreeItem = create_tree_item_from_command(i, -1, parent)
		if i is ConditionCommand:
			create_tree_from_block(i.condition_block, created_item)


func _on_tree_item_double_clicked() -> void:
	var sel_c: Command = get_selected().get_meta("command")
	undo_redo.create_action("selecting a command")
	undo_redo.add_do_method(self, "create_command_editor", sel_c)
	undo_redo.add_undo_method(self, "create_command_editor", prev_selected_Command)
	undo_redo.commit_action()

	prev_selected_Command = sel_c


func create_command_editor(current_item = null) -> void:
	# NOTE: typing current_item as Command will run get_class() on it and not on any
	# of the inhearted types

	deselect_all()

	if current_item == null:
		return

	if !current_item.changed.is_connected(create_tree_from_block):
		current_item.changed.connect(create_tree_from_block.bind(current_block))

	for c in commands_settings.get_children():
		c.queue_free()
	var control: Control
	match current_item.get_class():
		"SayCommand":
			control = (
				load("res://addons/Mushroom/DialogManager/Editor/Commands/SayControl.tscn")
				. instantiate()
			)
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, flowchart_tab.flowchart)

		"ForkCommand":
			control = (
				load("res://addons/Mushroom/DialogManager/Editor/Commands/ForkControl.tscn")
				. instantiate()
			)
			commands_settings.add_child(control, true)
			control.set_up(
				current_item, undo_redo, flowchart_tab.flowchart, current_block, graph_edit, self
			)

		"ConditionCommand":
			control = (
				load("res://addons/Mushroom/DialogManager/Editor/Commands/ConditionControl.tscn")
				. instantiate()
			)
			commands_settings.add_child(control, true)
			control.set_up(current_item)

		"SetVarCommand":
			control = (
				load("res://addons/Mushroom/DialogManager/Editor/Commands/SetVar.tscn")
				. instantiate()
			)
			commands_settings.add_child(control, true)
			control.set_up(current_item)

		"AnimationCommand":
			control = (
				load("res://addons/Mushroom/DialogManager/Editor/Commands/AnimationControl.tscn")
				. instantiate()
			)
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"JumpCommand":
			control = (
				load("res://addons/Mushroom/DialogManager/Editor/Commands/JumpControl.tscn")
				. instantiate()
			)
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, flowchart_tab.flowchart, self)

		"SoundCommand":
			control = (
				load("res://addons/Mushroom/DialogManager/Editor/Commands/SoundControl.tscn")
				. instantiate()
			)
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo)

		"ChangeUICommand":
			control = (
				load("res://addons/Mushroom/DialogManager/Editor/Commands/ChangeUIControl.tscn")
				. instantiate()
			)
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, self)
		_:
			return

	var item := get_tree_item_from_command(current_item)
	if item == null:
		return
	set_selected(item, 0)
	ensure_cursor_is_visible()


func _on_tree_item_rmb_selected(position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != 2:
		return
	rmb_pop.set_up()
	var gmp := get_global_mouse_position()
	rmb_pop.popup(Rect2(gmp.x, gmp.y, rmb_pop.size.x, rmb_pop.size.y))


func command_undo_redo_caller(undo_redo_method: StringName, args: Array = [], obj = null) -> void:
	var object
	if obj != null:
		if obj is Choice:
			for c in commands_settings.get_child(0).choices_container.get_children():
				if not c.has_method("get_choice"):
					continue
				if c.get_choice() == obj:
					object = c
					break
		else:
			object = obj
	else:
		object = commands_settings.get_child(0)

	if object:
		if object.has_method(undo_redo_method):
			object.callv(undo_redo_method, args)
