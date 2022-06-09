extends Command
class_name cond_choice

var type: String = "cond_choice"
export(String, MULTILINE) var text

export var next_block: Resource
export var next_index: int = 0

export(String) var required_node
export var required_var: String
export var check_val: int
export(String) var condition_type
