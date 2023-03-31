tool
extends VBoxContainer
onready var choice_text: LineEdit = $HBoxContainer/ChoiceText
onready var next_block_menu: MenuButton = $HBoxContainer2/NextBlockList
onready var next_index_text: SpinBox = $HBoxContainer3/NextIndex
onready var delete_choice: Button = $HBoxContainer3/DeleteChoice

var current_choice: choice
var flowchart: FlowChart
var undo_redo: UndoRedo

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


func _on_DeleteChoice_pressed():
	emit_signal("removing_choice", self)


func _on_NextIndex_value_changed(value: float) -> void:
	current_choice.next_index = int(value)


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


func _on_ChoiceText_text_changed(new_text: String) -> void:
	current_choice.text = new_text
