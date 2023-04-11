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
	remove_slot(block.inputs, c_inputs, false, fork)


func delete_outputs(fork: fork_command) -> void:
	var block: block = get_meta("block")
	remove_slot(block.outputs, c_outputs, true, fork)


# remove a slot from true:  right, false: left
func remove_slot(
	meta_slots: Array, control_slots: Array, left_or_right: bool, fork: fork_command
) -> void:
	var idx := meta_slots.find(fork)
	if left_or_right:
		set_slot_enabled_right(idx, false)
	else:
		set_slot_enabled_left(idx, false)
	if control_slots.size() > 0:
		control_slots[idx].queue_free()
		control_slots.remove(idx)
	meta_slots.erase(fork)

	for f in meta_slots:
		if left_or_right:
			set_slot_enabled_right(meta_slots.find(f), true)
			set_slot_type_right(meta_slots.find(f), 1)
			set_slot_color_right(meta_slots.find(f), f.f_color)
		else:
			set_slot_enabled_left(meta_slots.find(f), true)
			set_slot_type_left(meta_slots.find(f), 1)
			set_slot_color_left(meta_slots.find(f), f.f_color)


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
