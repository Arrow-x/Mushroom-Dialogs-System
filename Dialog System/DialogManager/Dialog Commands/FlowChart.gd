extends Resource
class_name FlowChart

#TODO each flowChart hold info about the blocks it contain, list of characters to be used, loacl variables
#maybe even a custom UI to be used by it

export (Array, Resource) var blocks : Array #this should be a dictionary with a defaul key "first_block" for easy deleting and naming of blocks
export (Array, Resource) var characters 

var local_vars : Array
