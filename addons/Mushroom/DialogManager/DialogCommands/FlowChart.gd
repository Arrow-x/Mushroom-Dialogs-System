tool
extends Resource
class_name FlowChart

export var first_block: Resource
export var local_vars: Array
export(Array, Resource) var characters: Array
export var blocks: Dictionary


func get_name() -> String:
	return self.resource_path.get_file().trim_suffix(".tres")


func get_block(b_name: String) -> block:
	return blocks[b_name].block


func get_block_offset(b_name: String) -> block:
	return blocks[b_name].offset
