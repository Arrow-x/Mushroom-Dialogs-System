@tool
extends Node

@export var i_choice_control: PackedScene
@export var choices_container: VBoxContainer

var current_fork: ForkCommand
var current_block: Block
var flowchart: FlowChart
var undo_redo: EditorUndoRedoManager
var graph: GraphEdit
var commands_tree: Tree

signal adding_choice
enum { UP, DOWN }


func set_up(
	f: ForkCommand,
	ur: EditorUndoRedoManager,
	fc: FlowChart,
	cb: Block,
	ge: GraphEdit,
	cmd_tree: Tree
) -> void:
	current_fork = f
	flowchart = fc
	graph = ge
	current_block = cb
	undo_redo = ur
	commands_tree = cmd_tree

	current_fork.origin_block = current_block.name
	create_choices()


func _on_add_choice_button_pressed() -> void:
	undo_redo.create_action("adding_choice")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "add_choice_resource")
	undo_redo.add_undo_method(commands_tree, "command_undo_redo_caller", "free_choice_control")
	undo_redo.commit_action()


func removing_choice_action(choice_c: Control) -> void:
	undo_redo.create_action("removing_choice")
	undo_redo.add_do_method(
		commands_tree, "command_undo_redo_caller", "free_choice_control", [choice_c.current_choice]
	)
	undo_redo.add_undo_method(
		commands_tree,
		"command_undo_redo_caller",
		"add_choice_resource",
		[choice_c.current_choice, choice_c.get_index()]
	)
	undo_redo.commit_action()


func add_choice_resource(c: Choice = null, idx: int = -1) -> void:
	var n_c: Choice = Choice.new() if c == null else c
	if idx == -1:
		current_fork.choices.append(n_c)
	else:
		current_fork.choices.insert(idx, n_c)
	create_choices()
	update_block_in_graph(current_block)


func free_choice_control(choice: Choice = null) -> void:
	if choice == null:
		current_fork.choices.resize(current_fork.choices.size() - 1)
		choices_container.get_children()[-1].queue_free()
	else:
		current_fork.choices.erase(choice)
		for c in choices_container.get_children():
			if not c.has_method("get_choice"):
				continue
			if c.get_choice() == choice:
				c.queue_free()
	TranslationServer.get_translation_object("en").erase_message(choice.tr_code)
	update_block_in_graph(current_block)


func update_block_in_graph(sender: Block) -> void:
	graph.update_block_flow(sender, current_fork, true)
	is_changed()


func create_choice_control(choice: Choice) -> Control:
	var choice_control: Control = i_choice_control.instantiate()

	choice_control.fork = self
	choices_container.add_child(choice_control)

	choice_control.set_up(choice, flowchart, undo_redo, commands_tree)
	choice_control.change_index.connect(_on_change_index)
	if !choice.changed.is_connected(is_changed):
		choice.changed.connect(is_changed)
	return choice_control
	is_changed()


func _on_change_index(dir: int, choice: Choice) -> void:
	var idx: int = current_fork.choices.find(choice)
	undo_redo.create_action("Change Choice order")
	(
		undo_redo
		. add_do_method(
			commands_tree,
			"command_undo_redo_caller",
			"change_choice_index",
			[dir, idx],
			current_fork,
		)
	)
	(
		undo_redo
		. add_undo_method(
			commands_tree,
			"command_undo_redo_caller",
			"change_choice_index",
			[dir, idx],
			current_fork,
		)
	)
	undo_redo.commit_action()


func change_choice_index(dir: int, idx: int) -> void:
	var choice: Choice = current_fork.choices[idx]
	if choice == null:
		push_error("couldn't find Choice")
		return
	if idx == -1:
		push_error("couldn't find Choice")
		return

	if dir == UP:
		if idx == 0:
			return
		if current_fork.choices.insert(idx - 1, choice) == OK:
			current_fork.choices.remove_at(idx + 1)
		else:
			push_error("couldn't insert at indx", idx - 1, "in Array", current_fork.choices)
			return

	elif dir == DOWN:
		if idx == current_fork.choices.size() - 1:
			return
		if current_fork.choices.insert(idx + 2, choice) == OK:
			current_fork.choices.remove_at(idx)
		else:
			push_error("couldn't insert at indx", idx + 2, "in Array", current_fork.choices)
			return
	create_choices()


func create_choices() -> void:
	var choice_cont: Control
	for c in choices_container.get_children():
		c.queue_free()
	for i: int in range(current_fork.choices.size()):
		choice_cont = create_choice_control(current_fork.choices[i])
		if i == 0:
			choice_cont.up_button.disabled = true
	choice_cont.down_button.disabled = true


func get_command() -> Command:
	return current_fork


func is_changed() -> void:
	current_fork.changed.emit(current_fork)
