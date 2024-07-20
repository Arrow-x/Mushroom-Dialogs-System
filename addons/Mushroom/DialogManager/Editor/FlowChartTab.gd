@tool
class_name FlowChartTabs extends Node

@export var graph_edit: GraphEdit
@export var add_block_button: Button
@export var command_tree: Tree
@export var enter_name_scene: PackedScene
@export var current_block_name: Label
@export var translation_lineedit: LineEdit
@export var export_button: Button

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
	plugin_config.load("res://addons/Mushroom/mushroom_configs.cfg")
	default_translation_location = plugin_config.get_value(
		"translation", "translation_file", "res://Translations/default.en.translation"
	)
	translation_lineedit.text = default_translation_location
	translation_lineedit.text_changed.connect(_on_translation_linedit_text_change)
	export_button.pressed.connect(translation_to_csv.bind(load(default_translation_location)))

	graph_edit.sync_flowchart_graph(flowchart)


func _on_translation_linedit_text_change(new_text: String) -> void:
	plugin_config.set_value("translation", "translation_file", new_text)
	default_translation_location = new_text


func check_flowchart_path_before_save() -> void:
	if flowchart == null:
		return
	parse_string_var(flowchart)
	replace_text_with_code(flowchart)
	if flowchart.resource_path == "":
		flow_tabs.set_tab_title(get_index(), String(name + "(*)"))
		var file_dialog: FileDialog = FileDialog.new()
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
	var default_translation: Translation = load(default_translation_location)
	if default_translation == null:
		push_error("FlowChartTabs: couldn't get the english translation file")
		return
	ResourceSaver.save(default_translation, default_translation_location)
	plugin_config.save("res://addons/Mushroom/mushroom_configs.cfg")
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
	for block: String in i_flowchart.blocks:
		replace_text_in_commands(
			i_flowchart.get_block(block).commands,
			block,
			i_flowchart.get_flowchart_name(),
			default_translation
		)


func replace_text_in_commands(
	commands: Array,
	block_name: String,
	flowchart_name: String,
	translation: Translation,
	last_code := ""
) -> void:
	var current_commands: Array
	var current_cmd: Command
	var current_choice: Choice
	var new_tr_code: StringName
	for c_idx: int in range(commands.size()):
		current_cmd = commands[c_idx]

		if current_cmd is SayCommand:
			new_tr_code = (
				last_code + flowchart_name + "___" + block_name + "___" + str(c_idx) + "___Say"
			)

			if current_cmd.tr_code != new_tr_code:
				translation.erase_message(StringName(current_cmd.tr_code))
				current_cmd.tr_code = new_tr_code

			translation.add_message(StringName(new_tr_code), current_cmd.say)

		elif current_cmd is ForkCommand:
			for choice_idx: int in range(current_cmd.choices.size()):
				current_choice = current_cmd.choices[choice_idx]
				new_tr_code = (
					last_code
					+ flowchart_name
					+ "___"
					+ block_name
					+ "___Fork___"
					+ str(c_idx)
					+ "___"
					+ str(choice_idx)
					+ "___Choice"
				)

				if current_choice.tr_code != new_tr_code:
					translation.erase_message(StringName(current_choice.tr_code))
					current_choice.tr_code = new_tr_code

				translation.add_message(new_tr_code, StringName(current_choice.choice_text))

		elif current_cmd is ContainerCommand:
			if current_cmd is GeneralContainerCommand:
				new_tr_code = (
					last_code
					+ flowchart_name
					+ "___"
					+ block_name
					+ "___"
					+ str(c_idx)
					+ "___"
					+ "General_Container_"
					+ current_cmd.name
				)
			elif current_cmd is RandomCommand:
				new_tr_code = (
					last_code
					+ flowchart_name
					+ "___"
					+ block_name
					+ "___"
					+ str(c_idx)
					+ "___"
					+ "Random"
				)
			elif current_cmd is ConditionCommand:
				new_tr_code = (
					last_code
					+ flowchart_name
					+ "___"
					+ block_name
					+ "___"
					+ str(c_idx)
					+ "___"
					+ "if"
				)
			elif current_cmd is IfElseCommand:
				new_tr_code = (
					last_code
					+ "___"
					+ flowchart_name
					+ "___"
					+ block_name
					+ "___"
					+ str(c_idx)
					+ "___"
					+ "else_if"
				)
			elif current_cmd is ElseCommand:
				new_tr_code = (
					last_code
					+ "___"
					+ flowchart_name
					+ "___"
					+ block_name
					+ "___"
					+ str(c_idx)
					+ "___"
					+ "else"
				)

			replace_text_in_commands(
				current_cmd.container_block.commands,
				block_name,
				flowchart_name,
				translation,
				new_tr_code
			)


