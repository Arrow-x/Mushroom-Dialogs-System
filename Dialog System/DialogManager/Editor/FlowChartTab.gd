extends HSplitContainer

var flowchart : FlowChart
var flowchart_path : String

export var _graph_edit : NodePath
onready var graph_edit : GraphEdit = get_node(_graph_edit)
func _ready():
	graph_edit.connect("add_block_to_flow", self, "_on_add_block_to_flow")

func _on_add_block_to_flow (new_block):
	flowchart.blocks.append(new_block)
	
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
