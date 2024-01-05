@tool
extends HSplitContainer
class_name FlowChartTabs

@export var graph_edit: GraphEdit
@export var add_block_button: Button
@export var command_tree: Tree
@export var enter_name_scene: PackedScene
@export var current_block_name: Label
@export var translation_lineedit: LineEdit

var flowchart: FlowChart
var flow_tabs: TabBar
var undo_redo: EditorUndoRedoManager
var main_editor: Control
var plugin_config: ConfigFile
var default_translation_location: String

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
	main_editor.block_clipboard = {}

	command_tree.full_clear()
	command_tree.undo_redo = sent_undo_redo
	command_tree.graph_edit = graph_edit
	command_tree.flowchart_tab = self
	command_tree.tree_changed.connect(changed_flowchart)

	plugin_config = ConfigFile.new()
	plugin_config.load("res://addons/Mushroom/plugin.cfg")
	default_translation_location = plugin_config.get_value(
		"plugin", "translation_file", "res://Translations/test.en.translation"
	)
	translation_lineedit.text = default_translation_location
	translation_lineedit.text_changed.connect(_on_translation_linedit_text_change)

	graph_edit.sync_flowchart_graph(flowchart)


func _on_translation_linedit_text_change(new_text: String) -> void:
	plugin_config.set_value("plugin", "translation_file", new_text)
	default_translation_location = new_text


func check_flowchart_path_before_save() -> void:
	if flowchart == null:
		return
	parse_string_var(flowchart)
	replace_text_with_code(flowchart)
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
	plugin_config.save("res://addons/Mushroom/plugin.cfg")
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


func replace_text_with_code(i_flowchart: FlowChart) -> void:
	var default_translation: Translation = load(default_translation_location)
	if default_translation == null:
		push_error("FlowChartTabs: couldn't get the english translation file")
		return
	var current_commands: Array
	var current_cmd: Command
	var current_choice: Choice
	var new_tr_code: StringName
	for block: String in i_flowchart.blocks:
		current_commands = i_flowchart.get_block(block).commands
		for c_idx: int in range(i_flowchart.get_block(block).commands.size()):
			current_cmd = current_commands[c_idx]

			if current_cmd is SayCommand:
				new_tr_code = (
					"Say_" + i_flowchart.get_flowchart_name() + "_" + block + "_" + str(c_idx)
				)

				if current_cmd.tr_code != new_tr_code:
					default_translation.erase_message(StringName(current_cmd.tr_code))
					current_cmd.tr_code = new_tr_code

				default_translation.add_message(StringName(new_tr_code), current_cmd.say)

			elif current_cmd is ForkCommand:
				for choice_idx: int in range(current_cmd.choices.size()):
					current_choice = current_cmd.choices[choice_idx]
					new_tr_code = (
						"Choice_"
						+ str(choice_idx)
						+ "_in_Fork_"
						+ i_flowchart.get_flowchart_name()
						+ "_"
						+ block
						+ "_"
						+ str(c_idx)
					)

					if current_choice.tr_code != new_tr_code:
						default_translation.erase_message(StringName(current_choice.tr_code))
						current_choice.tr_code = new_tr_code

					default_translation.add_message(new_tr_code, StringName(current_choice.text))

	for c: Chararcter in i_flowchart.characters:
		default_translation.add_message(StringName(c.name), StringName(c.name))

	ResourceSaver.save(default_translation, default_translation_location)


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


func deep_duplicate_block(block: Block) -> Block:
	var new_block: Block = block.duplicate(true)
	new_block.commands = deep_duplicate_commands(new_block.commands)
	new_block.inputs = []
	new_block.outputs = []
	return new_block


func deep_duplicate_commands(block_commnds: Array) -> Array:
	var ret_array = duplicate_array(block_commnds)
	for command in ret_array:
		if command is ContainerCommand:
			if command is IfCommand:
				command.conditionals = duplicate_array(command.conditionals)
				for conditional in command.conditionals:
					conditional.parsed_check_val = duplicate_array(conditional.parsed_check_val)
					conditional.parsed_args = duplicate_array(conditional.parsed_args)
			command.container_block = deep_duplicate_block(command.container_block)
		elif command is ForkCommand:
			command.choices = duplicate_array(command.choices)
			for choice in command.choices:
				choice.conditionals = duplicate_array(choice.conditionals)
				# WARN:  sus
				choice.placeholder_args = choice.placeholder_args.duplicate(true)

				for conditional in choice.conditionals:
					conditional.parsed_check_val = duplicate_array(conditional.parsed_check_val)
					conditional.parsed_args = duplicate_array(conditional.parsed_args)
		elif command is SayCommand:
			command.conditionals = duplicate_array(command.conditionals)
			for conditional in command.conditionals:
				conditional.parsed_check_val = duplicate_array(conditional.parsed_check_val)
				conditional.parsed_args = duplicate_array(conditional.parsed_args)
			command.placeholder_args = command.placeholder_args.duplicate(true)
	return ret_array


func duplicate_array(input: Array) -> Array:
	var ret_arr: Array = []
	for d in input:
		if d is Object:
			if d.has_method("duplicate"):
				ret_arr.append(d.duplicate(true))
		else:
			ret_arr.append(d)
	return ret_arr
