tool
extends Control

onready var name_line_edit: LineEdit = $VBoxContainer/NameHBoxContainer/NameLineEdit
onready var say_text_edit: TextEdit = $VBoxContainer/VSplitContainer/SayHBoxContainer/TextEdit
onready var v_slit: VSplitContainer = $VBoxContainer/VSplitContainer

onready var is_cond: CheckButton = $VBoxContainer/IsCondCheckBox

onready var cond_box: VBoxContainer = $VBoxContainer/CondVBoxContainer

onready var req_node: LineEdit = $VBoxContainer/CondVBoxContainer/ReqNode/ReqNodeInput
onready var req_var: LineEdit = $VBoxContainer/CondVBoxContainer/ReqVar/ReqVarInput
onready var req_val: LineEdit = $VBoxContainer/CondVBoxContainer/ReqVal/CheckValInput
onready var check_type: MenuButton = $VBoxContainer/CondVBoxContainer/ReqVar/CheckType
onready var append_check: CheckBox = $VBoxContainer/AppendHBoxContainer/AppendCheckBox

var current_say: say_command
var undo_redo: UndoRedo
var current_toogle: bool = false


func set_up(c_s: say_command, u_r: UndoRedo):
	current_say = c_s

	var check_type_popup: PopupMenu = get_node("VBoxContainer/CondVBoxContainer/ReqVar/CheckType").get_popup()
	check_type_popup.connect("id_pressed", self, "_on_CheckTypePopup", [check_type_popup])

	name_line_edit.text = c_s.name
	say_text_edit.text = c_s.say
	undo_redo = u_r

	is_cond.pressed = c_s.is_cond
	req_node.text = c_s.required_node
	req_var.text = c_s.required_var
	req_val.text = c_s.check_val
	check_type.text = c_s.condition_type
	append_check.pressed = c_s.append_text

	set_say_box_hight()


func set_say_box_hight():
	v_slit.split_offset = say_text_edit.get_line_count() * 18


func _on_TextEdit_text_changed():
	set_say_box_hight()
	current_say.say = say_text_edit.text
	is_changed()


func _on_NameLineEdit_text_changed(new_text: String):
	current_say.name = new_text
	is_changed()


func _on_CheckTypePopup(id: int, popup: PopupMenu) -> void:
	var pp_text: String = popup.get_item_text(id)
	current_say.condition_type = pp_text
	get_node("VBoxContainer/CondVBoxContainer/ReqVar/CheckType").text = pp_text
	is_changed()


func _on_CheckValInput_text_changed(new_text: String) -> void:
	current_say.check_val = new_text
	is_changed()


func _on_ReqVarInput_text_changed(new_text: String) -> void:
	current_say.required_var = new_text
	is_changed()


func _on_ReqNodeInput_text_changed(new_text: String) -> void:
	current_say.required_node = new_text
	is_changed()


func _on_IsCondCheckBox_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle condition")
	undo_redo.add_do_method(self, "show_condition_toggle", button_pressed)
	undo_redo.add_undo_method(self, "show_condition_toggle", current_toogle)
	undo_redo.commit_action()
	current_toogle = button_pressed


func show_condition_toggle(button_pressed: bool) -> void:
	is_cond.pressed = button_pressed
	cond_box.visible = button_pressed
	current_say.is_cond = button_pressed
	is_changed()


func _on_AppendCheckBox_toggled(button_pressed: bool) -> void:
	current_say.append_text = button_pressed
	is_changed()


func get_command() -> Command:
	return current_say


func is_changed() -> void:
	current_say.emit_signal("changed")
