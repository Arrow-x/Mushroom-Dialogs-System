tool
extends Resource
class_name FlowChart
export var graph_edit: PackedScene
export var first_block: Resource
export var local_vars: Array
export(Array, Resource) var characters
var graph_edit_node


func _init():
	var _graph_edit = load("res://addons/Mushroom/DialogManager/Editor/GraphEdit.tscn")
	graph_edit = _graph_edit.duplicate()


func get_name():
	return self.resource_path.get_file().trim_suffix(".tres")
