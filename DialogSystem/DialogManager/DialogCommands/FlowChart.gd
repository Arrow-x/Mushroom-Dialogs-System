extends Resource
class_name FlowChart

export var first_block: Resource

#TODO each flowChart hold info about the blocks it contain, list of characters to be used, loacl variables
#maybe even a custom UI to be used by it

export var blocks: Array
export var local_vars: Array
export(Array, Resource) var characters
export var nodes: Dictionary
