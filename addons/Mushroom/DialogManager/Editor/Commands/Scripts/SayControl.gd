tool
extends Control

onready var name_line_edit: LineEdit = $VBoxContainer/NameHBoxContainer/NameLineEdit
onready var say_text_edit: TextEdit = $VBoxContainer/VSplitContainer/SayHBoxContainer/TextEdit
onready var v_slit: VSplitContainer = $VBoxContainer/VSplitContainer

var current_say: say_command


func set_up(c_s: say_command):
	current_say = c_s
	name_line_edit.text = c_s.name
	say_text_edit.text = c_s.say
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


func get_command() -> Command:
	return current_say

func is_changed() -> void:
	current_say.emit_signal("changed")
