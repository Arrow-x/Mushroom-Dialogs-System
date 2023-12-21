@tool
extends Control

@export var cond_box: VBoxContainer
@export var cond_editors_container: VBoxContainer

var current_condition: IfCommand
var undo_redo: EditorUndoRedoManager
var commands_tree: Tree


func set_up(cc: IfCommand, u_r: EditorUndoRedoManager, cmd_tree: Tree) -> void:
	current_condition = cc
	undo_redo = u_r
	commands_tree = cmd_tree
	if current_condition.conditionals.is_empty():
		var new_cond := ConditionResource.new()
		new_cond.changed.connect(is_changed)
		current_condition.conditionals.append(new_cond)
	cond_box.set_up(current_condition, undo_redo, commands_tree)
	cond_box.cond_changed.connect(is_changed)


func get_command() -> Command:
	return current_condition


func is_changed() -> void:
	current_condition.changed.emit(current_condition)
