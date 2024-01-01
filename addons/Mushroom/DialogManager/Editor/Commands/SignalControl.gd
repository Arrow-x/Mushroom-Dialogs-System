@tool
extends VBoxContainer

@export var req_node: LineEdit
@export var signal_name: LineEdit
@export var signal_args: LineEdit

var current_signal: SignalCommand


func set_up(cmd: SignalCommand) -> void:
	current_signal = cmd
	req_node.text = current_signal.req_node
	signal_name.text = current_signal.signal_name
	signal_args.text = current_signal.signal_args


func _on_node_line_edit_text_changed(new_text: String) -> void:
	current_signal.req_node = new_text
	is_changed()


func _on_signal_line_edit_text_changed(new_text: String) -> void:
	current_signal.signal_name = new_text
	is_changed()


func _on_args_line_edit_text_changed(new_text: String) -> void:
	current_signal.signal_args = new_text
	is_changed()


func get_command() -> Command:
	return current_signal


func is_changed() -> void:
	current_signal.changed.emit(current_signal)
