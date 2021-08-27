extends GraphNode

signal graph_node_meta 
signal graph_node_dragged

func _gui_input(event: InputEvent):
	if event.is_action_pressed("left_mouse"):
		emit_signal("graph_node_meta",self.get_meta("block"),title)
	
func _on_GraphNode_dragged(_from, to):
	emit_signal("graph_node_dragged",to, self.to_string())
