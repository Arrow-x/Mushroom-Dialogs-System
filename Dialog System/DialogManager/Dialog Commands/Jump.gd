extends Command
class_name jump_command

var type : String = "jump"

export var jump_block : Resource
export var jump_index : int = 0

export var should_check : bool = false
export (String) var required_node 
export var required_var : String 
export var check_val : int 
export (String) var condition_type
