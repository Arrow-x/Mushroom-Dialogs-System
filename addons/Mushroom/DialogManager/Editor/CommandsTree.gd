@tool
extends Tree

signal moved(item, to_item, shift)
signal tree_changed(flowchart: FlowChart)

enum Resault { SUCCESS = 1, NOT_FOUND = -2 }
enum Copy_or_not { COPY, DONT_COPY }

@export var current_block_label: Label
@export var commands_settings: Container
@export var general_rmb_menu: PopupMenu
@export var icon_x: Texture2D

var flowchart_tab: FlowChartTabs
var current_block: Block
var undo_redo: EditorUndoRedoManager
var graph_edit: GraphEdit

var prev_selected_Command: Command
var prev_selected_Block: Block


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
	if MainEditor.commands_clipboard.is_empty() == false:
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
			push_error("CommandsTree: Unknow key in right menu button")


func on_commands_delete() -> void:
	_on_tree_item_x_button_pressed(get_selected(), 0, 1, 1)


func on_commands_copy() -> void:
	MainEditor.commands_clipboard.clear()
	MainEditor.commands_clipboard = get_selected_tree_items(Copy_or_not.COPY).keys()


func on_commands_cut() -> void:
	var _selected := get_selected_tree_items(Copy_or_not.DONT_COPY)
	MainEditor.commands_clipboard.clear()
	MainEditor.commands_clipboard = _selected.keys()
	undo_redo.create_action("cut commands")
	undo_redo.add_do_method(self, "cut_commands", _selected, flowchart_tab.flowchart)
	undo_redo.add_undo_method(self, "undo_cut_commands", _selected, flowchart_tab.flowchart)
	undo_redo.commit_action()


func on_commands_paste() -> void:
	var sel_idx: int
	var parent: Command

	if get_selected() == null:
		sel_idx = current_block.commands.size()
		parent = null
	else:
		var selected_cmd: Command = get_selected().get_meta("command")
		if selected_cmd is ContainerCommand:
			sel_idx = selected_cmd.container_block.commands.size()
			parent = selected_cmd
		else:
			sel_idx = get_selected().get_index() + 1
			if get_selected().get_parent() != get_root():
				parent = get_selected().get_parent().get_meta("command")
			else:
				parent = null

	var clip: Array = MainEditor.commands_clipboard
	undo_redo.create_action("paste commands")
	undo_redo.add_do_method(self, "paste_commands", clip, sel_idx, flowchart_tab.flowchart, parent)
	undo_redo.add_undo_method(
		self, "undo_paste_commands", clip.size(), sel_idx, flowchart_tab.flowchart, parent
	)
	undo_redo.commit_action()


func paste_commands(paste_array: Array, idx: int, fl: FlowChart, p_cmd: Command) -> void:
	tree_changed.emit(fl)
	for i: int in range(paste_array.size() - 1, -1, -1):
		add_command_to_block(paste_array[i], idx, p_cmd)


func undo_paste_commands(pasted_array_size: int, idx: int, fl: FlowChart, p_cmd: Command) -> void:
	tree_changed.emit(fl)
	for i in pasted_array_size:
		delete_command(idx, get_tree_item_from_command(p_cmd))


func cut_commands(selected: Dictionary, fl: FlowChart) -> void:
	tree_changed.emit(fl)
	var keys := selected.keys()
	for i: int in range(keys.size() - 1, -1, -1):
		delete_command(
			selected[keys[i]]["index"], get_tree_item_from_command(selected[keys[i]]["parent"])
		)


func undo_cut_commands(selected: Dictionary, fl: FlowChart) -> void:
	tree_changed.emit(fl)
	for s: Command in selected:
		add_command_to_block(s, selected[s]["index"], selected[s]["parent"])


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

	undo_redo.create_action("remove a command")
	undo_redo.add_do_method(self, "delete_command", idx, parent)
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
	for i in commands_settings.get_children():
		i.queue_free()


