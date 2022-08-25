tool
extends HSplitContainer

var flowchart: FlowChart
var flow_tabs: Tabs

var modified := false
var undo_redo: UndoRedo
var graph_edit: GraphEdit

signal done_saving


func set_graph_edit(in_graph_edit: GraphEdit):
	for g in $GraphContainer.get_children():
		if g is GraphEdit:
			g.queue_free()

	flowchart.graph_edit_node = in_graph_edit
	$GraphContainer/GraphHeader/GraphHeaderContainer/AddBlockButton.connect(
		"button_down", in_graph_edit, "_on_AddBlockButton_pressed"
	)
	in_graph_edit.connect(
		"g_node_clicked",
		get_node("InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"),
		"on_GraphNode_clicked"
	)
	in_graph_edit.connect("flow_changed", self, "changed_flowchart")
	in_graph_edit.connect("graph_node_close", self, "undo_redo_graph_edit")
	in_graph_edit.undo_redo = undo_redo
	get_node("InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree").full_clear()
	$GraphContainer.add_child(in_graph_edit)

	graph_edit = in_graph_edit
	graph_edit.sync_flowchart_graph()


func check_for_duplicates(name) -> bool:
	for n in flowchart.graph_edit_node.get_children():
		if n is GraphNode:
			if n.title == name:
				return true
	return false


func set_flowchart(chart, sent_undo_redo: UndoRedo) -> void:
	if chart is FlowChart:
		flowchart = chart
		undo_redo = sent_undo_redo
		set_graph_edit(chart.graph_edit.instance())


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


# BUG Godot Crashes when saving a graph_edit that has a node connected to itself
func save_to_disc(path: String, overwrite := false) -> void:
	var packed_scene = PackedScene.new()
	packed_scene.pack(graph_edit)
	flowchart.graph_edit = packed_scene
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
