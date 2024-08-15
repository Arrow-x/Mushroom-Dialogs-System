@tool
extends VBoxContainer

@export var conditional_editor_scene: PackedScene
@export var cond_editors_container: Container

var current_command
var undo_redo: EditorUndoRedoManager
var commands_container: Node

signal cond_changed

enum {
	UP,
	DOWN,
}


func set_up(cmd, u_r: EditorUndoRedoManager, cmd_c: Node) -> void:
	current_command = cmd
	undo_redo = u_r
	commands_container = cmd_c
	build_current_command_conditional_editors()


func _on_add_conditional_button_pressed() -> void:
	var new_cond := ConditionResource.new()
	undo_redo.create_action("add a conditional")
	undo_redo.add_do_method(
		commands_container,
		"command_undo_redo_caller",
		"add_conditional",
		[new_cond],
		current_command,
		true
	)
	undo_redo.add_undo_method(
		commands_container,
		"command_undo_redo_caller",
		"remove_conditional",
		[new_cond],
		current_command,
		true
	)
	undo_redo.commit_action()


func _on_conditional_close_button_pressed(conditional: ConditionResource) -> void:
	undo_redo.create_action("remove conditional")
	undo_redo.add_do_method(
		commands_container,
		"command_undo_redo_caller",
		"remove_conditional",
		[conditional],
		current_command,
		true
	)
	undo_redo.add_undo_method(
		commands_container,
		"command_undo_redo_caller",
		"add_conditional",
		[conditional, current_command.conditionals.find(conditional)],
		current_command,
		true
	)
	undo_redo.commit_action()


func create_conditional_editor(conditional: ConditionResource) -> Control:
	var cond_editor: Control = conditional_editor_scene.instantiate()
	cond_editor.set_up(current_command, conditional, undo_redo, commands_container)
	cond_editor.close_pressed.connect(_on_conditional_close_button_pressed)
	cond_editor.change_index.connect(_on_change_conditional_index)
	if not conditional.changed.is_connected(changed):
		conditional.changed.connect(changed)
	cond_editors_container.add_child(cond_editor, true)
	return cond_editor


func build_current_command_conditional_editors() -> void:
	# HACK: remove the node from the tree first then mark it to be deleted, so
	# any operations on the nodetree can happend with the garentee that this
	# node is not there
	for e in cond_editors_container.get_children():
		cond_editors_container.remove_child(e)
		e.queue_free()

	if current_command.conditionals.is_empty():
		return

	var cond_control := create_conditional_editor(current_command.conditionals.front())
	cond_control.sequencer_check.visible = false
	cond_control.up_button.disabled = true
	for i: int in range(1, current_command.conditionals.size()):
		cond_control = create_conditional_editor(current_command.conditionals[i])
	cond_control.down_button.disabled = true
	changed()


func add_conditional(conditional: ConditionResource = null, idx := -1) -> void:
	if idx == -1:
		current_command.conditionals.append(conditional)
	else:
		current_command.conditionals.insert(idx, conditional)
	build_current_command_conditional_editors()


func remove_conditional(conditional: ConditionResource) -> void:
	current_command.conditionals.erase(conditional)
	build_current_command_conditional_editors()


func _on_change_conditional_index(dir: int, cond: ConditionResource) -> void:
	var idx: int = current_command.conditionals.find(cond)
	undo_redo.create_action("change conditionals order")
	undo_redo.add_do_method(
		commands_container,
		"command_undo_redo_caller",
		"change_conditional_index",
		[dir, idx],
		current_command,
		true
	)
	undo_redo.add_undo_method(
		commands_container,
		"command_undo_redo_caller",
		"change_conditional_index",
		[dir, idx],
		current_command,
		true
	)
	undo_redo.commit_action()


func change_conditional_index(dir: int, idx: int) -> void:
	var cond: ConditionResource = current_command.conditionals[idx]
	if cond == null:
		push_error("couldn't find ConditionResource")
		return
	if idx == -1:
		push_error("couldn't find ConditionResource")
		return

	if dir == UP:
		if idx == 0:
			return
		if current_command.conditionals.insert(idx - 1, cond) == OK:
			current_command.conditionals.remove_at(idx + 1)
		else:
			push_error("couldn't insert at indx", idx - 1, "in Array", current_command.conditionals)
			return

	elif dir == DOWN:
		if idx == current_command.conditionals.size() - 1:
			return
		if current_command.conditionals.insert(idx + 2, cond) == OK:
			current_command.conditionals.remove_at(idx)
		else:
			push_error("couldn't insert at indx", idx + 2, "in Array", current_command.conditionals)
			return
	build_current_command_conditional_editors()


func changed() -> void:
	cond_changed.emit()
