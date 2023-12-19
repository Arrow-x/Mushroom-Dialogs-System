@tool
extends Tree

@export var current_block_label: Label
@export var commands_settings: Container
@export var general_rmb_menu: PopupMenu
@export var rename_button: Button

@export var i_animation_control: PackedScene
@export var i_call_function_control: PackedScene
@export var i_change_ui_control: PackedScene
@export var i_condition_control: PackedScene
@export var i_fork_control: PackedScene
@export var i_general_container_command: PackedScene
@export var i_jump_control: PackedScene
@export var i_say_control: PackedScene
@export var i_set_var_control: PackedScene
@export var i_signal_control: PackedScene
@export var i_sound_control: PackedScene

@export var icon_x: Texture2D

var flowchart_tab: Control
var current_block: Block
var undo_redo: EditorUndoRedoManager
var graph_edit: GraphEdit

var prev_selected_Command: Command

enum resault { success = 1, not_found = -2 }

signal moved(item, to_item, shift)
signal tree_changed(flowchart: FlowChart)


func _ready():
	button_clicked.connect(_on_tree_item_x_button_pressed)
	general_rmb_menu.add_index_pressed.connect(_on_add_command.bind(true))
	general_rmb_menu.index_pressed.connect(_rmb_menu_index_pressed)
	item_collapsed.connect(
		func(item: TreeItem) -> void: item.get_meta("command").collapse = item.is_collapsed()
	)
	moved.connect(_on_moved)


