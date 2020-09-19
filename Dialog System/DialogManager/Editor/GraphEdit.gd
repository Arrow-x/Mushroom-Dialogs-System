extends GraphEdit

onready var parrent = $"."

func _on_AddBlockButton_pressed():
	var node = GraphNode.new()
	node.title = "new block"
	var _new_block = block.new()
	node.set_meta("block",_new_block)
	#add the block to the flowchart list
	node.connect("gui_input",parrent,"_on_graph_node_clicked")
	add_child(node)
