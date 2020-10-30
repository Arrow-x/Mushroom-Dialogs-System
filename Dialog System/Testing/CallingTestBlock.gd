extends Node

export (Resource) var _block
onready var debug = $Label


func _process(delta):
	debug.text = String(DialogManager._skipped) 


func _input(event):
	if event.is_action_pressed("interact"):
		if _block != null:
			DialogManager.send_dialog(_block)
