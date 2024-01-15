@tool
extends Node

@export var var_node_lineedit: LineEdit
@export var var_name_lineedit: LineEdit
@export var var_val_lineedit: LineEdit

var current_set_var: SetVarCommand


func set_up(c: SetVarCommand) -> void:
	current_set_var = c
	var_node_lineedit.text = current_set_var.var_path
	var_name_lineedit.text = current_set_var.var_name
	var_val_lineedit.text = String(current_set_var.var_value)


func _on_var_node_line_edit_text_changed(new_text: String) -> void:
	current_set_var.var_path = new_text
	is_changed()


func _on_var_name_line_edit_text_changed(new_text: String) -> void:
	current_set_var.var_name = new_text
	is_changed()


func _on_set_val_line_edit_text_changed(new_text: String) -> void:
	current_set_var.var_value = new_text
	is_changed()


func get_command() -> Command:
	return current_set_var


func is_changed() -> void:
	current_set_var.changed.emit(current_set_var)
