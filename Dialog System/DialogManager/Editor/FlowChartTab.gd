extends HSplitContainer

var flowchart : FlowChart
var flowchart_path : String

export var _graph_edit : NodePath
onready var graph_edit : GraphEdit = get_node(_graph_edit)

func _ready():
	graph_edit.connect("add_save_flow", self, "_on_add_save_flow")

func _on_add_save_flow(new_block):
	flowchart.blocks.append(new_block)
	ResourceSaver.save(flowchart_path, flowchart)
	
