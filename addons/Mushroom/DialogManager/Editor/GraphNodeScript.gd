tool
extends GraphNode

signal graph_node_meta
signal graph_node_dragged

var inputs: Array
var outputs: Array

var c_inputs: Array
var c_outputs: Array


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				emit_signal("graph_node_meta", self.get_meta("block"), self.title)


func delete_inputs(fork: fork_command):
	var idx = inputs.find(fork)
	set_slot_enabled_left(idx, false)
	c_inputs[idx].queue_free()
	c_inputs.remove(idx)
	inputs.erase(fork)


func delete_outputs(fork: fork_command):
	var idx = outputs.find(fork)
	set_slot_enabled_right(idx, false)
	c_outputs[idx].queue_free()
	c_outputs.remove(idx)
	outputs.erase(fork)
