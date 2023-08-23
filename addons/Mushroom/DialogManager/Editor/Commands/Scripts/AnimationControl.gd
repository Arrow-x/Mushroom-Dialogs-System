tool
extends Node

var animation_cmd: animation_command
onready var anim_type_ctrl: MenuButton = $VBoxContainer/TypeHBoxContainer/TypeMenu
onready var anim_path_ctrl: LineEdit = $VBoxContainer/PathHBoxContainer/PathLineEdit
onready var anim_name_ctrl: LineEdit = $VBoxContainer/ANameHBoxContainer/NameLineEdit
onready var blend_ctrl: LineEdit = $VBoxContainer/BlendHBoxContainer/BlendLineEdit
onready var speed_ctrl: LineEdit = $VBoxContainer/SpeedHBoxContainer/SpeedLineEdit
onready var from_end_ctrl: CheckButton = $VBoxContainer/FromEndHBoxContainer/FromEndCheck


func set_up(a_cmd: animation_command) -> void:
	animation_cmd = a_cmd
	anim_type_ctrl.get_popup().connect(
		"id_pressed", self, "_on_anim_type", [anim_type_ctrl.get_popup()]
	)
	anim_type_ctrl.text = animation_cmd.anim_type
	anim_path_ctrl.text = animation_cmd.animation_path
	anim_name_ctrl.text = animation_cmd.animation_name
	blend_ctrl.text = String(animation_cmd.custom_blend)
	speed_ctrl.text = String(animation_cmd.custom_speed)
	from_end_ctrl.pressed = animation_cmd.from_end


func _on_PathLineEdit_text_changed(new_text: String) -> void:
	animation_cmd.animation_path = new_text
	is_changed()


func _on_NameLineEdit_text_changed(new_text: String) -> void:
	animation_cmd.animation_name = new_text
	is_changed()


func _on_BlendLineEdit_text_changed(new_text: String) -> void:
	animation_cmd.custom_blend = float(new_text)
	is_changed()


func _on_SpeedLineEdit_text_changed(new_text: String) -> void:
	animation_cmd.custom_speed = float(new_text)
	is_changed()


func _on_FromEndCheck_toggled(button_pressed: bool) -> void:
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
