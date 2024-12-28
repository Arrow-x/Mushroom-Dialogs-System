@tool
extends Control

@export var i_choice_control: PackedScene
@export var choices_container: VBoxContainer
@export var choices_scroll_bar: ScrollContainer
@export var right_click_menu: PopupMenu

var current_fork: ForkCommand
var current_block: Block
var flowchart: FlowChart
var undo_redo: EditorUndoRedoManager
var graph: GraphEdit
var commands_container: Node
var choices_selection_clipboard: Dictionary

signal adding_choice
enum { UP, DOWN }


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index == 2:
		create_right_click_menu()
		accept_event()
		return
	if event.button_index != 1:
		return
	if event.is_released() == true:
		return

	clear_all_choices_selection()
	accept_event()


func create_right_click_menu() -> void:
	right_click_menu.clear()
	if !choices_selection_clipboard.is_empty():
		right_click_menu.add_item("Copy")
		right_click_menu.add_item("Cut")
	if !MainEditor.choices_clipboard.is_empty():
		right_click_menu.add_item("Paste")
	if !choices_selection_clipboard.is_empty():
		right_click_menu.add_item("Delete")
	var gmp := get_global_mouse_position()
	right_click_menu.popup(Rect2(gmp.x, gmp.y, 0, 0))


func select_choice(choice: Choice) -> void:
	choices_selection_clipboard[choice] = {
		"index": current_fork.choices.find(choice), "parent": current_fork
	}


func clear_all_choices_selection() -> void:
	choices_selection_clipboard.clear()
	for c in choices_container.get_children():
		c.clear_choice_selection()


func set_up(
	f: ForkCommand, ur: EditorUndoRedoManager, fc: FlowChart, cb: Block, ge: GraphEdit, cmd_c: Node
) -> void:
	current_fork = f
	flowchart = fc
	graph = ge
	current_block = cb
	undo_redo = ur
	commands_container = cmd_c

	current_fork.origin_block_name = current_block.name
	right_click_menu.index_pressed.connect(_on_right_click_menu_item_clicked.bind(right_click_menu))
	create_choices()


func _on_right_click_menu_item_clicked(id: int, right_click_menu: PopupMenu) -> void:
	match right_click_menu.get_item_text(id):
		"Copy":
			MainEditor.choices_clipboard = choices_selection_clipboard

		"Cut":
			_on_cutting_choices(choices_selection_clipboard)

		"Paste":
			_on_pasting_choices()

		"Delete":
			removing_choice_action(choices_selection_clipboard.keys())

		_:
			push_error("Choice Editor: Unknow key in right menu button")


func _on_cutting_choices(choices: Dictionary) -> void:
	undo_redo.create_action("Cut Choice(s)")
	undo_redo.add_do_method(
		commands_container, "command_undo_redo_caller", "cut_choices", [choices]
	)
	undo_redo.add_undo_method(
		commands_container,
		"command_undo_redo_caller",
		"undo_cut_choices",
		[MainEditor.choices_clipboard]
	)
	undo_redo.commit_action()


func cut_choices(choices: Dictionary) -> void:
	MainEditor.choices_clipboard = choices
	for c in MainEditor.choices_clipboard:
		if current_fork.choices.has(c):
			current_fork.choices.erase(c)
			TranslationServer.get_translation_object("en").erase_message(c.tr_code)
	create_choices()


func undo_cut_choices(clipboard: Dictionary) -> void:
	if clipboard.is_empty():
		push_error("the choices clipboard is empty")
		return

	for c: Choice in clipboard:
		if clipboard[c].is_empty():
			push_error("the choices clipboard has copied items")
			return

	var idx: int
	for cc: Choice in clipboard:
		idx = clipboard[cc]["index"]
		if current_fork.choices.size() < idx + 1:
			current_fork.choices.resize(idx)

		current_fork.choices.insert(idx, cc)
	create_choices()


func _on_pasting_choices() -> void:
	var new_clip: Dictionary
	var new_choice: Choice
	for c in MainEditor.choices_clipboard:
		new_choice = Choice.new()
		new_choice.next_block = c.next_block
		new_choice.next_index = c.next_index
		new_choice.choice_text = c.choice_text
		new_choice.conditionals = FlowChartTabs.duplicate_array(c.conditionals)
		new_clip[new_choice] = {}

	undo_redo.create_action("Pasting choice(s)")
	undo_redo.add_do_method(
		commands_container, "command_undo_redo_caller", "paste_choices", [new_clip]
	)
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "undo_paste_choices", [new_clip]
	)
	undo_redo.commit_action()


