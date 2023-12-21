@tool
extends VBoxContainer

@export var name_edit: LineEdit

var current_general_container: GeneralContainerCommand


func set_up(cmd: GeneralContainerCommand):
	current_general_container = cmd
	name_edit.text = current_general_container.name


func _on_line_edit_text_changed(new_text: String) -> void:
	current_general_container.name = new_text
	is_changed()


func get_command() -> Command:
	return current_general_container


func is_changed() -> void:
	current_general_container.changed.emit(current_general_container)
