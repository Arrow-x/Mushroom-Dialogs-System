tool
extends Resource
class_name FlowChart

export var first_block: Resource
export var local_vars: Array
export(Array, Resource) var characters: Array
export var blocks: Dictionary


func get_name():
	return self.resource_path.get_file().trim_suffix(".tres")
