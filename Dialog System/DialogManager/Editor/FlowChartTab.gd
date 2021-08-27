extends HSplitContainer

var flowchart : FlowChart
var flowchart_path : String

export var _graph_edit : NodePath
onready var graph_edit : GraphEdit = get_node(_graph_edit)
func _ready():
	graph_edit.connect("add_block_to_flow", self, "_on_add_block_to_flow")

func _on_add_block_to_flow (new_block, node):
	flowchart.blocks.append(new_block)
	flowchart.nodes[node.to_string()] = [node.offset, new_block, node.title]
	node.connect("graph_node_dragged", self,"_update_graph_node_offset")
func update_flowchar():
	ResourceSaver.save(flowchart_path, flowchart)
	
func _on_Save_scene() -> void:
	var current_scene := PackedScene.new()
	var result = current_scene.pack(self)
	if result == OK:
		get_node("/root/Editor/").file_dialog_save(current_scene)
	if result != OK:
		push_error("An error occurred while saving the scene to disk.")

func _on_Open_pressed() -> void:
	var current_scene := PackedScene.new()
	var result = current_scene.pack(self)
	get_node("/root/Editor/").file_dialog_save(result, "Open")
	
func _update_graph_node_offset(new_offset, id):
	var _get_arr : Array = flowchart.nodes[id]
	_get_arr[0] = new_offset 

func check_for_duplicates (name) -> bool:
	var _get_arr : Array 
	if flowchart.nodes.size() == 0 : 
		return false
	for key in flowchart.nodes:
		_get_arr = flowchart.nodes[key]
		print(_get_arr[0], _get_arr[1], _get_arr[2]) 
		if _get_arr[2] == name :
			print("function returns that the name is a duplicate")
			return true
	print("function says eh it is fine")
	return false


