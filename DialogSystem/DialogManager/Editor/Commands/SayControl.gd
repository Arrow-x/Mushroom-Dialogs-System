extends Control

onready var name_line_edit: LineEdit = $VBoxContainer/NameHBoxContainer/NameLineEdit
onready var say_text_edit: TextEdit = $VBoxContainer/VSplitContainer/SayHBoxContainer/TextEdit
onready var v_slit: VSplitContainer = $VBoxContainer/VSplitContainer


func set_say_box_hight():
	v_slit.split_offset = say_text_edit.get_line_count() * 18


func _on_TextEdit_text_changed():
	v_slit.split_offset = say_text_edit.get_line_count() * 18