func translation_to_csv(translation: Translation) -> void:
	if translation == null:
		push_error("FlowChartTab: default translation file is null")
		return
	var file_dialog: FileDialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.set_size(Vector2(800, 500))
	file_dialog.get_line_edit().set_text("default.csv")
	file_dialog.file_selected.connect(csv_location_chosen.bind(translation))
	add_child(file_dialog)
	file_dialog.popup_centered()


func csv_location_chosen(csv_file: String, translation: Translation) -> void:
	var msg_list := translation.get_message_list()
	var tr_msg_list := translation.get_translated_message_list()
	var file_write := FileAccess.open(csv_file, FileAccess.WRITE)
	if file_write == null:
		push_error("FlowChartTabs: ", error_string(FileAccess.get_open_error()))
		return
	file_write.store_string("key,en\n")
	for m: int in range(translation.get_message_count()):
		file_write.store_string(str(msg_list[m] + "," + '"' + tr_msg_list[m] + '"' + "\n"))


func parse_string_var(input_flowchart: FlowChart) -> void:
	#TODO: batch this process
	var get_args: Dictionary
	for block in input_flowchart.blocks:
		for input in input_flowchart.get_block(block).commands:
			if input is SayCommand:
				for e: ConditionResource in input.conditionals:
					e.parsed_check_val = get_type_from_string(e.check_val)
					e.parsed_args = get_type_from_string(e.args)
				get_args = get_args_from_placeholders(input.say)
				if get_args.is_empty() != true:
					input.placeholder_args.clear()
					for k: int in get_args:
						input.placeholder_args[get_args[k]["args"]] = get_args[k]["parsed"]

			elif input is ForkCommand:
				for m: Choice in input.choices:
					for e: ConditionResource in m.conditionals:
						e.parsed_check_val = get_type_from_string(e.check_val)
						e.parsed_args = get_type_from_string(e.args)
					get_args = get_args_from_placeholders(m.choice_text)
					if get_args.is_empty() != true:
						m.placeholder_args.clear()
						for k: int in get_args:
							m.placeholder_args[get_args[k]["args"]] = get_args[k]["parsed"]

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
	var ret_dict: Dictionary = {}
	if regex_resault:
		for r in regex_resault:
			resault_array.append(r.get_string(1))
	var format_dictionary: Dictionary = {}
	var res: String
	for i: int in range(resault_array.size()):
		res = resault_array[i]
		if res.contains("(") and res.contains(")"):
			regex.compile(r"\((.*)\)")
			var func_arg_res := regex.search(res).get_string(1)
			if func_arg_res:
				ret_dict[i] = {"args": func_arg_res, "parsed": get_type_from_string(func_arg_res)}
	return ret_dict


func deep_duplicate_block(block: Block) -> Block:
	var new_block: Block = Block.new()
	new_block.commands = []
	new_block.commands.resize(block.commands.size())
	for i in range(block.commands.size()):
		new_block.commands[i] = deep_duplicate_command(block.commands[i])
	return new_block


func deep_duplicate_command(cmd: Command) -> Command:
	var command: Command = cmd.duplicate()
	if cmd is ContainerCommand:
		if cmd is IfCommand:
			command.conditionals = duplicate_array(cmd.conditionals)
			for conditional in cmd.conditionals:
				conditional.parsed_check_val = []
				conditional.parsed_args = []
		command.container_block = deep_duplicate_block(cmd.container_block)
	elif cmd is ForkCommand:
		command.choices = duplicate_array(cmd.choices)
		command._init()
		for i: int in range(cmd.choices.size()):
			command.choices[i].choice_text = cmd.choices[i].choice_text
			command.choices[i].tr_code = ""
			command.choices[i].conditionals = duplicate_array(cmd.conditionals)

			for c_i: int in range(cmd.choices[i].conditionals.size()):
				command.choices[i].conditionals[c_i].parsed_check_val = []
				command.choices[i].conditionals[c_i].parsed_args = []
			command.choices[i].placeholder_args = {}
	elif cmd is SayCommand:
		command.say = cmd.say
		command.tr_code = ""
		command.conditionals = duplicate_array(cmd.conditionals)
		for i: int in range(cmd.conditionals.size()):
			command.conditionals[i].parsed_check_val = []
			command.conditionals[i].parsed_args = []
		command.placeholder_args = {}
	return command


func duplicate_array(input: Array) -> Array:
	var ret_arr: Array = []
	for d in input:
		if d is Object:
			if d.has_method("duplicate"):
				ret_arr.append(d.duplicate(true))
		else:
			ret_arr.append(d)
	return ret_arr
