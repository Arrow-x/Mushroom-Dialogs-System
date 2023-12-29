@tool
extends HSplitContainer

@export var graph_edit: FlowChartGraphEdit
@export var add_block_button: Button
@export var command_tree: BlockCommandsTree
@export var enter_name_scene: PackedScene
@export var current_block_name: Label

var flowchart: FlowChart
var flow_tabs: TabBar
var undo_redo: EditorUndoRedoManager
var main_editor: Control

var modified := false

signal done_saving
signal f_tab_changed(flowchart: FlowChart)


func check_for_duplicates(name) -> bool:
	for n in flowchart.blocks:
		if n == name:
			return true
	return false


func set_flowchart(chart: FlowChart, sent_undo_redo: EditorUndoRedoManager, ed: Control) -> void:
	flowchart = chart
	undo_redo = sent_undo_redo
	main_editor = ed

	add_block_button.button_down.connect(graph_edit.on_add_block_button_pressed)

	graph_edit.g_node_clicked.connect(command_tree.initiate_tree_from_block)
	graph_edit.flow_changed.connect(changed_flowchart)
	graph_edit.undo_redo = sent_undo_redo
	graph_edit.clipboard = ed.block_clipboard

	command_tree.full_clear()
	command_tree.undo_redo = sent_undo_redo
	command_tree.graph_edit = graph_edit
	command_tree.flowchart_tab = self
	command_tree.tree_changed.connect(changed_flowchart)

	graph_edit.sync_flowchart_graph(flowchart)


func check_flowchart_path_before_save() -> void:
	if flowchart == null:
		return
	parse_string_var(flowchart)
	if flowchart.resource_path == "":
		flow_tabs.set_tab_title(get_index(), String(name + "(*)"))
		var file_dialog: FileDialog = FileDialog.new()
		file_dialog.resizable = true
		file_dialog.set_size(Vector2(800, 500))
		file_dialog.get_line_edit().set_text(String(name.trim_suffix("(*)") + ".tres"))
		file_dialog.get_line_edit().select(0, 12)
		file_dialog.file_selected.connect(save_flowchart_to_disc.bind(true))
		add_child(file_dialog)
		file_dialog.popup_centered()
		return

	save_flowchart_to_disc(flowchart.resource_path)


func save_flowchart_to_disc(path: String, overwrite := false) -> void:
	ResourceSaver.save(flowchart, path)
	if overwrite == true:
		flowchart.set_path(path)

	flow_tabs.set_tab_title(get_index(), flowchart.get_flowchart_name())
	modified = false
	done_saving.emit()


func changed_flowchart(f: FlowChart = null) -> void:
	if f == null:
		f_tab_changed.emit(flowchart)
	else:
		f_tab_changed.emit(f)
	if name.findn("(*)") == -1:
		if flow_tabs:
			flow_tabs.set_tab_title(get_index(), str(name + "(*)"))
			modified = true


func parse_string_var(input_flowchart: FlowChart) -> void:
	for block in input_flowchart.blocks:
		for input in input_flowchart.get_block(block).commands:
			if input is SayCommand:
				for e: ConditionResource in input.conditionals:
					e.parsed_check_val = get_type_from_string(e.check_val)
					e.parsed_args = get_type_from_string(e.args)
				var _get_args := get_args_from_placeholders(input.say)
				if _get_args != {}:
					input.placeholder_args[_get_args["args"]] = _get_args["parsed"]

			elif input is ForkCommand:
				for m: Choice in input.choices:
					for e: ConditionResource in m.conditionals:
						e.parsed_check_val = get_type_from_string(e.check_val)
						e.parsed_args = get_type_from_string(e.args)
					var _get_args := get_args_from_placeholders(m.text)
					if _get_args != {}:
						m.placeholder_args[_get_args["args"]] = _get_args["parsed"]

			elif input is ConditionCommand or input is IfElseCommand:
				for e: ConditionResource in input.conditionals:
					e.parsed_check_val = get_type_from_string(e.check_val)
					e.parsed_args = get_type_from_string(e.args)

			elif input is SetVarCommand:
				input.parsed_var_value = get_type_from_string(input.var_value)

			elif input is CallFunctionCommand:
				input.parsed_args = get_type_from_string(input.args)

			elif input is SignalCommand:
				input.singal_args_parsed = get_type_from_string(input.signal_args)


# TODO: batch this process
func get_type_from_string(value: String) -> Array:
	if value.is_empty():
		return []
	var raw = load("res://addons/Mushroom/DialogManager/misc/Args.gd").new()
	const INSTANCE_LOCATION := "res://addons/Mushroom/DialogManager/misc/args.tres"
	ResourceSaver.save(raw, INSTANCE_LOCATION)
	raw = null
	var file_read := FileAccess.open(INSTANCE_LOCATION, FileAccess.READ)
	var switch: bool = true
	var new_file: String = ""
	var current_line: String
	while switch == true:
		current_line = file_read.get_line()
		if current_line.begins_with("args ="):
			new_file += str("\n" + "args = " + "[" + value + "]")
			switch = false
			break
		new_file += current_line
		new_file += "\n"
	file_read.close()
	var file_write := FileAccess.open(INSTANCE_LOCATION, FileAccess.WRITE)
	file_write.store_string(new_file)
	file_write.close()
	var parsed_array: Array = load(INSTANCE_LOCATION).args
	DirAccess.remove_absolute(INSTANCE_LOCATION)
	return parsed_array


func get_args_from_placeholders(input: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile(r"{(.*?)}")
	var regex_resault := regex.search_all(input)
	var resault_array := []
	if regex_resault:
		for r in regex_resault:
			resault_array.append(r.get_string(1))
	var format_dictionary: Dictionary = {}
	for res: String in resault_array:
		if res.contains("(") and res.contains(")"):
			regex.compile(r"\((.*)\)")
			var func_arg_res := regex.search(res).get_string(1)
			if func_arg_res:
				return {"args": func_arg_res, "parsed": get_type_from_string(func_arg_res)}
	return {}
