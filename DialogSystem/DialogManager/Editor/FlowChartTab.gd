extends HSplitContainer

var flowchart : FlowChart
var flowchart_path : String

export var _graph_edit : NodePath
onready var graph_edit : GraphEdit = get_node(_graph_edit)

func _ready():
	graph_edit.connect("add_block_to_flow", self, "_on_add_block_to_flow")

func _on_add_block_to_flow (new_block, node):
	flowchart.blocks.append(new_block)
	flowchart.nodes[node.title] = [node.offset, new_block]
	node.connect("graph_node_dragged", self,"_update_graph_node_offset")

func _update_graph_node_offset(new_offset, title ):
	var _get_arr : Array = flowchart.nodes[title]
	_get_arr[0] = new_offset 

func check_for_duplicates (name) -> bool:
	if flowchart.nodes.size() == 0 : 
		return false
	for key in flowchart.nodes:
		if key == name :
			return true
	return false


