@tool
extends Tree

signal moved(item, to_item, shift)
signal tree_changed(flowchart: FlowChart)

enum Resault { SUCCESS = 1, NOT_FOUND = -2 }

@export var current_block_label: Label
@export var commands_settings: Container
@export var general_rmb_menu: PopupMenu

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
@export var i_show_media_control: PackedScene

@export var icon_x: Texture2D

var flowchart_tab: FlowChartTabs
var current_block: Block
var undo_redo: EditorUndoRedoManager
var graph_edit: GraphEdit

var prev_selected_Command: Command


func _ready() -> void:
	button_clicked.connect(_on_tree_item_x_button_pressed)
	general_rmb_menu.add_index_pressed.connect(_on_add_command.bind(true))
	general_rmb_menu.index_pressed.connect(_rmb_menu_index_pressed)
	item_activated.connect(_on_tree_item_double_clicked)
	item_mouse_selected.connect(
		func(pos: Vector2, m_flag: int): _on_tree_item_rmb_selected(pos, m_flag, true)
	)
	item_collapsed.connect(
		func(item: TreeItem) -> void: item.get_meta("command").collapse = item.is_collapsed()
	)
	gui_input.connect(genaric_right_click)
	moved.connect(_on_moved)


func genaric_right_click(input: InputEvent) -> void:
	if current_block == null:
		return
	if input is InputEventMouseButton:
		_on_tree_item_rmb_selected(input.position, input.button_index, false)


func _on_tree_item_rmb_selected(_position: Vector2, mouse_button_index: int, is_item: bool) -> void:
	if mouse_button_index != 2:
		return
	var paste := false
	if flowchart_tab.main_editor.commands_clipboard.is_empty() == false:
		paste = true
	general_rmb_menu.set_up(paste, is_item)
	var gmp := get_global_mouse_position()
	general_rmb_menu.popup(Rect2(gmp.x, gmp.y, 0, 0))


func _rmb_menu_index_pressed(idx: int) -> void:
	match general_rmb_menu.get_item_text(idx):
		"Delete":
			on_commands_delete()
		"Copy":
			on_commands_copy()
		"Cut":
			on_commands_cut()
		"Paste":
			on_commands_paste()
		_:
			push_error("Unknow key in right menu button")


func on_commands_delete() -> void:
	_on_tree_item_x_button_pressed(get_selected(), 0, 1, 1)


func on_commands_copy() -> void:
	flowchart_tab.main_editor.commands_clipboard.clear()
	flowchart_tab.main_editor.commands_clipboard = get_selected_tree_items_copy()


func on_commands_cut() -> void:
	var selected_copies := get_selected_tree_items(true)
	flowchart_tab.main_editor.commands_clipboard.clear()
	flowchart_tab.main_editor.commands_clipboard = get_selected_tree_items_copy()
	undo_redo.create_action("cut commands")
	undo_redo.add_do_method(self, "cut_commands", selected_copies, flowchart_tab.flowchart)
	undo_redo.add_undo_method(self, "undo_cut_commands", selected_copies, flowchart_tab.flowchart)
	undo_redo.commit_action()


func on_commands_paste() -> void:
	var sel_idx: int
	var cmds: Array
	if get_selected() == null:
		cmds = current_block.commands
		sel_idx = cmds.size()
	else:
		var selected_cmd: Command = get_selected().get_meta("command")
		if selected_cmd is ContainerCommand:
			cmds = selected_cmd.container_block.commands
			sel_idx = cmds.size()
		else:
			sel_idx = get_selected().get_index() + 1
			var parent = get_selected().get_parent()
			if parent == get_root() or parent == null:
				cmds = current_block.commands
			else:
				cmds = (get_selected().get_parent().get_meta("command").container_block.commands)
	var clip: Array = flowchart_tab.deep_duplicate_commands(
		flowchart_tab.main_editor.commands_clipboard
	)
	undo_redo.create_action("paste commands")
	undo_redo.add_do_method(self, "paste_commands", cmds, clip, sel_idx, flowchart_tab.flowchart)
	undo_redo.add_undo_method(
		self, "undo_paste_commands", sel_idx, clip.size(), cmds, flowchart_tab.flowchart
	)
	undo_redo.commit_action()