func _on_add_command(id: int, on_item := false, is_rmb := false) -> void:
	var command: Command
	match id:
		0:
			command = SayCommand.new()
		1:
			command = AnimationCommand.new()
		2:
			command = ForkCommand.new()
		3:
			command = ConditionCommand.new()
		4:
			command = ElseCommand.new()
		5:
			command = IfElseCommand.new()
		6:
			command = SoundCommand.new()
		7:
			command = ChangeUICommand.new()
		8:
			command = CallFunctionCommand.new()
		9:
			command = SignalCommand.new()
		10:
			command = GeneralContainerCommand.new()
		11:
			command = JumpCommand.new()
		12:
			command = SetVarCommand.new()
		13:
			command = RandomCommand.new()
		14:
			command = ShowMediaCommand.new()

	var idx: int = -1
	var parent_cmd: Command = null

	if is_rmb and on_item:
		var ret := on_rmb_find_parent_and_idx()
		idx = ret["idx"]
		parent_cmd = ret["parent_cmd"]

	undo_redo.create_action("Added Command")
	undo_redo.add_do_method(self, "add_command_to_block", command, idx, parent_cmd)
	undo_redo.add_undo_method(self, "delete_command", idx)
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
	elif command is ContainerCommand:
		for c: Command in command.container_block.commands:
			if c is ForkCommand:
				current_block.outputs.append(c)
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


func delete_command(index: int, parent_treeitem: TreeItem = null) -> void:
	var items_array: Array
	var del_block: Block

	if parent_treeitem:
		items_array = parent_treeitem.get_children()
		del_block = parent_treeitem.get_meta("command").container_block
	else:
		items_array = get_root().get_children()
		del_block = current_block

	var command: Command = del_block.commands[index]

	if command is ForkCommand:
		graph_edit.delete_output(current_block.name, command)

	elif command is ContainerCommand:
		for c: Command in command.container_block.commands:
			if c is ForkCommand:
				graph_edit.delete_output(current_block.name, c)

	items_array[index].free()
	if "tr_code" in command:
		TranslationServer.get_translation_object("en").erase_message(command.tr_code)
	if index == -1:
		del_block.commands.remove_at(del_block.commands.size() - 1)
	else:
		del_block.commands.remove_at(index)
	free_Command_editor()


func free_Command_editor() -> void:
	for c_s in commands_settings.get_children():
		c_s.queue_free()


func _get_drag_data(_position: Vector2):
	if get_selected() == null:
		return
	var selected_dict := get_selected_tree_items(Copy_or_not.DONT_COPY)

	var preview := Label.new()
	var selected_item := get_next_selected(null)
	var preview_text := ""
	while selected_item:
		preview_text += selected_item.get_text(0) + "\n"
		selected_item = get_next_selected(selected_item)
	preview.text = preview_text
	set_drag_preview(preview)

	return selected_dict


func get_selected_tree_items(c: Copy_or_not) -> Dictionary:
	var selected_item := get_next_selected(null)
	var selected_item_meta: Command = selected_item.get_meta("command")
	var r_dict: Dictionary
	var copy: Command
	while selected_item:
		var selected_parent := selected_item.get_parent()
		var selected_parent_command: Command = (
			selected_parent.get_meta("command") if selected_parent != get_root() else null
		)
		if r_dict.has(selected_parent_command) == false:
			if c == Copy_or_not.COPY:
				copy = flowchart_tab.deep_duplicate_command(selected_item_meta)
				r_dict[copy] = {
					"index": selected_item.get_index(), "parent": selected_parent_command
				}
			elif c == Copy_or_not.DONT_COPY:
				r_dict[selected_item_meta] = {
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


func undo_move_list_tree_items(t: Dictionary) -> void:
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
	if prev_selected_Block != null:
		if current_block != prev_selected_Block:
			prev_selected_Block = null
	undo_redo.create_action("selecting a command")
	undo_redo.add_do_method(self, "create_command_editor", sel_c)
	undo_redo.add_undo_method(self, "create_command_editor", prev_selected_Command)
	undo_redo.commit_action()
	prev_selected_Command = sel_c
	prev_selected_Block = current_block


func create_command_editor(current_item = null) -> void:
	# NOTE: typing current_item as Command will run get_class() on it and not on any
	# of the inhearted types

	deselect_all()

	if current_item == null:
		return

	free_Command_editor()

	if !current_item.changed.is_connected(update_command_preview):
		current_item.changed.connect(update_command_preview)

	commands_settings.add_command_editor(
		current_item, flowchart_tab.flowchart, current_block, undo_redo
	)

	var item := get_tree_item_from_command(current_item)
	if item == null:
		return
	set_selected(item, 0)
	ensure_cursor_is_visible()
