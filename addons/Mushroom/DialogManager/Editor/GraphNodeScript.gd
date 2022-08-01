tool
extends GraphNode

signal graph_node_meta
signal dragging
signal node_closed

var inputs: Array
var outputs: Array

var c_inputs: Array
var c_outputs: Array


func _ready() -> void:
	if !is_connected("raise_request", self, "_on_GraphNode_raise_request"):
		connect("raise_request", self, "_on_GraphNode_raise_request")

	if !is_connected("dragged", self, "_on_GraphNode_dragged"):
		connect("dragged", self, "_on_GraphNode_dragged")

	if !is_connected("close_request", self, "_on_GraphNode_closed"):
		connect("close_request", self, "_on_GraphNode_closed")


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


func _on_GraphNode_raise_request() -> void:
	emit_signal("graph_node_meta", self.get_meta("block"), self.title)


func _on_GraphNode_dragged(from, too) -> void:
	emit_signal("dragging", from, too, self)


func _on_GraphNode_closed() -> void:
	print("closing")
	emit_signal("node_closed", self)
