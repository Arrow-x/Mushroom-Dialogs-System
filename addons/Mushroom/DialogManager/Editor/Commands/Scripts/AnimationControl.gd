tool
extends Node

var animation_cmd: animation_command
var undo_redo: UndoRedo

var current_from_end: bool

onready var anim_type_ctrl: MenuButton = $VBoxContainer/TypeHBoxContainer/TypeMenu
onready var anim_path_ctrl: LineEdit = $VBoxContainer/PathHBoxContainer/PathLineEdit
onready var anim_name_ctrl: LineEdit = $VBoxContainer/ANameHBoxContainer/NameLineEdit
onready var blend_ctrl: SpinBox = $VBoxContainer/BlendHBoxContainer/BlendLineEdit
onready var speed_ctrl: SpinBox = $VBoxContainer/SpeedHBoxContainer/SpeedLineEdit
onready var from_end_ctrl: CheckButton = $VBoxContainer/FromEndHBoxContainer/FromEndCheck


func set_up(a_cmd: animation_command, u_r: UndoRedo) -> void:
	animation_cmd = a_cmd
	undo_redo = u_r
	anim_type_ctrl.get_popup().connect(
		"id_pressed", self, "_on_anim_type", [anim_type_ctrl.get_popup()]
	)
	anim_type_ctrl.text = animation_cmd.anim_type
	anim_path_ctrl.text = animation_cmd.animation_path
	anim_name_ctrl.text = animation_cmd.animation_name
	blend_ctrl.value = animation_cmd.custom_blend
	speed_ctrl.value = animation_cmd.custom_speed
	from_end_ctrl.pressed = animation_cmd.from_end


func _on_PathLineEdit_text_changed(new_text: String) -> void:
	animation_cmd.animation_path = new_text
	is_changed()


func _on_NameLineEdit_text_changed(new_text: String) -> void:
	animation_cmd.animation_name = new_text
	is_changed()


func _on_SpeedLineEdit_value_changed(value: float) -> void:
	animation_cmd.custom_speed = value
	is_changed()


func _on_BlendLineEdit_value_changed(value: float) -> void:
	animation_cmd.custom_blend = value
	is_changed()


func _on_FromEndCheck_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle from_end")
	undo_redo.add_do_method(self, "toggle_from_end", button_pressed)
	undo_redo.add_undo_method(self, "toggle_from_end", current_from_end)
	undo_redo.commit_action()
	current_from_end = button_pressed


func toggle_from_end(button_pressed: bool) -> void:
	from_end_ctrl.pressed = button_pressed
	animation_cmd.from_end = button_pressed
	is_changed()


func _on_anim_type(id: int, popup: Popup) -> void:
	var pp_text: String = popup.get_item_text(id)
	animation_cmd.anim_type = pp_text
	anim_type_ctrl.text = pp_text
	is_changed()


func get_command() -> Command:
	return animation_cmd


func is_changed() -> void:
	animation_cmd.emit_signal("changed")
