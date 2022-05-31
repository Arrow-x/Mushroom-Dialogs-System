extends Command
class_name condition_command

var type: String = "condition"
export var condition_block: Resource

export(String) var required_node
export var required_var: String
export var check_val: int
export(String) var condition_type
