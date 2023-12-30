@tool
extends Resource
class_name Block

#each block should now what flowchart it is parented to
@export var name: StringName
@export var commands: Array
@export var rand_times := -1

#these are used when a block is used as condtional block
@export var _next_block: Block
@export var _next_indexer: int = 0

@export var inputs: Array[ForkCommand]
@export var outputs: Array[ForkCommand]
