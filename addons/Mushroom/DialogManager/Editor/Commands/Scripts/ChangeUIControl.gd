@tool
extends Control

@export var default_check: CheckButton
@export var ui_drag_target: Label
@export var ui_drag_container: HBoxContainer

var current_change_ui: ChangeUICommand
var undo_redo: EditorUndoRedoManager


func set_up(cmd: ChangeUICommand, u_r: EditorUndoRedoManager) -> void:
	current_change_ui = cmd
	undo_redo = u_r
	default_check.set_pressed_no_signal(current_change_ui.change_to_default)
	change_ui_scene(current_change_ui.next_UI)


func _on_is_default_checkbutton_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle default ui")
	undo_redo.add_do_method(self, "toggle_ui", button_pressed)
	undo_redo.add_undo_method(self, "toggle_ui", current_change_ui.change_to_default)
	undo_redo.commit_action()


func toggle_ui(button_pressed: bool) -> void:
	current_change_ui.change_to_default = button_pressed
	if button_pressed:
		ui_drag_container.visible = false
	else:
		ui_drag_container.visible = true
	is_changed()


func _on_ui_drag_target_label_value_dragged(value: PackedScene) -> void:
	undo_redo.create_action("drag a new UI scene")
	undo_redo.add_do_method(self, "change_ui_scene", value)
	undo_redo.add_undo_method(self, "change_ui_scene", current_change_ui.next_UI)
	undo_redo.commit_action()


func _on_clear_button_pressed() -> void:
	undo_redo.create_action("drag a new UI scene")
	undo_redo.add_do_method(self, "change_ui_scene")
	undo_redo.add_undo_method(self, "change_ui_scene", current_change_ui.next_UI)
	undo_redo.commit_action()


func change_ui_scene(new_ui: PackedScene = null) -> void:
	current_change_ui.next_UI = new_ui
	if new_ui != null:
		ui_drag_target.text = new_ui.resource_path.get_file()
	else:
		ui_drag_target.text = "..."


func get_command() -> Command:
	return current_change_ui


func is_changed() -> void:
	current_change_ui.emit_signal("changed")
