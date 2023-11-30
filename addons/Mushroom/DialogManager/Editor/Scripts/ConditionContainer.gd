@tool
extends VBoxContainer

@export var conditional_editor_scene: PackedScene
@export var cond_editors_container: Container

var current_command
var undo_redo: EditorUndoRedoManager
var commands_tree: Tree


func set_up(cmd, u_r: EditorUndoRedoManager, cmd_tree: Tree) -> void:
	current_command = cmd
	undo_redo = u_r
	commands_tree = cmd_tree
	build_current_command_conditional_editors(cmd.conditionals)


func _on_add_conditional_button_pressed() -> void:
	var new_cond := ConditionResource.new()
	undo_redo.create_action("add a conditional")
	undo_redo.add_do_method(
		commands_tree,
		"command_undo_redo_caller",
		"add_conditional",
		[new_cond],
		current_command,
		true
	)
	undo_redo.add_undo_method(
		commands_tree,
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
		commands_tree,
		"command_undo_redo_caller",
		"remove_conditional",
		[conditional],
		current_command,
		true
	)
	undo_redo.add_undo_method(
		commands_tree,
		"command_undo_redo_caller",
		"add_conditional",
		[conditional, current_command.conditionals.find(conditional)],
		current_command,
		true
	)
	undo_redo.commit_action()


func create_conditional_editor(conditional: ConditionResource) -> void:
	var cond_editor: Control = conditional_editor_scene.instantiate()
	cond_editor.set_up(conditional, undo_redo, commands_tree)
	if cond_editors_container.get_child_count() == 0:
		cond_editor.sequence_container.visible = false
	cond_editors_container.add_child(cond_editor, true)
	cond_editor.close_pressed.connect(_on_conditional_close_button_pressed)


func add_conditional(conditional: ConditionResource = null, idx := -1) -> void:
	if idx == -1:
		current_command.conditionals.append(conditional)
	else:
		current_command.conditionals.insert(idx, conditional)
	build_current_command_conditional_editors(current_command.conditionals)


func build_current_command_conditional_editors(conditionals: Array[ConditionResource]) -> void:
	for e in cond_editors_container.get_children():
		e.queue_free()
	await get_tree().create_timer(0.001).timeout
	current_command.conditionals = conditionals
	for c in current_command.conditionals:
		create_conditional_editor(c)


func remove_conditional(conditional: ConditionResource) -> void:
	for e in cond_editors_container.get_children():
		if e.get_conditional() == conditional:
			current_command.conditionals.erase(e.get_conditional())
			build_current_command_conditional_editors(current_command.conditionals)
