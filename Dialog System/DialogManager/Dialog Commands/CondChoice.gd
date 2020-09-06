extends Resource
class_name cond_choice

var type : String = "cond_choice"
export (String, MULTILINE) var text 

export var next_block : block
export var next_index : int = 0

export (String) var required_node 
export var required_var : String 
export var check_val : int  
export (String) var condition_type
