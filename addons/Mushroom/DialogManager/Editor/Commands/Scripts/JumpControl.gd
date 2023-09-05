tool
extends Control
onready var index_control: SpinBox = $BlockHBoxContainer/SpinBox
onready var global_control: CheckButton = $GlobalHBoxContainer/CheckButton
onready var chose_block_control: HBoxContainer = $BlockHBoxContainer2
onready var block_selection_cotrol: MenuButton = $BlockHBoxContainer2/MenuButton

var flowchart: FlowChart
var current_jump: jump_command
var undo_redo: UndoRedo
var current_toogle: bool


func set_up(jump: jump_command, u_r: UndoRedo, fl: FlowChart):
	flowchart = fl
	current_jump = jump
	undo_redo = u_r
	index_control.value = jump.jump_index
	global_control.pressed = jump.global
	current_toogle = jump.global
	block_selection_cotrol.text = jump.get_block_name()
	show_block_menu(jump.global)


func _on_SpinBox_value_changed(value: float) -> void:
	current_jump.jump_index = int(value)
	is_changed()


func _on_CheckButton_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle local_jump")
	undo_redo.add_do_method(self, "show_block_menu", button_pressed)
	undo_redo.add_undo_method(self, "show_block_menu", current_toogle)
	undo_redo.commit_action()
	current_toogle = button_pressed


func show_block_menu(toggle: bool) -> void:
	global_control.pressed = toggle
	current_jump.global = toggle
	chose_block_control.visible = toggle
	is_changed()


func _on_MenuButton_about_to_show() -> void:
	var menu: PopupMenu = block_selection_cotrol.get_popup()
	menu.clear()
	for b in flowchart.blocks:
		menu.add_item(b)

	if !menu.is_connected("index_pressed", self, "change_jump_block"):
		menu.connect("index_pressed", self, "change_jump_block", [menu])


func change_jump_block(idx, m: PopupMenu) -> void:
	var n_block: block = flowchart.get_block(m.get_item_text(idx))
	var p_block: block = current_jump.jump_block
	undo_redo.create_action("change next block")
	undo_redo.add_do_method(self, "do_change_jump_block", n_block)
	undo_redo.add_undo_method(self, "do_change_jump_block", p_block)
	undo_redo.commit_action()


func do_change_jump_block(next_block: block = null) -> void:
	if next_block != null:
		current_jump.jump_block = next_block
		block_selection_cotrol.text = next_block.name
	else:
		block_selection_cotrol.text = "null"
	is_changed()


func is_changed() -> void:
	current_jump.emit_signal("changed")


func get_command() -> Command:
	return current_jump
