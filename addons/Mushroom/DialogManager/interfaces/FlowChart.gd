@tool
extends Resource
class_name FlowChart

@export var first_block: Block
@export var local_vars: Dictionary
@export var characters: Array[Chararcter]
@export var blocks: Dictionary
@export var blocks_offset: Dictionary


func get_flowchart_name() -> String:
	var flowchart_name := self.get_path().get_file().trim_suffix(".tres")
	return flowchart_name


func get_block(b_name: String) -> Block:
	if b_name:
		return blocks[b_name]
	push_error("flowchart: ", get_flowchart_name(), "can't get_block with string: ", b_name)
	return null


func get_block_offset(b_name: String) -> Vector2:
	if b_name:
		return blocks_offset[b_name]
	push_error("flowchart: ", get_flowchart_name(), "can't get_block with string: ", b_name)
	return Vector2.ZERO
