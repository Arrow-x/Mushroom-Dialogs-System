@tool
extends VBoxContainer

var current_change_ui: ChangeUICommand
var undo_redo: EditorUndoRedoManager
var toggle: bool
var current_ui_scene: PackedScene

@onready var default_check := $HBoxContainer/IsDefaultCheckButton
@onready var ui_drag_target := $UIHBoxContainer/HBoxContainer/UIDragTargetLabel
@onready var ui_drag_container := $UIHBoxContainer


func set_up(cmd: ChangeUICommand, u_r: EditorUndoRedoManager) -> void:
	current_change_ui = cmd
	undo_redo = u_r
	default_check.button_pressed = current_change_ui.change_to_default
	change_ui_scene(current_change_ui.next_UI)


func _on_IsDefaultCheckButton_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle default ui")
	undo_redo.add_do_method(self, "toggle_ui", button_pressed)
	undo_redo.add_undo_method(self, "toggle_ui", toggle)
	undo_redo.commit_action()
	toggle = button_pressed


func toggle_ui(button_pressed: bool) -> void:
	current_change_ui.change_to_default = button_pressed
	if button_pressed:
		ui_drag_container.visible = false
	else:
		ui_drag_container.visible = true
	is_changed()


func _on_UIDragTargetLabel_value_dragged(value: PackedScene) -> void:
	undo_redo.create_action("drag a new UI scene")
	undo_redo.add_do_method(self, "change_ui_scene", value)
	undo_redo.add_undo_method(self, "change_ui_scene", current_ui_scene)
	undo_redo.commit_action()
	current_ui_scene = value


func _on_ClearButton_pressed() -> void:
	undo_redo.create_action("drag a new UI scene")
	undo_redo.add_do_method(self, "change_ui_scene")
	undo_redo.add_undo_method(self, "change_ui_scene", current_ui_scene)
	undo_redo.commit_action()
	current_ui_scene = null


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
