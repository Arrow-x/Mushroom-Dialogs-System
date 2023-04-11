tool
extends GraphNode

signal graph_node_meta
signal dragging
signal node_closed

var c_inputs: Array
var c_outputs: Array


func _ready() -> void:
	if !is_connected("raise_request", self, "_on_GraphNode_raise_request"):
		connect("raise_request", self, "_on_GraphNode_raise_request")

	if !is_connected("dragged", self, "_on_GraphNode_dragged"):
		connect("dragged", self, "_on_GraphNode_dragged")

	if !is_connected("close_request", self, "_on_GraphNode_closed"):
		connect("close_request", self, "_on_GraphNode_closed")


func delete_inputs(fork: fork_command) -> void:
	var block: block = get_meta("block")
	var idx := block.inputs.find(fork)
	set_slot_enabled_left(idx, false)
	if idx < c_inputs.size():
		c_inputs[idx].queue_free()
		c_inputs.remove(idx)
	block.inputs.erase(fork)


func delete_outputs(fork: fork_command) -> void:
	var block: block = get_meta("block")
func add_g_node_output(fork: fork_command, mod_block: bool = true) -> void:
	var block: block = get_meta("block")
	if mod_block:
		if !block.outputs.has(fork):
			block.outputs.append(fork)
	var idx := block.outputs.find(fork)
	if !is_slot_enabled_right(idx):
		create_contorl_for_g_node_connection(c_outputs, fork)
		set_slot_enabled_right(idx, true)
		set_slot_type_right(idx, 1)
		set_slot_color_right(idx, fork.f_color)


func add_g_node_input(fork: fork_command, mod_block: bool = true) -> void:
	var block: block = get_meta("block")
	if mod_block:
		if !block.inputs.has(fork):
			block.inputs.append(fork)
	var idx := block.inputs.find(fork)
	if !is_slot_enabled_left(idx):
		create_contorl_for_g_node_connection(c_inputs, fork)
		set_slot_enabled_left(idx, true)
		set_slot_type_left(idx, 1)
		set_slot_color_left(idx, fork.f_color)


func create_contorl_for_g_node_connection(io_c: Array, fork: fork_command) -> void:
	var cc: Control = Control.new()
	cc.rect_min_size = Vector2(10, 10)
	add_child(cc)
	cc.set_owner(self)
	io_c.append(cc)


func _on_GraphNode_raise_request() -> void:
	emit_signal("graph_node_meta", self)


func _on_GraphNode_dragged(from, too) -> void:
	emit_signal("dragging", from, too, self.title)


func _on_GraphNode_closed() -> void:
	emit_signal("node_closed", self)
