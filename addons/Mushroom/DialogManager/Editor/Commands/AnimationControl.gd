@tool
extends Control

@export var anim_path_ctrl: LineEdit
@export var anim_name_ctrl: LineEdit
@export var blend_ctrl: SpinBox
@export var speed_ctrl: SpinBox
@export var from_end_ctrl: CheckButton
@export var wait_check: CheckButton

var animation_cmd: AnimationCommand
var undo_redo: EditorUndoRedoManager
var commands_tree: Tree


func set_up(a_cmd: AnimationCommand, u_r: EditorUndoRedoManager, cmd_tree: Tree) -> void:
	animation_cmd = a_cmd
	undo_redo = u_r
	commands_tree = cmd_tree
	anim_path_ctrl.text = animation_cmd.animation_path
	anim_name_ctrl.text = animation_cmd.animation_name
	blend_ctrl.value = animation_cmd.custom_blend
	speed_ctrl.value = animation_cmd.custom_speed
	toggle_is_wait(animation_cmd.is_wait)
	toggle_from_end(animation_cmd.from_end)


func _on_path_lineedit_text_changed(new_text: String) -> void:
	animation_cmd.animation_path = new_text
	is_changed()


func _on_name_lineedit_text_changed(new_text: String) -> void:
	animation_cmd.animation_name = new_text
	is_changed()


func _on_speed_lineedit_value_changed(value: float) -> void:
	animation_cmd.custom_speed = value
	is_changed()


func _on_blend_lineedit_value_changed(value: float) -> void:
	animation_cmd.custom_blend = value
	is_changed()


func _on_from_endcheck_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle from_end")
	undo_redo.add_do_method(
		commands_tree, "command_undo_redo_caller", "toggle_from_end", [button_pressed]
	)
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "toggle_from_end", [animation_cmd.from_end]
	)
	undo_redo.commit_action()


func toggle_from_end(button_pressed: bool) -> void:
	from_end_ctrl.set_pressed_no_signal(button_pressed)
	animation_cmd.from_end = button_pressed
	if button_pressed == true:
		from_end_ctrl.text = "From End"
	if button_pressed == false:
		from_end_ctrl.text = "From Beginning"
	is_changed()


func _on_is_wait_check_toggled(toggled_on: bool) -> void:
	undo_redo.create_action("toggle from_end")
	undo_redo.add_do_method(
		commands_tree, "command_undo_redo_caller", "toggle_is_wait", [toggled_on]
	)
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "toggle_is_wait", [animation_cmd.is_wait]
	)
	undo_redo.commit_action()


func toggle_is_wait(toggle: bool) -> void:
	wait_check.set_pressed_no_signal(toggle)
	animation_cmd.is_wait = toggle
	if toggle == true:
		wait_check.text = "Wait"
	if toggle == false:
		wait_check.text = "Continue"

	is_changed()


func get_command() -> Command:
	return animation_cmd


func is_changed() -> void:
	animation_cmd.changed.emit()