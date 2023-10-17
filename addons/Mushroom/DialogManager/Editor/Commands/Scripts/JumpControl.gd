@tool
extends Control

@onready var index_control: SpinBox = $BlockHBoxContainer/SpinBox
@onready var global_control: CheckButton = $GlobalHBoxContainer/CheckButton
@onready var chose_block_control: HBoxContainer = $BlockHBoxContainer2
@onready var block_selection_cotrol: MenuButton = $BlockHBoxContainer2/MenuButton

var flowchart: FlowChart
var current_jump: JumpCommand
var undo_redo: UndoRedo
var current_toogle: bool


func set_up(jump: JumpCommand, u_r: UndoRedo, fl: FlowChart) -> void:
	flowchart = fl
	current_jump = jump
	undo_redo = u_r
	index_control.value = jump.jump_index
	global_control.button_pressed = jump.global
	current_toogle = jump.global
	block_selection_cotrol.text = jump.get_block_name()
	show_block_menu(jump.global)


func _on_SpinBox_value_changed(value: float) -> void:
	current_jump.jump_index = int(value)
	is_changed()


func _on_CheckButton_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle local_jump")
	undo_redo.add_do_method(show_block_menu.bind(button_pressed))
	undo_redo.add_undo_method(show_block_menu.bind(current_toogle))
	undo_redo.commit_action()
	current_toogle = button_pressed


func show_block_menu(toggle: bool) -> void:
	global_control.button_pressed = toggle
	current_jump.global = toggle
	chose_block_control.visible = toggle
	is_changed()


func _on_MenuButton_about_to_show() -> void:
	var menu: PopupMenu = block_selection_cotrol.get_popup()
	menu.clear()
	for b in flowchart.blocks:
		menu.add_item(b)

	if !menu.index_pressed.is_connected(change_jump_block):
		menu.index_pressed.connect(change_jump_block.bind(menu))


func change_jump_block(idx, m: PopupMenu) -> void:
	var n_block: Block = flowchart.get_block(m.get_item_text(idx))
	var p_block: Block = current_jump.jump_block
	undo_redo.create_action("change next block")
	undo_redo.add_do_method(do_change_jump_block.bind(n_block))
	undo_redo.add_undo_method(do_change_jump_block.bind(p_block))
	undo_redo.commit_action()


func do_change_jump_block(next_block: Block = null) -> void:
	if next_block != null:
		current_jump.jump_block = next_block
		block_selection_cotrol.text = next_block.name
	else:
		block_selection_cotrol.text = "null"
	is_changed()


func is_changed() -> void:
	current_jump.changed.emit()


func get_command() -> Command:
	return current_jump
