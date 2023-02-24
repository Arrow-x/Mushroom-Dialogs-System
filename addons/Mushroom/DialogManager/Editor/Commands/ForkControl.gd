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


func get_command() -> Command:
	return current_fork


func _on_AddChoiceButton_pressed() -> void:
	adding_choice_action()


func adding_choice_action() -> void:
	undo_redo.create_action("adding_choice")
	undo_redo.add_do_method(self, "add_choice_contol")
	undo_redo.add_undo_method(self, "free_choice_control")
	undo_redo.commit_action()


func removing_choice_action(choice_c: Control) -> void:
	undo_redo.create_action("removing_choice")
	undo_redo.add_do_method(self, "free_choice_control", choice_c)
	undo_redo.add_undo_method(
		self, "add_choice_contol", choice_c.current_choice, choice_c.get_index()
	)
	undo_redo.commit_action()


func add_choice_contol(c: choice = null, idx: int = -1) -> void:
	var n_c: choice
	if c == null:
		n_c = choice.new()
		current_fork.choices.append(n_c)
	else:
		n_c = c
		current_fork.choices.append(n_c)
	create_choice_controle(n_c, idx)
	is_changed()


func free_choice_control(choice: Control = null) -> void:
	if choice == null:
		current_fork.choices.resize(current_fork.choices.size() - 1)
		choices_container.get_children()[-1].queue_free()
	else:
		current_fork.choices.erase(choice.current_choice)
		choice.queue_free()
	is_changed()


func set_up(f: fork_command, flowcharttab: Control, cb: block, ur: UndoRedo) -> void:
	current_fork = f
	fc = flowcharttab.flowchart
	graph = flowcharttab.graph_edit
	current_block = cb
	undo_redo = ur

	if f.choices != null:
		for i in f.choices:
			create_choice_controle(i)


func _on_connecting(sender) -> void:
	graph.update_block_flow(sender, current_fork)


func is_changed() -> void:
	current_fork.emit_signal("changed")


func create_choice_controle(choice: choice, idx: int = -1) -> void:
	var choice_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
	choice_control.connect("conncting", self, "_on_connecting", [current_block])
	choice_control.connect("removing_choice", self, "removing_choice_action")
	choices_container.add_child(choice_control)
	if idx != -1:
		choices_container.move_child(choice_control, idx)
	choice_control.set_up(choice, fc, undo_redo)
	if !choice.is_connected("changed", self, "is_changed"):
		choice.connect("changed", self, "is_changed")
