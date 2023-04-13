tool
extends HSplitContainer

var flowchart: FlowChart
var flow_tabs: Tabs

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
		$GraphContainer/GraphHeader/GraphHeaderContainer/AddBlockButton.connect(
			"button_down", graph_edit, "_on_AddBlockButton_pressed"
		)
		graph_edit.connect(
			"g_node_clicked",
			get_node("InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"),
			"on_GraphNode_clicked"
		)
		graph_edit.connect("flow_changed", self, "changed_flowchart")
		graph_edit.connect("graph_node_close", self, "undo_redo_graph_edit")
		graph_edit.undo_redo = sent_undo_redo
		get_node("InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree").full_clear()
		graph_edit.sync_flowchart_graph(flowchart)


func _on_Button_pressed() -> void:
	if flowchart.resource_path == "":
		var _i: FileDialog = FileDialog.new()
		_i.resizable = true
		_i.set_size(Vector2(800, 500))
		_i.get_line_edit().set_text("new_resource.tres")
		_i.get_line_edit().select(0, 12)
		_i.connect("file_selected", self, "save_to_disc", [true])

		add_child(_i)
		_i.popup_centered()
		return

	save_to_disc(flowchart.resource_path)


func save_to_disc(path: String, overwrite := false) -> void:
	ResourceSaver.save(path, flowchart)

	if overwrite == true:
		flowchart.set_path(path)
		name = flowchart.get_name()
	if name.findn("(*)") != -1:
		name = name.rstrip("(*)")

	flow_tabs.set_tab_title(get_position_in_parent(), name)
	modified = false
	emit_signal("done_saving")


func changed_flowchart() -> void:
	if name.findn("(*)") == -1:
		name = String(name + "(*)")
		flow_tabs.set_tab_title(get_position_in_parent(), name)
		modified = true
