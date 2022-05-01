extends Command
class_name fork_command

var type: String = "fork"
var f_color : Color
export(Array, Resource) var choices


func _init():
	f_color = Color(randf(), randf(), randf())
