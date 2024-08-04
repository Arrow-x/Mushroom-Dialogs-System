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
	build_current_command_conditional_editors(cmd.conditionals)


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


func create_conditional_editor(conditional: ConditionResource) -> void:
	var cond_editor: Control = conditional_editor_scene.instantiate()
	cond_editor.set_up(conditional, undo_redo, commands_container)
	if cond_editors_container.get_child_count() == 0:
		cond_editor.sequencer_check.visible = false
		cond_editor.up_button.disabled = true
	cond_editors_container.add_child(cond_editor, true)
	cond_editor.close_pressed.connect(_on_conditional_close_button_pressed)
	cond_editor.change_index.connect(_on_change_conditional_index)
	conditional.changed.connect(func(): self.cond_changed.emit())


func add_conditional(conditional: ConditionResource = null, idx := -1) -> void:
	if idx == -1:
		current_command.conditionals.append(conditional)
	else:
		current_command.conditionals.insert(idx, conditional)
	build_current_command_conditional_editors(current_command.conditionals)


func build_current_command_conditional_editors(conditionals: Array) -> void:
	var _children := cond_editors_container.get_children()

	for e in _children:
		cond_editors_container.remove_child(e)

	for r in _children:
		r.queue_free()

	current_command.conditionals = conditionals
	for c in current_command.conditionals:
		create_conditional_editor(c)
	if cond_editors_container.get_child_count() > 0:
		cond_editors_container.get_children()[-1].down_button.disabled = true

	changed()


func remove_conditional(conditional: ConditionResource) -> void:
	for e in cond_editors_container.get_children():
		if e.get_conditional() == conditional:
			current_command.conditionals.erase(e.get_conditional())
			build_current_command_conditional_editors(current_command.conditionals)
	changed()


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
	build_current_command_conditional_editors(current_command.conditionals)


func changed() -> void:
	cond_changed.emit()
