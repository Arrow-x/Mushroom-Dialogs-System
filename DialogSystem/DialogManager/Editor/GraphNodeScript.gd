extends GraphNode

signal graph_node_meta
signal graph_node_dragged

var inputs: Array
var outputs: Array

var c_inputs: Array
var c_outputs: Array


func _gui_input(event: InputEvent):
	if event.is_action_pressed("left_mouse"):
		emit_signal("graph_node_meta", self.get_meta("block"), title)


func _on_GraphNode_dragged(_from, to):
	emit_signal("graph_node_dragged", to, self.title)


func delete_inputs(fork: fork_command):
	while inputs.find(fork) != -1:
		var idx = inputs.find(fork)
		set_slot_enabled_left(idx, false)
		# get_child(idx).queue_free()
		c_inputs[idx].queue_free()
		c_inputs.remove(idx)
		inputs.erase(fork)


func delete_outputs(fork: fork_command):
	while outputs.find(fork) != -1:
		var idx = outputs.find(fork)
		set_slot_enabled_right(idx, false)
		# get_child(idx).queue_free()
		c_outputs[idx].queue_free()
		c_outputs.remove(idx)
		outputs.erase(fork)
