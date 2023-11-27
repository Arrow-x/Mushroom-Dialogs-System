@tool
extends Control

@export var cond_box: VBoxContainer
@export var cond_editors_container: VBoxContainer

var current_condition: ConditionCommand
var undo_redo: EditorUndoRedoManager
var commands_tree: Tree


func set_up(cc: ConditionCommand, u_r: EditorUndoRedoManager, cmd_tree: Tree) -> void:
	current_condition = cc
	undo_redo = u_r
	commands_tree = cmd_tree
	cond_box.set_up(current_condition, undo_redo, commands_tree)


func get_command() -> Command:
	return current_condition


func is_changed() -> void:
	current_condition.changed.emit()
