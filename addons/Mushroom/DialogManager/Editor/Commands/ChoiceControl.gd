@tool
extends Control

@export var choice_text: LineEdit
@export var next_block_menu: MenuButton
@export var next_index_text: SpinBox
@export var delete_choice: Button
@export var cond_box: VBoxContainer
@export var sperator: Control
@export var up_button: Button
@export var down_button: Button
@export var select_indicator: PanelContainer
@export var selected_stylebox: StyleBoxFlat

var current_choice: Choice
var flowchart: FlowChart
var undo_redo: EditorUndoRedoManager
var commands_container: Node
var fork: Control

signal change_index


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != 1 and event.button_index != 2:
		return
	if event.is_released() == true:
		return

	if event.shift_pressed == false:
		fork.clear_all_choices_selection()

	fork.select_choice(current_choice)
	select_indicator.add_theme_stylebox_override("panel", selected_stylebox)
	accept_event()


func set_up(c: Choice, fct: FlowChart, u: EditorUndoRedoManager, cmd_c: Node, f: Control) -> void:
	if c.choice_text.is_empty():
		c.choice_text = TranslationServer.get_translation_object("en").get_message(c.tr_code)

	flowchart = fct
	current_choice = c
	choice_text.text = c.choice_text
	undo_redo = u
	commands_container = cmd_c
	fork = f
	if c.next_block != null:
		next_block_menu.text = c.next_block
	next_index_text.value = c.next_index

	cond_box.set_up(current_choice, undo_redo, commands_container)




func clear_choice_selection() -> void:
	select_indicator.remove_theme_stylebox_override("panel")


func _on_delete_choice_pressed() -> void:
	fork.removing_choice_action(current_choice)
	fork.update_block_in_graph(fork.current_block)


func _on_next_index_value_changed(value: float) -> void:
	current_choice.next_index = int(value)
	is_changed()


func _on_next_blocklist_about_to_show() -> void:
	var menu: PopupMenu = next_block_menu.get_popup()
	if not menu.index_pressed.is_connected(change_next_bloc):
		menu.index_pressed.connect(change_next_bloc.bind(menu))
	menu.clear()
	for b in flowchart.blocks:
		menu.add_item(b)


func change_next_bloc(index: int, m: PopupMenu) -> void:
	var next_block_name := m.get_item_text(index)
	var current_next_block_name := current_choice.next_block
	undo_redo.create_action("change next block")
	undo_redo.add_do_method(
		commands_container,
		"command_undo_redo_caller",
		"change_next_block",
		[next_block_name],
		current_choice
	)
	undo_redo.add_undo_method(
		commands_container,
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
	current_choice.choice_text = new_text
	is_changed()


func _on_conditional_changed() -> void:
	if cond_box.cond_editors_container.get_child_count() == 0:
		sperator.custom_minimum_size = Vector2.ZERO
	else:
		sperator.custom_minimum_size = Vector2(0, 10)
	is_changed()


func _on_up_button_pressed() -> void:
	change_index.emit(fork.UP, current_choice)


func _on_down_button_pressed() -> void:
	change_index.emit(fork.DOWN, current_choice)


func get_choice() -> Choice:
	return current_choice


func is_changed() -> void:
	current_choice.changed.emit()
