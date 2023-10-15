tool
extends Control
onready var character_menu: MenuButton = $VBoxContainer/CharacterHBoxContainer/CharacterMenuButton
onready var portraits_menu: MenuButton = $VBoxContainer/VSplitContainer/VBoxContainer/PortraitHBoxContainer/PortraitMenuButton
onready var say_text_edit: TextEdit = $VBoxContainer/VSplitContainer/SayHBoxContainer/TextEdit
onready var v_slit: VSplitContainer = $VBoxContainer/VSplitContainer
onready var is_cond: CheckButton = $VBoxContainer/IsCondCheckBox
onready var cond_box: VBoxContainer = $VBoxContainer/CondVBoxContainer
onready var req_node: LineEdit = $VBoxContainer/CondVBoxContainer/ReqNode/ReqNodeInput
onready var req_var: LineEdit = $VBoxContainer/CondVBoxContainer/ReqVar/ReqVarInput
onready var req_val: LineEdit = $VBoxContainer/CondVBoxContainer/ReqVal/CheckValInput
onready var check_type: MenuButton = $VBoxContainer/CondVBoxContainer/ReqVal/CheckType
onready var append_check: CheckBox = $VBoxContainer/AppendHBoxContainer/AppendCheckBox

var undo_redo: UndoRedo
var current_say: SayCommand
var current_flowchart: FlowChart


func set_up(c_s: SayCommand, u_r: UndoRedo, fl: FlowChart):
	current_say = c_s
	current_flowchart = fl

	var check_type_popup: PopupMenu = get_node("VBoxContainer/CondVBoxContainer/ReqVal/CheckType").get_popup()
	check_type_popup.connect("id_pressed", self, "_on_CheckTypePopup", [check_type_popup])
	character_menu.get_popup().connect("id_pressed", self, "_on_Character_Selected")
	portraits_menu.get_popup().connect("id_pressed", self, "_on_Portrait_Selected")

	undo_redo = u_r

	if c_s.character != null:
		character_menu.text = c_s.character.name
	if c_s.portrait_id != "":
		portraits_menu.text = c_s.portrait_id
	say_text_edit.text = c_s.say
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


func _on_Character_Selected(id: int) -> void:
	var s_char: Chararcter = character_menu.get_popup().get_item_metadata(id)
	undo_redo.create_action("select character")
	undo_redo.add_do_method(self, "select_character", s_char)
	undo_redo.add_undo_method(self, "select_character", current_say.character)
	undo_redo.commit_action()


func select_character(character: Chararcter = null) -> void:
	character_menu.text = character.name if character != null else ""
	current_say.character = character
	portraits_menu.text = "Select a Portrait"
	current_say.portrait_id = ""
	current_say.portrait = null
	is_changed()


func _on_Portrait_Selected(id: int) -> void:
	var portrait_name := portraits_menu.get_popup().get_item_text(id)
	undo_redo.create_action("select a portrait")
	undo_redo.add_do_method(self, "select_portrait", portrait_name)
	undo_redo.add_undo_method(self, "select_portrait", current_say.portrait_id)
	undo_redo.commit_action()


func select_portrait(character: String = "") -> void:
	portraits_menu.text = character
	current_say.portrait_id = character
	current_say.portrait = (
		current_say.character.portraits[character]
		if current_say.character != null and character != ""
		else null
	)
	is_changed()


func _on_CharacterMenuButton_about_to_show() -> void:
	var pop := character_menu.get_popup()
	pop.clear()
	var fc_chars := current_flowchart.characters
	for c_idx in fc_chars.size():
		pop.add_item(fc_chars[c_idx].name)
		pop.set_item_metadata(c_idx, fc_chars[c_idx])


func _on_PortraitMenuButton_about_to_show() -> void:
	var pop := portraits_menu.get_popup()
	pop.clear()
	var char_portrs: Dictionary = current_say.character.portraits
	for c in char_portrs:
		pop.add_item(c)


func _on_CheckTypePopup(id: int, popup: PopupMenu) -> void:
	var pp_text: String = popup.get_item_text(id)
	current_say.condition_type = pp_text
	get_node("VBoxContainer/CondVBoxContainer/ReqVal/CheckType").text = pp_text
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
	undo_redo.add_undo_method(self, "show_condition_toggle", current_say.is_cond)
	undo_redo.commit_action()


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
