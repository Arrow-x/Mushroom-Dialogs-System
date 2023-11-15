@tool
extends Panel

var _currnet_title: String: set = change_title


func change_title(new_value):
	if new_value != _currnet_title:
		if get_child_count() == 0:
			return
		if get_child(0):
			get_child(0).queue_free()
	_currnet_title = new_value