func _on_tree_item_rmb_selected(position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != 2:
		return
	general_rmb_menu.set_up()
	var gmp := get_global_mouse_position()
	general_rmb_menu.popup(Rect2(gmp.x, gmp.y, general_rmb_menu.size.x, general_rmb_menu.size.y))


func _rmb_menu_index_pressed(idx: int) -> void:
	if general_rmb_menu.get_item_text(idx) == "delete":
		_on_tree_item_x_button_pressed(get_selected(), 0, 1, 1)


func _on_tree_item_x_button_pressed(
	item: TreeItem, _collumn: int, _id: int, mouse_idx: int
) -> void:
	if mouse_idx != 1:
		return
	var cmd: Command = item.get_meta("command")
	var parent_command: Command = null
	var idx: int = find_tree_item(item)
	var parent: TreeItem = null

	if item.get_parent().has_meta("command"):
		var parent_meta = item.get_parent().get_meta("command")
		if parent_meta is ContainerCommand:
			parent_command = parent_meta
			idx = parent_meta.container_block.commands.find(cmd)
			parent = item.get_parent()

	undo_redo.create_action("delete_command")
	undo_redo.add_do_method(self, "delete_command", cmd, parent)
	undo_redo.add_undo_method(self, "add_command_to_block", cmd, idx, parent_command)
	undo_redo.commit_action()


func initiate_tree_from_block(meta: Block) -> void:
	if meta == current_block or meta == null:
		return
	full_clear()
	current_block = meta
	current_block_label.text = meta.name
	if meta.name == "first_block":
		rename_button.disabled = true
	else:
		rename_button.disabled = false

	for c in commands_settings.get_children():
		c.queue_free()

	create_tree_from_block(meta)


func full_clear() -> void:
	self.clear()
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
		if selec_m is ContainerCommand:
			p = selec_m
		else:
			var selec_p := get_selected().get_parent()
			if selec_p == get_root():
				idx = find_tree_item(get_selected()) + 1
			else:
				idx = selec_p.get_meta("command").container_block.commands.find(selec_m) + 1
				p = selec_p.get_meta("command")

	undo_redo.create_action("Added Command")
	undo_redo.add_do_method(self, "add_command_to_block", _command, idx, p)
	undo_redo.add_undo_method(self, "delete_command", _command)
	undo_redo.commit_action()


func add_command_to_block(command: Command, idx: int = -1, parent: Command = null) -> void:
	if parent == null:
		var cbc: Array = current_block.commands
		if idx == -1:
			cbc.append(command)
		else:
			cbc.insert(idx, command)

	else:
		if parent is ContainerCommand:
			var prc: Array[Command] = parent.container_block.commands
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
	_item.add_button(0, icon_x)
	if command is ContainerCommand:
		_item.set_collapsed(command.collapse)
	if command is ElseCommand or command is IfElseCommand:
		var l := l_parent.get_children() if l_parent != null else get_root().get_children()
		var v_idx := l.size() - 2 if idx == -1 else idx - 1
		var l_cmd: Command = l[v_idx].get_meta("command")
		if not l_cmd is IfCommand or v_idx == -1:
			_item.set_custom_color(0, Color.RED)

	flowchart_tab.changed_flowchart()
	return _item


func delete_command(command: Command, tree: TreeItem = null) -> int:
	var d_tree: Array
	var d_block: Block
	if command is ForkCommand:
		graph_edit.delete_output(current_block.name, command)

	if tree:
		d_tree = tree.get_children()
		d_block = tree.get_meta("command").container_block
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
		elif d_c.get_meta("command") is ContainerCommand:
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
	if get_selected() == null:
		return
	var selected_dict := get_all_selected_tree_items()

	var preview := Label.new()
	var selected_item := get_next_selected(null)
	var preview_text := ""
	while selected_item:
		preview_text += selected_item.get_text(0) + "\n"
		selected_item = get_next_selected(selected_item)
	preview.text = preview_text
	set_drag_preview(preview)

	return selected_dict


func get_all_selected_tree_items() -> Dictionary:
	var selected_item := get_next_selected(null)
	var r_dict: Dictionary
	while selected_item:
		var selected_parent := selected_item.get_parent()
		var selected_parent_command: Command = (
			selected_parent.get_meta("command") if selected_parent != get_root() else null
		)
		if r_dict.has(selected_parent_command) == false:
			r_dict[selected_item.get_meta("command")] = {
				"index": selected_item.get_index(), "parent": selected_parent_command
			}
		selected_item = get_next_selected(selected_item)
	return r_dict


func _can_drop_data(position: Vector2, data) -> bool:
	if not data is Dictionary:
		return false
	var to_item := get_item_at_position(position)
	if to_item is TreeItem:
		if to_item.get_meta("command") is ContainerCommand:
			set_drop_mode_flags(DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM)
		else:
			set_drop_mode_flags(DROP_MODE_INBETWEEN)
	return true


func _drop_data(position: Vector2, items) -> void:
	var to_item := get_item_at_position(position)
	var shift := get_drop_section_at_position(position)
	# shift == 0 if dropping on item, -1, +1 if in between
	for i in items:
		if to_item:
			if i == to_item.get_meta("command"):
				return
			if to_item.get_parent() != get_root():
				if i == to_item.get_parent().get_meta("command"):
					return
	moved.emit(items, to_item, shift)


func _on_moved(items: Dictionary, to_item: TreeItem, shift: int) -> void:
	var to_item_command: Command = to_item.get_meta("command") if to_item != null else null
	undo_redo.create_action("drag command")
	undo_redo.add_do_method(self, "move_list_tree_items", items, to_item_command, shift)
	undo_redo.add_undo_method(self, "undo_move_list_tree_items", items)
	undo_redo.commit_action()


func move_list_tree_items(d: Dictionary, to_item_command: Command, shift: int) -> void:
	for item_command in d:
		move_tree_item(item_command, to_item_command, shift)


func undo_move_list_tree_items(t: Dictionary):
	for item_command in t:
		undo_move_tree_item(item_command, t[item_command]["index"], t[item_command]["parent"])


func move_tree_item(
	item_command: Command, to_item_command: Command = null, shift: int = -100
) -> void:
	var item := get_tree_item_from_command(item_command)
	var item_idx := find_tree_item(item)
	var to_item := get_tree_item_from_command(to_item_command)
	var to_item_idx: int = find_tree_item(to_item)
	var to_itme_parent: TreeItem = to_item.get_parent() if to_item != null else get_root()
	var to_item_parent_commands: Array[Command] = (
		current_block.commands
		if to_itme_parent == get_root()
		else to_itme_parent.get_meta("command").container_block.commands
	)

	match shift:
		-1:
			to_item_parent_commands.insert(to_item_idx, item_command)
		0:
			to_item_command.container_block.commands.append(item_command)
		1:
			if to_item_command is ContainerCommand:
				to_item_command.container_block.commands.insert(0, item_command)
			else:
				if to_item_idx + 1 > to_item_parent_commands.size():
					to_item_parent_commands.append(item_command)
				else:
					to_item_parent_commands.insert(to_item_idx + 1, item_command)
		-100:
			to_item_parent_commands.append(item_command)

	if to_item_idx != resault.not_found:
		if shift == -1:
			if item.get_parent() == to_itme_parent:
				if item_idx > to_item_idx:
					item_idx = item_idx + 1

	if item.get_parent() == get_root():
		current_block.commands.remove_at(item_idx)
	else:
		item.get_parent().get_meta("command").container_block.commands.remove_at(item_idx)

	create_tree_from_block(current_block)


func undo_move_tree_item(og_item_command: Command, og_idx: int, og_parent_command: Command):
	var to_item := get_tree_item_from_command(og_item_command)
	var item_idx := find_tree_item(to_item)
	if item_idx == resault.not_found:
		push_error("can't find it")
		return
	var to_item_parent := to_item.get_parent()
	var og_parent_commands: Array[Command] = (
		og_parent_command.container_block.commands
		if og_parent_command != null
		else current_block.commands
	)
	var to_item_parent_command: Command = (
		to_item_parent.get_meta("command") if to_item_parent.has_meta("command") else null
	)

	if to_item == null or to_item_parent == get_root():
		current_block.commands.remove_at(item_idx)
	elif to_item_parent_command is ContainerCommand:
		to_item_parent_command.container_block.commands.remove_at(item_idx)

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
		elif treeitems[i].get_meta("command") is ContainerCommand:
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
		elif t_cmd is ContainerCommand:
			var s := get_tree_item_from_command(command, t)
			if s != null:
				return s
	return null


func create_tree_from_block(block: Block, parent: TreeItem = null) -> void:
	tree_changed.emit(flowchart_tab.flowchart)
	if parent == null:
		self.clear()
	if block.commands == null:
		return
	for i in block.commands:
		var created_item: TreeItem = create_tree_item_from_command(i, -1, parent)
		if i is ContainerCommand:
			create_tree_from_block(i.container_block, created_item)


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
			control = i_say_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, flowchart_tab.flowchart, self)

		"ForkCommand":
			control = i_fork_control.nstantiate()
			commands_settings.add_child(control, true)
			control.set_up(
				current_item, undo_redo, flowchart_tab.flowchart, current_block, graph_edit, self
			)

		"ConditionCommand", "IfElseCommand":
			control = i_condition_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"SetVarCommand":
			control = i_set_var_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item)

		"AnimationCommand":
			control = i_animation_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"JumpCommand":
			control = i_jump_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, flowchart_tab.flowchart, self)

		"SoundCommand":
			control = i_sound_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"ChangeUICommand":
			control = i_change_ui_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"CallFunctionCommand":
			control = i_call_function_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item)

		"SignalCommand":
			control = i_signal_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item)

		"GeneralContainerCommand":
			control = i_general_container_command.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item)

		"ElseCommand", "RandomCommand":
			pass
		_:
			push_error("CommandsTree: Unknow Command ", current_item.get_class())
			return

	var item := get_tree_item_from_command(current_item)
	if item == null:
		return
	set_selected(item, 0)
	ensure_cursor_is_visible()


func command_undo_redo_caller(
	undo_redo_method: StringName, args: Array = [], obj = null, is_condition_container := false
) -> void:
	var object
	if obj != null:
		match obj.get_class():
			"Choice":
				for c in commands_settings.get_child(0).get_children():
					if not c.has_method("get_choice"):
						continue
					if c.get_choice() == obj:
						if is_condition_container == true:
							object = c.cond_box
							break
						else:
							object = c
							break
			"ConditionResource":
				var condition_editors: Array
				if commands_settings.get_child(0).get_command() is ForkCommand:
					for c in commands_settings.get_child(0).get_children():
						if not c.has_method("get_choice"):
							continue
						condition_editors.append_array(c.cond_editors_container.get_children())
				else:
					condition_editors = (
						commands_settings.get_child(0).cond_editors_container.get_children()
					)
				if condition_editors != []:
					for c in condition_editors:
						if not c.has_method("get_conditional"):
							continue
						if c.get_conditional() == obj:
							object = c
							break
			_:
				if is_condition_container == true:
					object = commands_settings.get_child(0).cond_box
				else:
					object = obj
	else:
		object = commands_settings.get_child(0)

	if object:
		if object.has_method(undo_redo_method):
			object.callv(undo_redo_method, args)
