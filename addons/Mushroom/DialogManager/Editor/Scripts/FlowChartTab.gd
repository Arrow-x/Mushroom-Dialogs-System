@tool
extends HSplitContainer

@export var graph_edit: GraphEdit
@export var add_block_button: Button
@export var command_tree: Tree
@export var enter_name_scene: PackedScene
@export var current_block_name: Label

var flowchart: FlowChart
var flow_tabs: TabBar
var undo_redo: EditorUndoRedoManager

var modified := false

signal done_saving


func check_for_duplicates(name) -> bool:
	for n in flowchart.blocks:
		if n == name:
			return true
	return false


func set_flowchart(chart: FlowChart, sent_undo_redo: EditorUndoRedoManager) -> void:
	flowchart = chart
	undo_redo = sent_undo_redo

	add_block_button.button_down.connect(graph_edit.on_add_block_button_pressed)

	graph_edit.g_node_clicked.connect(command_tree.initiate_tree_from_block)
	graph_edit.flow_changed.connect(changed_flowchart)
	graph_edit.undo_redo = sent_undo_redo

	command_tree.full_clear()
	command_tree.undo_redo = sent_undo_redo
	command_tree.graph_edit = graph_edit
	command_tree.flowchart_tab = self

	graph_edit.sync_flowchart_graph(flowchart)


func check_flowchart_path_before_save() -> void:
	if flowchart == null:
		return

	if flowchart.resource_path == "":
		flow_tabs.set_tab_title(get_index(), String(name + "(*)"))
		var _i: FileDialog = FileDialog.new()
		_i.resizable = true
		_i.set_size(Vector2(800, 500))
		_i.get_line_edit().set_text(String(name.trim_suffix("(*)") + ".tres"))
		_i.get_line_edit().select(0, 12)
		_i.file_selected.connect(save_flowchart_to_disc.bind(true))
		add_child(_i)
		_i.popup_centered()
		return

	save_flowchart_to_disc(flowchart.resource_path)


func save_flowchart_to_disc(path: String, overwrite := false) -> void:
	ResourceSaver.save(flowchart, path)
	if overwrite == true:
		flowchart.set_path(path)

	flow_tabs.set_tab_title(get_index(), flowchart.get_flowchart_name())
	modified = false
	done_saving.emit()


func changed_flowchart() -> void:
	if name.findn("(*)") == -1:
		flow_tabs.set_tab_title(get_index(), str(name + "(*)"))
		modified = true


func _on_rename_button_pressed() -> void:
	var enter_name: Window = enter_name_scene.instantiate()
	enter_name.line_edit.text = current_block_name.text
	enter_name.line_edit.select(0)
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.new_text_confirm.connect(_on_new_text_confirm)


func _on_new_text_confirm(new_title: String) -> void:
	if check_for_duplicates(new_title) or new_title.is_empty():
		await get_tree().create_timer(0.01).timeout
		push_error("The Title is a duplicate! or an Empty string")
		_on_rename_button_pressed()
		return

	undo_redo.create_action("Rename a block")
	undo_redo.add_do_method(self, "rename_block", new_title, current_block_name.text)
	undo_redo.add_undo_method(self, "rename_block", current_block_name.text, new_title)
	undo_redo.commit_action()


func rename_block(new_name: String, prev_name: String) -> void:
	graph_edit.graph_nodes[prev_name].title = new_name
	graph_edit.graph_nodes[new_name] = graph_edit.graph_nodes.get(prev_name)
	graph_edit.graph_nodes.erase(prev_name)

	var current_data := flowchart.blocks.get(prev_name)
	current_data.block.name = new_name
	flowchart.blocks[new_name] = current_data

	for output in flowchart.blocks[new_name].block.outputs:
		output.origin_block = new_name
	for input in flowchart.blocks[new_name].block.inputs:
		for choice in input.choices:
			choice.next_block = new_name

	current_block_name.text = new_name
	flowchart.blocks.erase(prev_name)
