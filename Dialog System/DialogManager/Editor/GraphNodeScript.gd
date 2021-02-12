extends GraphNode

signal graph_node_meta (meta, title)

func _gui_input(event: InputEvent):
	if event.is_action_pressed("left_mouse"):
		emit_signal("graph_node_meta",self.get_meta("block"),title)
	
