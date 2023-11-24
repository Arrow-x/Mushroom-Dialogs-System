@tool
extends Control

@export var character_menu: MenuButton
@export var portraits_menu: MenuButton
@export var portraits_pos_menu: MenuButton
@export var say_text_edit: TextEdit
@export var v_slit: VSplitContainer
@export var is_cond: CheckButton
@export var cond_box: VBoxContainer
@export var req_node: LineEdit
@export var req_var: LineEdit
@export var req_val: LineEdit
@export var check_type: MenuButton
@export var append_check: CheckBox

var current_say: SayCommand
var undo_redo: EditorUndoRedoManager
var current_flowchart: FlowChart
var commands_tree: Tree


func set_up(c_s: SayCommand, u_r: EditorUndoRedoManager, fl: FlowChart, cmd_tree: Tree) -> void:
	current_say = c_s
	undo_redo = u_r
	current_flowchart = fl
	commands_tree = cmd_tree

	var check_type_popup: PopupMenu = check_type.get_popup()
	check_type_popup.id_pressed.connect(_on_checktype_popup.bind(check_type_popup))
	character_menu.get_popup().id_pressed.connect(_on_character_selected)
	portraits_menu.get_popup().id_pressed.connect(_on_portrait_selected)
	portraits_pos_menu.get_popup().id_pressed.connect(_on_portrait_pos_selected)

	if c_s.character != null:
		character_menu.text = c_s.character.name
	if c_s.portrait_id != "":
		portraits_menu.text = c_s.portrait_id
	say_text_edit.text = c_s.say
	is_cond.set_pressed_no_signal(c_s.is_cond)
	req_node.text = c_s.required_node
	req_var.text = c_s.required_var
	req_val.text = c_s.check_val
	check_type.text = c_s.condition_type
	append_check.button_pressed = c_s.append_text
	portraits_pos_menu.text = c_s.por_pos

	set_say_box_hight()


func set_say_box_hight() -> void:
	var new_offset := say_text_edit.get_line_count() * 18
	if new_offset > v_slit.split_offset:
		v_slit.split_offset = new_offset


func _on_text_edit_text_changed() -> void:
	set_say_box_hight()
	current_say.say = say_text_edit.text
	is_changed()


func _on_character_selected(id: int) -> void:
	var s_char: Chararcter = character_menu.get_popup().get_item_metadata(id)
	undo_redo.create_action("select character")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "select_character", [s_char])
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "select_character", [current_say.character]
	)
	undo_redo.commit_action()


func select_character(character: Chararcter = null) -> void:
	character_menu.text = character.name if character != null else ""
	current_say.character = character
	portraits_menu.text = "Select a Portrait"
	current_say.portrait_id = ""
	current_say.portrait = null
	is_changed()


func _on_portrait_selected(id: int) -> void:
	var portrait_name := portraits_menu.get_popup().get_item_text(id)
	undo_redo.create_action("select a portrait")
	undo_redo.add_do_method(
		commands_tree, "command_undo_redo_caller", "select_portrait", [portrait_name]
	)
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "select_portrait", [current_say.portrait_id]
	)
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


func _on_portrait_pos_selected(id: int) -> void:
	var portrait_pos_name := portraits_pos_menu.get_popup().get_item_text(id)
	undo_redo.create_action("select portrait position")
	undo_redo.add_do_method(
		commands_tree, "command_undo_redo_caller", "select_portrait_pos", [portrait_pos_name]
	)
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "select_portrait_pos", [current_say.por_pos]
	)
	undo_redo.commit_action()


func select_portrait_pos(pos: String) -> void:
	portraits_pos_menu.text = pos
	current_say.por_pos = pos
	is_changed()


func _on_character_menu_button_about_to_show() -> void:
	var pop := character_menu.get_popup()
	pop.clear()
	var fc_chars := current_flowchart.characters
	for c_idx in fc_chars.size():
		pop.add_item(fc_chars[c_idx].name)
		pop.set_item_metadata(c_idx, fc_chars[c_idx])


func _on_portrait_menu_button_about_to_show() -> void:
	var pop := portraits_menu.get_popup()
	pop.clear()
	var char_portrs: Dictionary = current_say.character.portraits
	for c in char_portrs:
		pop.add_item(c)


func _on_checktype_popup(id: int, popup: PopupMenu) -> void:
	var pp_text: String = popup.get_item_text(id)
	current_say.condition_type = pp_text
	check_type.text = pp_text
	is_changed()


func _on_check_val_input_text_changed(new_text: String) -> void:
	current_say.check_val = new_text
	is_changed()


func _on_req_var_input_text_changed(new_text: String) -> void:
	current_say.required_var = new_text
	is_changed()


func _on_req_node_input_text_changed(new_text: String) -> void:
	current_say.required_node = new_text
	is_changed()


func _on_is_cond_check_box_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle condition")
	undo_redo.add_do_method(
		commands_tree, "command_undo_redo_caller", "show_condition_toggle", [button_pressed]
	)
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "show_condition_toggle", [current_say.is_cond]
	)
	undo_redo.commit_action()


func show_condition_toggle(button_pressed: bool) -> void:
	is_cond.set_pressed_no_signal(button_pressed)
	cond_box.visible = button_pressed
	current_say.is_cond = button_pressed
	is_changed()


func _on_append_check_box_toggled(button_pressed: bool) -> void:
	current_say.append_text = button_pressed
	is_changed()


func get_command() -> Command:
	return current_say


func is_changed() -> void:
	current_say.changed.emit()


func _on_wrap_button_pressed() -> void:
	undo_redo.create_action("Set Say Text Wrap preview")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "set_say_text_wrap")
	undo_redo.add_undo_method(commands_tree, "command_undo_redo_caller", "set_say_text_wrap")
	undo_redo.commit_action()


func set_say_text_wrap():
	say_text_edit.wrap_mode = 1 - say_text_edit.wrap_mode
