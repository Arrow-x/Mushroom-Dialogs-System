@tool
extends Control

@onready var var_node_lineedit: LineEdit = $VBoxContainer/VarNodeHBoxContainer/VarNodeLineEdit
@onready var var_name_lineedit: LineEdit = $VBoxContainer/VarNameHBoxContainer/VarNameLineEdit
@onready var var_val_lineedit: LineEdit = $VBoxContainer/SetValHBoxContainer/SetValLineEdit

var command: SetVarCommand


func set_up(c: SetVarCommand) -> void:
	command = c
	var_node_lineedit.text = command.var_path
	var_name_lineedit.text = command.var_name
	var_val_lineedit.text = String(command.var_value)


func _on_VarNodeLineEdit_text_changed(new_text: String) -> void:
	command.var_path = new_text
	is_changed()


func _on_VarNameLineEdit_text_changed(new_text: String) -> void:
	command.var_name = new_text
	is_changed()


func _on_SetValLineEdit_text_changed(new_text: String) -> void:
	command.var_value = new_text
	is_changed()


func get_command() -> Command:
	return command


func is_changed() -> void:
	command.changed.emit()
