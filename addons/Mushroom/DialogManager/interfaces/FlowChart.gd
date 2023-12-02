@tool
extends Resource
class_name FlowChart

@export var first_block: Block
@export var local_vars: Dictionary
@export var characters: Array[Chararcter]
@export var blocks: Dictionary


func get_flowchart_name() -> String:
	var flowchart_name := self.get_path().get_file().trim_suffix(".tres")
	return flowchart_name


func get_block(b_name: String) -> Block:
	return blocks[b_name].block


func get_block_offset(b_name: String) -> Vector2:
	return blocks[b_name].offset
