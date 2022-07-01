tool
extends HSplitContainer

var flowchart: FlowChart

onready var graph_edit: GraphEdit


func check_for_duplicates(name) -> bool:
	for n in flowchart.graph_edit_node.get_children():
		if n is GraphNode:
			if n.title == name:
				return true
	return false


func set_flowchart(chart) -> void:
	if chart is FlowChart:
		flowchart = chart
		graph_edit = chart.graph_edit.instance()
		$GraphContainer.add_child(graph_edit)
		flowchart.graph_edit_node = graph_edit
		$GraphContainer/GraphHeader/GraphHeaderContainer/AddBlockButton.connect(
			"button_down", graph_edit, "_on_AddBlockButton_pressed"
		)
		graph_edit.connect(
			"g_node_clicked",
			get_node("InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"),
			"on_GraphNode_clicked"
		)
		graph_edit.sync_flowchart_graph()


func _on_Button_pressed() -> void:
	var packed_scene = PackedScene.new()
	packed_scene.pack(graph_edit)
	flowchart.graph_edit = packed_scene
	ResourceSaver.save(flowchart.resource_path, flowchart)
	if name.findn("(*)") != -1:
		name = name.rstrip("(*)")


func changed_flowchart():
	if name.findn("(*)") == -1:
		name = String(name + "(*)")
