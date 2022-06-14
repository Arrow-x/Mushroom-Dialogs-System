tool
extends HSplitContainer

var flowchart: FlowChart

onready var graph_edit: GraphEdit


func _on_add_block_to_flow(new_block, node):
	flowchart.blocks.append(new_block)
	flowchart.nodes[node.title] = [node.offset, new_block, node]
	node.connect("graph_node_dragged", self, "_update_graph_node_offset")


func _update_graph_node_offset(new_offset, title):
	var _get_arr: Array = flowchart.nodes[title]
	_get_arr[0] = new_offset


func check_for_duplicates(name) -> bool:
	if flowchart.nodes.size() == 0:
		return false
	for key in flowchart.nodes:
		if key == name:
			return true
	return false


func set_flowchart(chart) -> void:
	if chart is FlowChart:
		flowchart = chart
		graph_edit = chart.graph_edit.instance()
		$GraphContainer.add_child(graph_edit)
		graph_edit.connect("add_block_to_flow", self, "_on_add_block_to_flow")
		$GraphContainer/GraphHeader/GraphHeaderContainer/AddBlockButton.connect(
			"button_down", graph_edit, "_on_AddBlockButton_pressed"
		)
		graph_edit.connect(
			"g_node_clicked",
			get_node("InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"),
			"on_GraphNode_clicked"
		)
		graph_edit.sync_flowchart_graph()
