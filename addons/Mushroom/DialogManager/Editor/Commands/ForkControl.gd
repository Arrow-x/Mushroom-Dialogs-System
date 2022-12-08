tool
extends Control
onready var choices_container: Control = $ScrollContainer/ChoicesContainer
onready var add_choice_button: Button = $ScrollContainer/ChoicesContainer/InfoBar/AddChoiceButton
onready var graph: GraphEdit

var current_fork: fork_command
var current_block: block
var fc: FlowChart
var undo_redo: UndoRedo
signal adding_choice


func _on_AddChoiceButton_pressed() -> void:
	# BUG adding or removing choice contorls doesn't work if another command was selected
	emit_signal("adding_choice")


func add_choice_contol() -> void:
	var choice_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
	choices_container.add_child(choice_control)
	choice_control.flowchart = fc
	var n_c: choice = choice.new()
	current_fork.choices.append(n_c)
	choice_control.current_choice = n_c
	choice_control.current_choice.connect("changed", self, "is_changed")
	choice_control.undo_redo = undo_redo
	choice_control.connect("conncting", self, "_on_connecting", [current_block])
	is_changed()


func free_choice_control() -> void:
	current_fork.choices.resize(current_fork.choices.size() - 1)
	choices_container.get_children()[-1].queue_free()
	is_changed()


func set_up(f: fork_command, flowcharttab: Control, cb: block, ur: UndoRedo) -> void:
	print("fork setUp")
	current_fork = f
	fc = flowcharttab.flowchart
	graph = flowcharttab.graph_edit
	current_block = cb
	undo_redo = ur

	if f.choices != null:
		for i in f.choices:
			var choice_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
			choices_container.add_child(choice_control)
			i.connect("changed", self, "is_changed")
			choice_control.set_up(i, flowcharttab, undo_redo)
			choice_control.connect("conncting", self, "_on_connecting", [current_block])


func _on_connecting(sender) -> void:
	graph.update_block_flow(sender, current_fork)


func is_changed() -> void:
	current_fork.emit_signal("changed")