func paste_commands(to_array: Array, paste_array: Array, idx: int, fl: FlowChart) -> void:
	tree_changed.emit(fl)
	for i in range(paste_array.size() - 1, -1, -1):
		to_array.insert(idx, paste_array[i])
	create_tree_from_block(current_block)


func undo_paste_commands(input_idx: int, paste_count: int, pasted: Array, fl: FlowChart) -> void:
	tree_changed.emit(fl)
	for i in range(paste_count + input_idx - 1, input_idx - 1, -1):
		pasted.remove_at(i)
	create_tree_from_block(current_block)


func cut_commands(selected: Dictionary, fl: FlowChart) -> void:
	tree_changed.emit(fl)
	var keys := selected.keys()
	for i in range(keys.size() - 1, -1, -1):
		var cmds: Array = (
			selected[keys[i]]["parent"].container_block.commands
			if selected[keys[i]]["parent"] != null
			else current_block.commands
		)
		cmds.remove_at(selected[keys[i]]["index"])
	create_tree_from_block(current_block)


func undo_cut_commands(selected: Dictionary, fl: FlowChart) -> void:
	tree_changed.emit(fl)
	for s: Command in selected:
		var cmds: Array = (
			selected[s]["parent"].container_block.commands
			if selected[s]["parent"] != null
			else current_block.commands
		)
		cmds.insert(selected[s]["index"], s)
	create_tree_from_block(current_block)


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
	if meta == null:
		return
	if meta == current_block:
		current_block_label.set_text(meta.name)
		return
	full_clear()
	current_block_label.set_text(meta.name)
	current_block = meta

	for c in commands_settings.get_children():
		c.queue_free()

	create_tree_from_block(meta)


func full_clear() -> void:
	self.clear()
	current_block = null
	current_block_label.text = ""


func _on_add_command(id: int, pop_up: Popup, on_item := false, is_rmb := false) -> void:
	if current_block == null:
		push_error("CommandsTree: there is no block selected")
		return

	var command: Command = pop_up.get_item_metadata(id).duplicate()

	var idx: int = -1
	var parent_cmd: Command = null

	if is_rmb and on_item:
		var ret := on_rmb_find_parent_and_idx()
		idx = ret["idx"]
		parent_cmd = ret["parent_cmd"]

	undo_redo.create_action("Added Command")
	undo_redo.add_do_method(self, "add_command_to_block", command, idx, parent_cmd)
	undo_redo.add_undo_method(self, "delete_command", command)
	undo_redo.commit_action()


func on_rmb_find_parent_and_idx() -> Dictionary:
	var ret_dic = {"parent_cmd": null, "idx": -1}
	if get_selected() == null:
		return ret_dic

	var selected_item_cmd: Command = get_selected().get_meta("command")
	if selected_item_cmd is ContainerCommand:
		ret_dic["parent_cmd"] = selected_item_cmd
	else:
		var selected_parent := get_selected().get_parent()
		if selected_parent != get_root():
			ret_dic["idx"] = (
				selected_parent.get_meta("command").container_block.commands.find(selected_item_cmd)
				+ 1
			)
			ret_dic["parent_cmd "] = selected_parent.get_meta("command")
			return ret_dic
		ret_dic["idx"] = find_tree_item(get_selected()) + 1
	return ret_dic


func add_command_to_block(command: Command, idx: int = -1, parent: Command = null) -> void:
	if parent == null:
		var cbc: Array = current_block.commands
		if idx == -1:
			cbc.append(command)
		else:
			cbc.insert(idx, command)
	elif parent is ContainerCommand:
		var pbc: Array = parent.container_block.commands
		if idx == -1:
			pbc.append(command)
		else:
			pbc.insert(idx, command)
	if command is ForkCommand:
		current_block.outputs.append(command)
	create_tree_from_block(current_block)
	graph_edit.connect_block_outputs(current_block, true)


