@tool
extends Control

@export var i_animation_control: PackedScene
@export var i_call_function_control: PackedScene
@export var i_change_ui_control: PackedScene
@export var i_condition_control: PackedScene
@export var i_fork_control: PackedScene
@export var i_general_container_command: PackedScene
@export var i_jump_control: PackedScene
@export var i_say_control: PackedScene
@export var i_set_var_control: PackedScene
@export var i_signal_control: PackedScene
@export var i_sound_control: PackedScene
@export var i_show_media_control: PackedScene

@export var graph_edit: GraphEdit

var undo_redo: EditorUndoRedoManager
var flowchart: FlowChart
var current_block: Block

var control: Control


func add_command_editor(current_item, in_flowshart: FlowChart, in_block: Block, in_undo):
	undo_redo = in_undo
	flowchart = in_flowshart
	current_block = in_block

	for c in get_children():
		c.queue_free()

	match current_item.get_class():
		"SayCommand":
			control = i_say_control.instantiate()
			add_child(control, true)
			control.set_up(current_item, undo_redo, flowchart, self)

		"ForkCommand":
			control = i_fork_control.instantiate()
			add_child(control, true)
			control.set_up(current_item, undo_redo, flowchart, current_block, graph_edit, self)

		"ConditionCommand", "IfElseCommand":
			control = i_condition_control.instantiate()
			add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"SetVarCommand":
			control = i_set_var_control.instantiate()
			add_child(control, true)
			control.set_up(current_item)

		"AnimationCommand":
			control = i_animation_control.instantiate()
			add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"JumpCommand":
			control = i_jump_control.instantiate()
			add_child(control, true)
			control.set_up(current_item, undo_redo, flowchart, self)

		"SoundCommand":
			control = i_sound_control.instantiate()
			add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"ChangeUICommand":
			control = i_change_ui_control.instantiate()
			add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		"CallFunctionCommand":
			control = i_call_function_control.instantiate()
			add_child(control, true)
			control.set_up(current_item)

		"SignalCommand":
			control = i_signal_control.instantiate()
			add_child(control, true)
			control.set_up(current_item)

		"GeneralContainerCommand":
			control = i_general_container_command.instantiate()
			add_child(control, true)
			control.set_up(current_item)

		"ElseCommand", "RandomCommand":
			pass

		"ShowMediaCommand":
			control = i_show_media_control.instantiate()
			add_child(control, true)
			control.set_up(current_item, undo_redo, self)

		_:
			push_error("CommandsTree: Unknow Command ", current_item.get_class())
			return


func command_undo_redo_caller(
	undo_redo_method: StringName,
	args: Array = [],
	input_obj = null,
	is_condition_container := false
) -> void:
	var current_ed: Control = get_child(0)
	var object

	if input_obj is Choice:
		for c in current_ed.choices_container.get_children():
			if not c.has_method("get_choice"):
				continue
			if c.get_choice() != input_obj:
				continue
			if is_condition_container == true:
				object = c.cond_box
				break
			object = c
			break
	elif input_obj is ConditionResource:
		var condition_editors: Array = []
		if current_ed.get_command() is ForkCommand:
			for c in current_ed.choices_container.get_children():
				if not c.has_method("get_choice"):
					continue
				condition_editors.append_array(c.cond_box.cond_editors_container.get_children())
		else:
			condition_editors = current_ed.cond_box.cond_editors_container.get_children()

		for c in condition_editors:
			if not c.has_method("get_conditional"):
				continue
			if c.get_conditional() != input_obj:
				continue
			object = c
			break
	else:
		object = current_ed.cond_box if is_condition_container == true else current_ed

	if object == null:
		push_error("Can't find the calling object")
		return
	if not object.has_method(undo_redo_method):
		push_error(object, " doesn't have ", undo_redo_method)
		return

	object.callv(undo_redo_method, args)
