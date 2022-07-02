tool
extends VBoxContainer
onready var choice_text: LineEdit = $HBoxContainer/ChoiceText
onready var next_block_menu: MenuButton = $HBoxContainer2/NextBlockList
onready var next_index_text: SpinBox = $HBoxContainer3/NextIndex
onready var delete_choice: Button = $HBoxContainer3/DeleteChoice

var current_choice: choice
var flowchart: FlowChart

signal conncting


func set_up(c: choice, fct: Control) -> void:
	flowchart = fct.flowchart
	current_choice = c
	choice_text.text = c.text
	if c.next_block != null:
		next_block_menu.text = c.next_block.name
	next_index_text.value = c.next_index


func _on_DeleteChoice_pressed():
	pass  # Replace with function body.


func _on_NextIndex_value_changed(value: float) -> void:
	current_choice.next_index = int(value)


func _on_NextBlockList_about_to_show() -> void:
	var menu: PopupMenu = next_block_menu.get_popup()
	if !menu.is_connected("index_pressed", self, "change_next_bloc"):
		menu.connect("index_pressed", self, "change_next_bloc", [menu])
	menu.clear()
	var _c := 0
	for b in flowchart.graph_edit_node.get_children():
		if b is GraphNode:
			menu.add_item(b.get_meta("block").name, _c)
			menu.set_item_metadata(_c, b.get_meta("block"))
			_c += 1


func change_next_bloc(index, m: PopupMenu) -> void:
	current_choice.next_block = m.get_item_metadata(index)
	next_block_menu.text = m.get_item_text(index)
	emit_signal("conncting")
	current_choice.emit_signal("changed")


func _on_ChoiceText_text_changed(new_text: String) -> void:
	current_choice.text = new_text
	current_choice.emit_signal("changed")