func create_tree_item_from_command(
	command: Command, idx: int = -1, in_parent: TreeItem = null
) -> TreeItem:
	var parent := in_parent
	if get_root() == null:
		parent = self.create_item()
		self.set_hide_root(true)

	var item: TreeItem = self.create_item(parent, idx)
	item.set_text(0, command.preview())
	item.set_icon(0, command.get_icon())
	item.set_meta("command", command)
	item.add_button(0, icon_x)
	command.tree_item = item
	if command is ContainerCommand:
		item.set_collapsed(command.collapse)
	if command is ElseCommand or command is IfElseCommand:
		var parent_children := (
			parent.get_children() if parent != null else get_root().get_children()
		)
		var create_idx := parent_children.size() - 2 if idx == -1 else idx - 1
		var created_cmd: Command = parent_children[create_idx].get_meta("command")
		if not created_cmd is IfCommand or create_idx == -1:
			item.set_custom_color(0, Color.RED)

	tree_changed.emit(flowchart_tab.flowchart)
	return item


func delete_command(command: Command, tree: TreeItem = null) -> int:
	var del_tree: Array
	var del_block: Block
	if command is ForkCommand:
		graph_edit.delete_output(current_block.name, command)

	if tree:
		del_tree = tree.get_children()
		del_block = tree.get_meta("command").container_block
	else:
		del_tree = get_root().get_children()
		del_block = current_block
	for t_idx in del_tree.size():
		var d_t: TreeItem = del_tree[t_idx]
		if d_t.get_meta("command") == command:
			d_t.free()
			del_block.commands.remove_at(t_idx)
			free_Command_editor(command)
			create_tree_from_block(current_block)
			return Resault.SUCCESS
		if d_t.get_meta("command") is ContainerCommand:
			var err := delete_command(command, d_t)
			if err != Resault.NOT_FOUND:
				free_Command_editor(command)
				create_tree_from_block(current_block)
				return Resault.SUCCESS
	return Resault.NOT_FOUND


func free_Command_editor(command: Command) -> void:
	for c_s in commands_settings.get_children():
		if c_s.get_command() == command:
			c_s.queue_free()


func _get_drag_data(_position: Vector2):
	if get_selected() == null:
		return
	var selected_dict := get_selected_tree_items(false)

	var preview := Label.new()
	var selected_item := get_next_selected(null)
	var preview_text := ""
	while selected_item:
		preview_text += selected_item.get_text(0) + "\n"
		selected_item = get_next_selected(selected_item)
	preview.text = preview_text
	set_drag_preview(preview)

	return selected_dict


func get_selected_tree_items_copy() -> Array:
	var selected_item := get_next_selected(null)
	var copies_array: Array
	while selected_item:
		var selected_parent := selected_item.get_parent()
		var selected_parent_command: Command = (
			selected_parent.get_meta("command") if selected_parent != get_root() else null
		)
		if copies_array.has(selected_parent_command) == false:
			copies_array.append(selected_item.get_meta("command").duplicate())
		selected_item = get_next_selected(selected_item)
	return copies_array


func get_selected_tree_items(copy: bool) -> Dictionary:
	var selected_item := get_next_selected(null)
	var r_dict: Dictionary
	while selected_item:
		var selected_parent := selected_item.get_parent()
		var selected_parent_command: Command = (
			selected_parent.get_meta("command") if selected_parent != get_root() else null
		)
		if r_dict.has(selected_parent_command) == false:
			if copy == true:
				r_dict[selected_item.get_meta("command").duplicate()] = {
					"index": selected_item.get_index(), "parent": selected_parent_command
				}
			else:
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
	var t_keys := t.keys()
	for i in range(t_keys.size() - 1, -1, -1):
		undo_move_tree_item_delete(t_keys[i])
	for item_command in t:
		undo_move_tree_item_insert(
			item_command, t[item_command]["index"], t[item_command]["parent"]
		)
	create_tree_from_block(current_block)