func paste_choices(clip: Dictionary) -> void:
	var idx: int = -1
	if not choices_selection_clipboard.is_empty():
		for c in choices_selection_clipboard:
			if choices_selection_clipboard[c].index > idx:
				idx = choices_selection_clipboard[c].index

	for c in clip:
		if idx == -1:
			current_fork.choices.append(c)
		elif idx + 1 < current_fork.choices.size():
			current_fork.choices.insert(idx + 1, c)
		else:
			current_fork.choices.append(c)

		idx += 1
	create_choices()


func undo_paste_choices(clip: Dictionary) -> void:
	for c in clip:
		current_fork.choices.erase(c)
		TranslationServer.get_translation_object("en").erase_message(c.tr_code)
	create_choices()


func _on_add_choice_button_pressed() -> void:
	var new_choice := Choice.new()
	undo_redo.create_action("Adding a new Choice")
	undo_redo.add_do_method(
		commands_container, "command_undo_redo_caller", "add_choice_resource", [new_choice]
	)
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "free_choice_control", [new_choice]
	)
	undo_redo.commit_action()


func removing_choice_action(choices: Array) -> void:
	var idxs: Array[int]
	for c: Choice in choices:
		idxs.append(choices.find(c))
	assert(
		idxs.size() == choices.size(), "the choice array is not alligned witht the indexes array"
	)

	undo_redo.create_action("Removing Choice(s)")
	undo_redo.add_do_method(
		commands_container, "command_undo_redo_caller", "free_choice_controls", [choices]
	)
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "undo_free_choice_controls", [choices, idxs]
	)
	undo_redo.commit_action()


func free_choice_controls(choices: Array) -> void:
	for c: Choice in choices:
		free_choice_control(c)


func undo_free_choice_controls(choices: Array, idxs: Array) -> void:
	for i: int in choices.size():
		add_choice_resource(choices[i], idxs[i])


func create_choice_control(choice: Choice) -> Control:
	var choice_control: Control = i_choice_control.instantiate()

	choices_container.add_child(choice_control)

	choice_control.set_up(choice, flowchart, undo_redo, commands_container, self)
	choice_control.change_index.connect(_on_change_index)
	if !choice.changed.is_connected(is_changed):
		choice.changed.connect(is_changed)
	return choice_control


func create_choices() -> void:
	for c in choices_container.get_children():
		choices_container.remove_child(c)
		c.queue_free()

	if current_fork.choices.is_empty():
		return

	var choice_control: Control = create_choice_control(current_fork.choices.front())
	choice_control.up_button.disabled = true
	for i: int in range(1, current_fork.choices.size()):
		choice_control = create_choice_control(current_fork.choices[i])
	choice_control.down_button.disabled = true


func add_choice_resource(choice: Choice, idx: int = -1) -> void:
	if idx == -1:
		current_fork.choices.append(choice)
	else:
		current_fork.choices.insert(idx, choice)
	create_choices()

	await get_tree().process_frame
	choices_scroll_bar.set_deferred(
		"scroll_vertical", choices_scroll_bar.get_v_scroll_bar().max_value
	)

	update_block_in_graph(current_block)


func free_choice_control(choice: Choice) -> void:
	current_fork.choices.erase(choice)
	TranslationServer.get_translation_object("en").erase_message(choice.tr_code)
	create_choices()
	update_block_in_graph(current_block)


func update_block_in_graph(sender: Block) -> void:
	graph.update_block_flow(sender, current_fork, true)
	is_changed()


func _on_change_index(dir: int, choice: Choice) -> void:
	var idx: int = current_fork.choices.find(choice)
	undo_redo.create_action("Change Choice order")
	undo_redo.add_do_method(
		commands_container,
		"command_undo_redo_caller",
		"change_choice_index",
		[dir, idx],
		current_fork
	)
	undo_redo.add_undo_method(
		commands_container,
		"command_undo_redo_caller",
		"change_choice_index",
		[dir, idx],
		current_fork
	)
	undo_redo.commit_action()


func change_choice_index(dir: int, idx: int) -> void:
	var choice: Choice = current_fork.choices[idx]
	if choice == null:
		push_error("couldn't find Choice")
		return
	if idx == -1:
		push_error("couldn't find Choice")
		return

	if dir == UP:
		if idx == 0:
			return
		if current_fork.choices.insert(idx - 1, choice) == OK:
			current_fork.choices.remove_at(idx + 1)
		else:
			push_error("couldn't insert at indx", idx - 1, "in Array", current_fork.choices)
			return

	elif dir == DOWN:
		if idx == current_fork.choices.size() - 1:
			return
		if current_fork.choices.insert(idx + 2, choice) == OK:
			current_fork.choices.remove_at(idx)
		else:
			push_error("couldn't insert at indx", idx + 2, "in Array", current_fork.choices)
			return
	create_choices()


func get_command() -> Command:
	return current_fork


func is_changed() -> void:
	current_fork.changed.emit(current_fork)
