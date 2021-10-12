extends FileDialog


func _ready():
	get_cancel().connect("pressed", self, "_on_FileDialog_Closed")
