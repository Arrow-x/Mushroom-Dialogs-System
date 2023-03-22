tool
extends GraphNode

signal graph_node_meta
signal dragging
signal node_closed

var c_inputs: Array
var c_outputs: Array

var block: block


func _ready() -> void:
	if !is_connected("raise_request", self, "_on_GraphNode_raise_request"):
		connect("raise_request", self, "_on_GraphNode_raise_request")

	if !is_connected("dragged", self, "_on_GraphNode_dragged"):
		connect("dragged", self, "_on_GraphNode_dragged")

	if !is_connected("close_request", self, "_on_GraphNode_closed"):
		connect("close_request", self, "_on_GraphNode_closed")


func block() -> block:
	return get_meta("block")


func delete_inputs(fork: fork_command):
	var idx = block.inputs.find(fork)
	set_slot_enabled_left(idx, false)
	if idx < c_inputs.size():
		# if c_inputs.size() != 0:
		c_inputs[idx].queue_free()
		c_inputs.remove(idx)
	block.inputs.erase(fork)


func delete_outputs(fork: fork_command):
	var idx = block.outputs.find(fork)
	set_slot_enabled_right(idx, false)
	if idx < c_inputs.size():
		# if c_outputs.size() != 0:
		c_outputs[idx].queue_free()
		c_outputs.remove(idx)
	block.outputs.erase(fork)


func add_g_node_output(fork: fork_command) -> void:
	if !block.outputs.has(fork):
		var cc: Control = Control.new()
		cc.rect_min_size = Vector2(10, 10)
		add_child(cc)
		cc.set_owner(self)
		block.outputs.append(fork)
		c_outputs.append(cc)
	set_slot_enabled_right(block.outputs.find(fork), true)
	set_slot_type_right(block.outputs.find(fork), 1)
	set_slot_color_right(block.outputs.find(fork), fork.f_color)


func add_g_node_input(fork: fork_command, delete_undo: bool = false) -> void:
	# doing an if or doesn't work for some reason so I had to for it
	if delete_undo == true:
		var cc: Control = Control.new()
		cc.rect_min_size = Vector2(10, 10)
		add_child(cc)
		cc.set_owner(self)
		c_inputs.append(cc)

	if block.inputs.has(fork) == false:
		block.inputs.append(fork)
		var cc: Control = Control.new()
		cc.rect_min_size = Vector2(10, 10)
		add_child(cc)
		cc.set_owner(self)
		c_inputs.append(cc)
	set_slot_enabled_left(block.inputs.find(fork), true)
	set_slot_type_left(block.inputs.find(fork), 1)
	set_slot_color_left(block.inputs.find(fork), fork.f_color)


func _on_GraphNode_raise_request() -> void:
	emit_signal("graph_node_meta", self)


func _on_GraphNode_dragged(from, too) -> void:
	emit_signal("dragging", from, too, self.title)


func _on_GraphNode_closed() -> void:
	emit_signal("node_closed", self)
