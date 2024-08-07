@tool
extends Node

@export var index_control: SpinBox
@export var global_control: CheckButton
@export var chose_block_control: HBoxContainer
@export var block_selection_cotrol: MenuButton

var current_jump: JumpCommand
var undo_redo: EditorUndoRedoManager
var flowchart: FlowChart
var commands_container: Node


func set_up(jump: JumpCommand, u_r: EditorUndoRedoManager, fl: FlowChart, cmd_c: Node) -> void:
	flowchart = fl
	current_jump = jump
	undo_redo = u_r
	commands_container = cmd_c
	index_control.value = jump.jump_index
	global_control.set_pressed_no_signal(jump.global)
	block_selection_cotrol.text = jump.get_block_name()
	show_block_menu(jump.global)


func _on_spin_box_value_changed(value: float) -> void:
	current_jump.jump_index = int(value)
	is_changed()


func _on_check_button_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle local_jump")
	undo_redo.add_do_method(
		commands_container, "command_undo_redo_caller", "show_block_menu", [button_pressed]
	)
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "show_block_menu", [current_jump.global]
	)
	undo_redo.commit_action()


func show_block_menu(toggle: bool) -> void:
	global_control.set_pressed_no_signal(toggle)
	current_jump.global = toggle
	chose_block_control.visible = toggle
	is_changed()


func _on_menu_button_about_to_show() -> void:
	var menu: PopupMenu = block_selection_cotrol.get_popup()
	menu.clear()
	for b in flowchart.blocks:
		menu.add_item(b)

	if !menu.index_pressed.is_connected(change_jump_block):
		menu.index_pressed.connect(change_jump_block.bind(menu))


func change_jump_block(idx, m: PopupMenu) -> void:
	var next_block: Block = flowchart.get_block(m.get_item_text(idx))
	var current_block: Block = current_jump.jump_block
	undo_redo.create_action("change next block")
	undo_redo.add_do_method(
		commands_container, "command_undo_redo_caller", "do_change_jump_block", [next_block]
	)
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "do_change_jump_block", [current_block]
	)
	undo_redo.commit_action()


func do_change_jump_block(next_block: Block = null) -> void:
	if next_block != null:
		current_jump.jump_block = next_block
		block_selection_cotrol.text = next_block.name
	else:
		block_selection_cotrol.text = "null"
	is_changed()


func get_command() -> Command:
	return current_jump


func is_changed() -> void:
	current_jump.changed.emit(current_jump)
