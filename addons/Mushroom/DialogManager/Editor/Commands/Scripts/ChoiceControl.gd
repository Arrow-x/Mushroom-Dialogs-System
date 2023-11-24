@tool
extends Control

@export var choice_text: LineEdit
@export var next_block_menu: MenuButton
@export var next_index_text: SpinBox
@export var delete_choice: Button
@export var is_cond: CheckButton
@export var cond_box: VBoxContainer
@export var req_node: LineEdit
@export var req_var: LineEdit
@export var req_val: LineEdit
@export var check_type: MenuButton

var current_choice: Choice
var flowchart: FlowChart
var undo_redo: EditorUndoRedoManager

signal conncting
signal removing_choice


func set_up(c: Choice, fct: FlowChart, u: EditorUndoRedoManager) -> void:
	flowchart = fct
	current_choice = c
	choice_text.text = c.text
	undo_redo = u
	if c.next_block != null:
		next_block_menu.text = c.next_block
	next_index_text.value = c.next_index

	var check_type_popup: PopupMenu = check_type.get_popup()
	check_type_popup.id_pressed.connect(_on_checktype_popup.bind(check_type_popup))

	is_cond.set_pressed_no_signal(c.is_cond)
	req_node.text = c.required_node
	req_var.text = c.required_var
	req_val.text = c.check_val
	check_type.text = c.condition_type


func _on_delete_choice_pressed() -> void:
	removing_choice.emit(self)
	conncting.emit()


func _on_next_index_value_changed(value: float) -> void:
	current_choice.next_index = int(value)
	conncting.emit()


func _on_next_blocklist_about_to_show() -> void:
	var menu: PopupMenu = next_block_menu.get_popup()
	if !menu.index_pressed.is_connected(change_next_bloc):
		menu.index_pressed.connect(change_next_bloc.bind(menu))
	menu.clear()
	for b in flowchart.blocks:
		menu.add_item(b)


func change_next_bloc(index, m: PopupMenu) -> void:
	var n_block_name := m.get_item_text(index)
	var p_block_name := current_choice.next_block
	undo_redo.create_action("change next block")
	undo_redo.add_do_method(self, "do_change_next_block", n_block_name)
	undo_redo.add_undo_method(self, "do_change_next_block", p_block_name)
	undo_redo.commit_action()


func do_change_next_block(next_block_name: String = "") -> void:
	current_choice.next_block = next_block_name
	next_block_menu.text = next_block_name
	conncting.emit()


func _on_checktype_popup(id: int, popup: PopupMenu) -> void:
	var pp_text: String = popup.get_item_text(id)
	current_choice.condition_type = pp_text
	check_type.text = pp_text
	conncting.emit()


func _on_choicetext_text_changed(new_text: String) -> void:
	current_choice.text = new_text
	conncting.emit()


func _on_check_val_input_text_changed(new_text: String) -> void:
	current_choice.check_val = new_text
	conncting.emit()


func _on_req_var_input_text_changed(new_text: String) -> void:
	current_choice.required_var = new_text
	conncting.emit()


func _on_req_node_input_text_changed(new_text: String) -> void:
	current_choice.required_node = new_text
	conncting.emit()


func _on_is_cond_checkbox_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle condition")
	undo_redo.add_do_method(self, "show_condition_toggle", button_pressed)
	undo_redo.add_undo_method(self, "show_condition_toggle", current_choice.is_cond)
	undo_redo.commit_action()


func show_condition_toggle(button_pressed: bool) -> void:
	is_cond.set_pressed_no_signal(button_pressed)
	cond_box.visible = button_pressed
	current_choice.is_cond = button_pressed
	conncting.emit()


func get_choice() -> Choice:
	return current_choice
