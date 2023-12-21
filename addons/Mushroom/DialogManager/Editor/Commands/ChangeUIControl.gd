@tool
extends Control

@export var default_check: CheckButton
@export var ui_drag_target: Label
@export var ui_drag_container: HBoxContainer

var current_change_ui: ChangeUICommand
var undo_redo: EditorUndoRedoManager
var commands_tree: Tree


func set_up(cmd: ChangeUICommand, u_r: EditorUndoRedoManager, cmd_tree: Tree) -> void:
	current_change_ui = cmd
	undo_redo = u_r
	commands_tree = cmd_tree
	default_check.set_pressed_no_signal(current_change_ui.change_to_default)
	change_ui_scene(current_change_ui.next_UI)


func _on_is_default_check_button_toggled(toggled_on: bool) -> void:
	undo_redo.create_action("toggle default ui")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "toggle_ui", [toggled_on])
	undo_redo.add_undo_method(
		commands_tree,
		"command_undo_redo_caller",
		"toggle_ui",
		[current_change_ui.change_to_default]
	)
	undo_redo.commit_action()


func toggle_ui(toggle: bool) -> void:
	default_check.set_pressed_no_signal(toggle)
	current_change_ui.change_to_default = toggle
	ui_drag_container.visible = not toggle
	is_changed()


func _on_ui_drag_target_label_value_dragged(value: PackedScene) -> void:
	undo_redo.create_action("drag a new UI scene")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "change_ui_scene", [value])
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "change_ui_scene", [current_change_ui.next_UI]
	)
	undo_redo.commit_action()


func _on_clear_button_pressed() -> void:
	undo_redo.create_action("drag a new UI scene")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "change_ui_scene")
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "change_ui_scene", [current_change_ui.next_UI]
	)
	undo_redo.commit_action()


func change_ui_scene(new_ui: PackedScene = null) -> void:
	current_change_ui.next_UI = new_ui
	ui_drag_target.text = new_ui.resource_path.get_file() if new_ui != null else "..."
	is_changed()


func get_command() -> Command:
	return current_change_ui


func is_changed() -> void:
	current_change_ui.changed.emit(current_change_ui)
