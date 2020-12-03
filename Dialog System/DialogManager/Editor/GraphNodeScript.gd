extends GraphNode

signal graph_node_meta (meta)

func _gui_input(event: InputEvent):
	if event.is_action_pressed("left_mouse"):
		print("clicked")
		emit_signal("graph_node_meta",self.get_meta("block"))
	
