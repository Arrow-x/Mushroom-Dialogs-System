@tool
extends Control

@export var req_node_input: LineEdit
@export var req_var_input: LineEdit
@export var check_val_input: LineEdit
@export var check_type: MenuButton

var current_condition: ConditionCommand


func set_up(cc: ConditionCommand) -> void:
	current_condition = cc

	var check_type_popup: PopupMenu = check_type.get_popup()
	check_type_popup.id_pressed.connect(_on_check_type_popup.bind(check_type_popup))

	req_node_input.text = current_condition.required_node
	req_var_input.text = current_condition.required_var
	check_val_input.text = current_condition.check_val
	check_type.text = current_condition.condition_type


func _on_check_val_input_text_changed(new_text: String) -> void:
	current_condition.check_val = new_text
	is_changed()


func _on_req_var_input_text_changed(new_text: String) -> void:
	current_condition.required_var = new_text
	is_changed()


func _on_req_node_input_text_changed(new_text: String) -> void:
	current_condition.required_node = new_text
	is_changed()


func _on_check_type_popup(id: int, popup: PopupMenu) -> void:
	var pp_text: String = popup.get_item_text(id)
	current_condition.condition_type = pp_text
	check_type.text = pp_text
	is_changed()


func get_command() -> Command:
	return current_condition


func is_changed() -> void:
	current_condition.changed.emit()
