@tool
extends HSplitContainer

var flowchart: FlowChart
var flow_tabs: TabBar

var modified := false

signal done_saving


func check_for_duplicates(name) -> bool:
	for n in flowchart.blocks:
		if n == name:
			return true
	return false


func set_flowchart(chart, sent_undo_redo: UndoRedo) -> void:
	if chart is FlowChart:
		flowchart = chart
		var graph_edit: GraphEdit = get_node("GraphContainer/GraphEdit")
		$GraphContainer/GraphHeader/GraphHeaderContainer/AddBlockButton.button_down.connect(
			graph_edit._on_AddBlockButton_pressed
		)
		graph_edit.g_node_clicked.connect(
			(
				get_node("InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree")
				. initeate_Tree_from_Block
			)
		)
		graph_edit.flow_changed.connect(changed_flowchart)
		graph_edit.undo_redo = sent_undo_redo

		var command_tree: Tree = get_node(
			"InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"
		)
		command_tree.full_clear()
		command_tree.undo_redo = sent_undo_redo
		command_tree.graph_edit = graph_edit
		command_tree.flowchart_tab = self

		graph_edit.sync_flowchart_graph(flowchart)


func check_flowchart_path_before_save() -> void:
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

	flow_tabs.set_tab_title(get_index(), flowchart.get_name())
	modified = false
	emit_signal("done_saving")


func changed_flowchart() -> void:
	if name.findn("(*)") == -1:
		flow_tabs.set_tab_title(get_index(), str(name + "(*)"))
		modified = true