func move_tree_item(
	item_command: Command, to_item_command: Command = null, shift: int = -100
) -> void:
	var item := get_tree_item_from_command(item_command)
	var item_idx := find_tree_item(item)
	var to_item := get_tree_item_from_command(to_item_command)
	var to_item_idx: int = find_tree_item(to_item)
	var to_itme_parent: TreeItem = to_item.get_parent() if to_item != null else get_root()
	var to_item_parent_commands: Array = (
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

	if to_item_idx != Resault.NOT_FOUND:
		if shift == -1:
			if item.get_parent() == to_itme_parent:
				if item_idx > to_item_idx:
					item_idx = item_idx + 1

	if item.get_parent() == get_root():
		current_block.commands.remove_at(item_idx)
	else:
		item.get_parent().get_meta("command").container_block.commands.remove_at(item_idx)

	create_tree_from_block(current_block)


func undo_move_tree_item_delete(og_item_command: Command):
	var to_item := get_tree_item_from_command(og_item_command)
	if to_item == null:
		push_error("CommandsTree: ", og_item_command, "is not in this tree")
		return
	var item_idx := find_tree_item(to_item)
	if item_idx == Resault.NOT_FOUND:
		push_error("CommandsTree: can't find it")
		return
	var to_item_parent := to_item.get_parent()
	var to_item_parent_command: Command = (
		to_item_parent.get_meta("command") if to_item_parent.has_meta("command") else null
	)

	if to_item_parent_command != null:
		to_item_parent_command.container_block.commands.remove_at(item_idx)
	else:
		current_block.commands.remove_at(item_idx)


func undo_move_tree_item_insert(
	og_item_command: Command, og_idx: int, og_parent_command: Command
) -> void:
	var og_parent_commands: Array = (
		og_parent_command.container_block.commands
		if og_parent_command != null
		else current_block.commands
	)
	var err := og_parent_commands.insert(og_idx, og_item_command)
	if err != OK:
		push_error(
			"CommandsTree: can't insert: ",
			og_parent_command,
			"at: ",
			og_idx,
			"on: ",
			og_parent_commands
		)


func find_tree_item(item: TreeItem) -> int:
	if item != null:
		return item.get_index()
	return Resault.NOT_FOUND


func get_tree_item_from_command(command: Command) -> TreeItem:
	if command != null:
		return command.tree_item
	return null


func create_tree_from_block(block: Block, parent: TreeItem = null) -> void:
	if parent == null:
		self.clear()
	if block.commands == null:
		return
	for i in block.commands:
		var created_item: TreeItem = create_tree_item_from_command(i, -1, parent)
		if i is ContainerCommand:
			create_tree_from_block(i.container_block, created_item)

	tree_changed.emit(flowchart_tab.flowchart)


func update_command_preview(cmd: Command) -> void:
	cmd.tree_item.set_text(0, cmd.preview())
	tree_changed.emit(flowchart_tab.flowchart)


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

	if !current_item.changed.is_connected(update_command_preview):
		current_item.changed.connect(update_command_preview)

	for c in commands_settings.get_children():
		c.queue_free()
	var control: Control
	match current_item.get_class():
		"SayCommand":
			control = i_say_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, flowchart_tab.flowchart, self)

		"ForkCommand":
			control = i_fork_control.instantiate()
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

		"ShowMediaCommand":
			control = i_show_media_control.instantiate()
			commands_settings.add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		_:
			push_error("CommandsTree: Unknow Command ", current_item.get_class())
			return

	var item := get_tree_item_from_command(current_item)
	if item == null:
		return
	set_selected(item, 0)
	ensure_cursor_is_visible()


func command_undo_redo_caller(
	undo_redo_method: StringName,
	args: Array = [],
	input_obj = null,
	is_condition_container := false
) -> void:
	var current_ed: Control = commands_settings.get_child(0)
	var object

	if input_obj is Choice:
		for c in current_ed.get_children():
			if not c.has_method("get_choice"):
				continue
			if c.get_choice() != input_obj:
				continue
			if is_condition_container == true:
				object = c.cond_box
				break
			object = c
			break
	elif input_obj is ConditionResource:
		var condition_editors: Array = []
		if current_ed.get_command() is ForkCommand:
			for c in current_ed.get_children():
				if not c.has_method("get_choice"):
					continue
				condition_editors.append_array(c.cond_editors_container.get_children())
		else:
			condition_editors = current_ed.cond_editors_container.get_children()

		for c in condition_editors:
			if not c.has_method("get_conditional"):
				continue
			if c.get_conditional() != input_obj:
				continue
			object = c
			break
	else:
		object = current_ed.cond_box if is_condition_container == true else current_ed

	if object == null:
		push_error("Can't find the calling object")
		return
	if not object.has_method(undo_redo_method):
		push_error(object, " doesn't have ", undo_redo_method)
		return

	object.callv(undo_redo_method, args)
