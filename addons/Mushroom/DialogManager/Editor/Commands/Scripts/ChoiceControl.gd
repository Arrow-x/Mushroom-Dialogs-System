tool
extends VBoxContainer
onready var choice_text: LineEdit = $HBoxContainer/ChoiceText
onready var next_block_menu: MenuButton = $HBoxContainer2/NextBlockList
onready var next_index_text: SpinBox = $HBoxContainer3/NextIndex
onready var delete_choice: Button = $HBoxContainer3/DeleteChoice

onready var is_cond: CheckButton = $IsCondCheckBox

onready var cond_box: VBoxContainer = $CondVBoxContainer

onready var req_node: LineEdit = $CondVBoxContainer/ReqNode/ReqNodeInput
onready var req_var: LineEdit = $CondVBoxContainer/ReqVar/ReqVarInput
onready var req_val: LineEdit = $CondVBoxContainer/ReqVal/CheckValInput
onready var check_type: MenuButton = $CondVBoxContainer/ReqVar/CheckType

var current_choice: choice
var flowchart: FlowChart
var undo_redo: UndoRedo
var current_toogle: bool = false

signal conncting
signal removing_choice


func set_up(c: choice, fct: FlowChart, u: UndoRedo) -> void:
	flowchart = fct
	current_choice = c
	choice_text.text = c.text
	undo_redo = u
	if c.next_block != null:
		next_block_menu.text = c.next_block
	next_index_text.value = c.next_index

	var check_type_popup: PopupMenu = get_node("CondVBoxContainer/ReqVar/CheckType").get_popup()
	check_type_popup.connect("id_pressed", self, "_on_CheckTypePopup", [check_type_popup])

	is_cond.pressed = c.is_cond
	req_node.text = c.required_node
	req_var.text = c.required_var
	req_val.text = c.check_val
	check_type.text = c.condition_type


func _on_DeleteChoice_pressed():
	emit_signal("removing_choice", self)
	emit_signal("conncting")


func _on_NextIndex_value_changed(value: float) -> void:
	current_choice.next_index = int(value)
	emit_signal("conncting")


func _on_NextBlockList_about_to_show() -> void:
	var menu: PopupMenu = next_block_menu.get_popup()
	if !menu.is_connected("index_pressed", self, "change_next_bloc"):
		menu.connect("index_pressed", self, "change_next_bloc", [menu])
	menu.clear()
	for b in flowchart.blocks:
		menu.add_item(b)


func change_next_bloc(index, m: PopupMenu) -> void:
	var n_block_name := m.get_item_text(index)
	var p_block_name := current_choice.next_block
	undo_redo.create_action("change next block")
	undo_redo.add_do_method(self, "do_change_next_block", n_block_name)
	undo_redo.add_undo_method(self, "do_change_next_block", p_block_name)
	undo_redo.commit_action()


func do_change_next_block(next_block_name: String = "") -> void:
	current_choice.next_block = next_block_name
	next_block_menu.text = next_block_name
	emit_signal("conncting")


func _on_CheckTypePopup(id: int, popup: PopupMenu) -> void:
	var pp_text: String = popup.get_item_text(id)
	current_choice.condition_type = pp_text
	get_node("CondVBoxContainer/ReqVar/CheckType").text = pp_text
	emit_signal("conncting")


func _on_ChoiceText_text_changed(new_text: String) -> void:
	current_choice.text = new_text
	emit_signal("conncting")


func _on_CheckValInput_text_changed(new_text: String) -> void:
	current_choice.check_val = new_text
	emit_signal("conncting")


func _on_ReqVarInput_text_changed(new_text: String) -> void:
	current_choice.required_var = new_text
	emit_signal("conncting")


func _on_ReqNodeInput_text_changed(new_text: String) -> void:
	current_choice.required_node = new_text
	emit_signal("conncting")


func _on_IsCondCheckBox_toggled(button_pressed: bool) -> void:
	undo_redo.create_action("toggle condition")
	undo_redo.add_do_method(self, "show_condition_toggle", button_pressed)
	undo_redo.add_undo_method(self, "show_condition_toggle", current_toogle)
	undo_redo.commit_action()
	current_toogle = button_pressed


func show_condition_toggle(button_pressed: bool) -> void:
	is_cond.pressed = button_pressed
	cond_box.visible = button_pressed
	current_choice.is_cond = button_pressed
	emit_signal("conncting")
