@tool
extends VBoxContainer

@export var req_node: LineEdit
@export var func_name: LineEdit
@export var args: LineEdit

var current_call_func: CallFunctionCommand


func set_up(cmd: CallFunctionCommand) -> void:
	current_call_func = cmd
	req_node.text = current_call_func.req_node
	func_name.text = current_call_func.func_name
	args.text = current_call_func.args


func _on_node_line_edit_text_changed(new_text: String) -> void:
	current_call_func.req_node = new_text
	is_changed()


func _on_func_line_edit_text_changed(new_text: String) -> void:
	current_call_func.func_name = new_text
	is_changed()


func _on_args_line_edit_text_changed(new_text: String) -> void:
	current_call_func.args = new_text
	is_changed()


func get_command() -> Command:
	return current_call_func


func is_changed() -> void:
	current_call_func.changed.emit()
