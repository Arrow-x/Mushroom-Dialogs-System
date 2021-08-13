extends GraphEdit

onready var graph_node : PackedScene = load("res://DialogManager/Editor/GraphNode.tscn")

var node_offset : int = 0

signal add_save_flow 

	
func _on_AddBlockButton_pressed(title : String = "new block"):
	var node : GraphNode = graph_node.instance()
	node.title = title
	node.offset = Vector2(node_offset, 0)
	if node_offset < 240:
		node_offset = node_offset + 120
	else:
		node_offset = 0
	var _new_block = block.new()
	node.set_meta("block",_new_block)
	emit_signal("add_save_flow",[_new_block])
	node.connect("graph_node_meta",get_node("../../InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"),"_on_GraphNode_graph_node_meta")
	add_child(node)
