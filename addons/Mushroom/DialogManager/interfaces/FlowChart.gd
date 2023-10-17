@tool
extends Resource
class_name FlowChart

@export var first_block: Block
@export var local_vars: Array
@export var characters: Array[Chararcter]
@export var blocks: Dictionary


func get_name() -> String:
	return self.resource_path.get_file().trim_suffix(".tres")


func get_block(b_name: String) -> Block:
	return blocks[b_name].block


func get_block_offset(b_name: String) -> Block:
	return blocks[b_name].offset
