extends Panel

var _currnet_title : String setget change_title

func change_title(new_value):
	if new_value != _currnet_title :
		if get_child(0):
			get_child(0).queue_free()
	_currnet_title = new_value
