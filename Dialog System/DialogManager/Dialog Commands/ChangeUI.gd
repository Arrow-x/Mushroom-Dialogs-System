extends Command
class_name change_ui_command

var type : String = "change_ui"
export (PackedScene) var next_UI
export (bool) var change_to_default = false

