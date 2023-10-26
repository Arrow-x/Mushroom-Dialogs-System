@tool
extends Control
@onready var choices_container: Control = $ScrollContainer/ChoicesContainer
@onready var add_choice_button: Button = $ScrollContainer/ChoicesContainer/InfoBar/AddChoiceButton
@onready var graph: GraphEdit

var current_fork: ForkCommand
var current_block: Block
var fc: FlowChart
var undo_redo: EditorUndoRedoManager

signal adding_choice


func _on_AddChoiceButton_pressed() -> void:
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


func add_choice_contol(c: Choice = null, idx: int = -1) -> void:
	var n_c: Choice
	if c == null:
		n_c = Choice.new()
		current_fork.choices.append(n_c)
	else:
		n_c = c
		current_fork.choices.append(n_c)
	create_choice_controle(n_c, idx)
	update_block_in_graph(current_block)


func free_choice_control(choice: Control = null) -> void:
	if choice == null:
		current_fork.choices.resize(current_fork.choices.size() - 1)
		choices_container.get_children()[-1].queue_free()
	else:
		current_fork.choices.erase(choice.current_choice)
		choice.queue_free()
	update_block_in_graph(current_block)


func set_up(
	f: ForkCommand, flowcharttab: Control, cb: Block, ur: EditorUndoRedoManager, ge: GraphEdit
) -> void:
	current_fork = f
	fc = flowcharttab.flowchart
	graph = ge
	current_block = cb
	undo_redo = ur

	current_fork.origin_block = current_block.name

	if f.choices != null:
		for i in f.choices:
			create_choice_controle(i)


func update_block_in_graph(sender: Block) -> void:
	graph.update_block_flow(sender, current_fork, true)
	is_changed()


func create_choice_controle(choice: Choice, idx: int = -1) -> void:
	var choice_control: Control = (
		load("res://addons/Mushroom/DialogManager/Editor/Commands/ChoiceControl.tscn").instantiate()
	)

	choice_control.conncting.connect(update_block_in_graph.bind(current_block))
	choice_control.removing_choice.connect(removing_choice_action)
	choices_container.add_child(choice_control)
	if idx != -1:
		choices_container.move_child(choice_control, idx)
	choice_control.set_up(choice, fc, undo_redo)
	if !choice.changed.is_connected(is_changed):
		choice.changed.connect(is_changed)


func get_command() -> Command:
	return current_fork


func is_changed() -> void:
	current_fork.changed.emit()
