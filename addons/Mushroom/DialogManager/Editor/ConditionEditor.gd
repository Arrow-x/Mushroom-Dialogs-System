@tool
extends Control

@export var sequencer_check: CheckButton
@export var check_operation: MenuButton
@export var req_node: LineEdit
@export var req_var: LineEdit
@export var is_prop: CheckButton
@export var args_inputs: LineEdit
@export var req_val: LineEdit
@export var val_or_return_label: Label
@export var up_button: Button
@export var down_button: Button
@export var select_indicator: Container
@export var selected_stylebox: StyleBoxFlat

var current_conditional: ConditionResource
var undo_redo: EditorUndoRedoManager
var commands_container: Node
var current_command
var conditionals_container: Control


enum {
	UP,
	DOWN,
}

signal close_pressed
signal change_index


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != 1 and event.button_index != 2:
		return
	if event.is_released() == true:
		return

	if event.shift_pressed == false:
		conditionals_container.clear_all_conditionals_selection()

	conditionals_container.select_conditional(current_conditional)

	select_indicator.add_theme_stylebox_override("panel", selected_stylebox)
	accept_event()


func clear_conditional_selection() -> void:
	select_indicator.remove_theme_stylebox_override("panel")


func set_up(c_cmd, conditional: ConditionResource, u_r: EditorUndoRedoManager, cmd_c: Node, cc: Control) -> void:
	current_conditional = conditional
	undo_redo = u_r
	commands_container = cmd_c
	current_command = c_cmd
	conditionals_container = cc

	var check_op_popup: PopupMenu = check_operation.get_popup()
	check_op_popup.id_pressed.connect(_on_check_operation_popup.bind(check_op_popup))

	req_node.text = conditional.required_node
	req_var.text = conditional.required_var
	req_val.text = conditional.check_val
	check_operation.text = conditional.condition_type
	args_inputs.text = conditional.args
	toggle_sequencer(conditional.is_and)
	toggle_is_prop(conditional.is_property)


func _on_check_button_toggled(toggled_on: bool) -> void:
	undo_redo.create_action("toggle sequencer")
	undo_redo.add_do_method(
		commands_container,
		"command_undo_redo_caller",
		"toggle_sequencer",
		[toggled_on],
		current_conditional
	)
	undo_redo.add_undo_method(
		commands_container,
		"command_undo_redo_caller",
		"toggle_sequencer",
		[current_conditional.is_and],
		current_conditional
	)
	undo_redo.commit_action()
	is_changed()


func toggle_sequencer(toggled_on: bool) -> void:
	sequencer_check.set_pressed_no_signal(toggled_on)
	current_conditional.is_and = toggled_on
	if toggled_on == true:
		sequencer_check.text = "and"
	else:
		sequencer_check.text = "or"


func _on_is_property_toggled(toggled_on: bool) -> void:
	undo_redo.create_action("toggle Property or Function")
	undo_redo.add_do_method(
		commands_container,
		"command_undo_redo_caller",
		"toggle_is_prop",
		[toggled_on],
		current_conditional
	)
	undo_redo.add_undo_method(
		commands_container,
		"command_undo_redo_caller",
		"toggle_is_prop",
		[current_conditional.is_and],
		current_conditional
	)
	undo_redo.commit_action()
	is_changed()


func toggle_is_prop(toggled_on: bool) -> void:
	is_prop.set_pressed_no_signal(toggled_on)
	current_conditional.is_property = toggled_on
	if toggled_on == true:
		is_prop.text = "Property:"
		val_or_return_label.text = "Value: "
		args_inputs.visible = false
	else:
		is_prop.text = "Function:"
		val_or_return_label.text = "Return: "
		args_inputs.visible = true


func _on_args_text_changed(new_text: String) -> void:
	current_conditional.args = new_text
	is_changed()


func _on_check_operation_popup(id: int, popup: PopupMenu) -> void:
	var pp_text: String = popup.get_item_text(id)
	undo_redo.create_action("set check operation")
	undo_redo.add_do_method(
		commands_container,
		"command_undo_redo_caller",
		"set_check_operation",
		[pp_text],
		current_conditional
	)
	undo_redo.add_undo_method(
		commands_container,
		"command_undo_redo_caller",
		"set_check_operation",
		[current_conditional.condition_type],
		current_conditional
	)
	undo_redo.commit_action()


func set_check_operation(pp_text: String) -> void:
	current_conditional.condition_type = pp_text
	check_operation.text = pp_text
	is_changed()


func _on_check_val_input_text_changed(new_text: String) -> void:
	current_conditional.check_val = new_text
	is_changed()


func _on_req_var_input_text_changed(new_text: String) -> void:
	current_conditional.required_var = new_text
	is_changed()


func _on_req_node_input_text_changed(new_text: String) -> void:
	current_conditional.required_node = new_text
	is_changed()


func _on_close_button_pressed() -> void:
	close_pressed.emit(current_conditional)
	is_changed()


func _on_up_button_pressed() -> void:
	change_index.emit(UP, current_conditional)


func _on_down_button_pressed() -> void:
	change_index.emit(DOWN, current_conditional)


func get_conditional() -> ConditionResource:
	return current_conditional


func is_changed() -> void:
	current_conditional.changed.emit()
