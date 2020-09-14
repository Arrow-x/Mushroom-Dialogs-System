extends GraphEdit

onready var parrent = $"."

func _on_AddBlockButton_pressed():
	var node = GraphNode.new()
	node.title = "new block"
	var _new_block = block.new()
	parrent.flowchart.blocks.append(_new_block)
	node.set_meta("block",_new_block)
	#node.connect("gui_input",$"FlowChartTabs/FlowChartTab/InspectorTabContainer/InspectorSplitContainer/InspectorVContainer/CommandsTree", "_recieve_block_metadeta",[node.get_meta("block")])
	add_child(node)
