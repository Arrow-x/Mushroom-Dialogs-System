extends Resource
class_name FlowChart

export var first_block : Resource #this is unnessary 

#TODO each flowChart hold info about the blocks it contain, list of characters to be used, loacl variables
#maybe even a custom UI to be used by it

var blocks : Array #this should be a dictionary with a defaul key "first_block" for easy deleting and naming of blocks
var local_vars : Array
export (Array, Resource) var characters 
