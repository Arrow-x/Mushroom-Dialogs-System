tool
extends Resource
class_name block

#each block should now what flowchart it is parented to
export var name: String
export(Array, Resource) var commands: Array

#these are used when a block is used as condtional block
export var _next_block: Resource
export var _next_indexer: int = 0

export var inputs: Array
export var outputs: Array


