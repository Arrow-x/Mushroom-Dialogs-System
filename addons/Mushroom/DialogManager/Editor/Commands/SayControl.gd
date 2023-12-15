@tool
extends Control

@export var character_menu: MenuButton
@export var portraits_menu: MenuButton
@export var portraits_pos_menu: MenuButton
@export var say_text_edit: TextEdit
@export var v_slit: VSplitContainer
@export var is_cond: CheckButton
@export var cond_box: VBoxContainer
@export var cond_editors_container: VBoxContainer
@export var append_check: CheckBox
@export var follow_check: CheckBox

var current_say: SayCommand
var undo_redo: EditorUndoRedoManager
var current_flowchart: FlowChart
var commands_tree: Tree


func set_up(c_s: SayCommand, u_r: EditorUndoRedoManager, fl: FlowChart, cmd_tree: Tree) -> void:
	current_say = c_s
	undo_redo = u_r
	current_flowchart = fl
	commands_tree = cmd_tree

	character_menu.get_popup().id_pressed.connect(_on_character_selected)
	portraits_menu.get_popup().id_pressed.connect(_on_portrait_selected)
	portraits_pos_menu.get_popup().id_pressed.connect(_on_portrait_pos_selected)

	if c_s.character != null:
		character_menu.text = c_s.character.name
	if c_s.portrait_id != "":
		portraits_menu.text = c_s.portrait_id
	say_text_edit.text = c_s.say
	portraits_pos_menu.text = c_s.por_pos
	cond_box.set_up(current_say, undo_redo, commands_tree)
	append_check.set_pressed_no_signal(c_s.append_text)
	follow_check.set_pressed_no_signal(c_s.follow_through)
	is_cond.set_pressed_no_signal(c_s.is_cond)
	if is_cond.button_pressed == true:
		cond_box.visible = true

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
	undo_redo.create_action("Toggle append")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "toggle_append")
	undo_redo.add_undo_method(commands_tree, "command_undo_redo_caller", "toggle_append")
	undo_redo.commit_action()


func toggle_append() -> void:
	append_check.set_pressed_no_signal(not current_say.append_text)
	current_say.append_text = not current_say.append_text
	is_changed()


func _on_through_check_box_toggled(toggled_on: bool) -> void:
	undo_redo.create_action("Toggle follow")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "toggle_follow")
	undo_redo.add_undo_method(commands_tree, "command_undo_redo_caller", "toggle_follow")
	undo_redo.commit_action()


func toggle_follow() -> void:
	follow_check.set_pressed_no_signal(not current_say.follow_through)
	current_say.follow_through = not current_say.follow_through
	is_changed()


func _on_wrap_button_pressed() -> void:
	undo_redo.create_action("Set Say Text Wrap preview")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "set_say_text_wrap")
	undo_redo.add_undo_method(commands_tree, "command_undo_redo_caller", "set_say_text_wrap")
	undo_redo.commit_action()


func set_say_text_wrap():
	say_text_edit.wrap_mode = 1 - say_text_edit.wrap_mode


func get_command() -> Command:
	return current_say


func is_changed() -> void:
	current_say.changed.emit()
