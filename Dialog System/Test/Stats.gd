extends Node

var sthr = 16
var dex = 15
var con = 12

export var testblock: Resource

func _input(event):
	if event.is_action_pressed("ui_accept"):
		DialogManager.send_dialog(testblock)
