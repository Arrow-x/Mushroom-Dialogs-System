@tool
extends Control

@export var choice_text: LineEdit
@export var next_block_menu: MenuButton
@export var next_index_text: SpinBox
@export var delete_choice: Button
@export var is_cond: CheckButton
@export var cond_box: VBoxContainer
@export var cond_editors_container: VBoxContainer

var current_choice: Choice
var flowchart: FlowChart
var undo_redo: EditorUndoRedoManager
var commands_tree: Tree
var fork: Control


func set_up(c: Choice, fct: FlowChart, u: EditorUndoRedoManager, cmd_tree: Tree) -> void:
	flowchart = fct
	current_choice = c
	choice_text.text = c.text
	undo_redo = u
	commands_tree = cmd_tree
	if c.next_block != null:
		next_block_menu.text = c.next_block
	next_index_text.value = c.next_index

	cond_box.set_up(current_choice, undo_redo, commands_tree)
	is_cond.set_pressed_no_signal(c.is_cond)
	if is_cond.button_pressed == true:
		cond_box.visible = true


func _on_delete_choice_pressed() -> void:
	fork.removing_choice_action(self)
	fork.update_block_in_graph(fork.current_block)


func _on_next_index_value_changed(value: float) -> void:
	current_choice.next_index = int(value)
	is_changed()


func _on_next_blocklist_about_to_show() -> void:
	var menu: PopupMenu = next_block_menu.get_popup()
	if !menu.index_pressed.is_connected(change_next_bloc):
		menu.index_pressed.connect(change_next_bloc.bind(menu))
	menu.clear()
	for b in flowchart.blocks:
		menu.add_item(b)


func change_next_bloc(index: int, m: PopupMenu) -> void:
	var next_block_name := m.get_item_text(index)
	var current_next_block_name := current_choice.next_block
	undo_redo.create_action("change next block")
	undo_redo.add_do_method(
		commands_tree,
		"command_undo_redo_caller",
		"change_next_block",
		[next_block_name],
		current_choice
	)
	undo_redo.add_undo_method(
		commands_tree,
		"command_undo_redo_caller",
		"change_next_block",
		[current_next_block_name],
		current_choice
	)
	undo_redo.commit_action()


func change_next_block(next_block_name: String = "") -> void:
	current_choice.next_block = next_block_name
	next_block_menu.text = next_block_name
	fork.update_block_in_graph(fork.current_block)


func _on_choicetext_text_changed(new_text: String) -> void:
	current_choice.text = new_text
	is_changed()


func _on_is_cond_checkbox_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle condition")
	undo_redo.add_do_method(
		commands_tree,
		"command_undo_redo_caller",
		"show_condition_toggle",
		[button_pressed],
		current_choice
	)
	undo_redo.add_undo_method(
		commands_tree,
		"command_undo_redo_caller",
		"show_condition_toggle",
		[current_choice.is_cond],
		current_choice
	)
	undo_redo.commit_action()


func show_condition_toggle(button_pressed: bool) -> void:
	is_cond.set_pressed_no_signal(button_pressed)
	cond_box.visible = button_pressed
	current_choice.is_cond = button_pressed
	is_changed()


func get_choice() -> Choice:
	return current_choice


func is_changed() -> void:
	current_choice.changed.emit()
