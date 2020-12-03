extends Node

export (Resource) var _block


func _input(event):
	if event.is_action_pressed("interact"):
		if _block != null:
			DialogManager.send_dialog(_block)
