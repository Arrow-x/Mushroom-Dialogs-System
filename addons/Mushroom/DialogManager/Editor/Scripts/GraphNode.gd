@tool
extends GraphNode

var c_inputs: Array
var c_outputs: Array

var connected_destenation_blocks: Array

signal graph_node_meta
signal dragging
signal node_closed


func _ready() -> void:
	if !raise_request.is_connected(_on_GraphNode_raise_request):
		raise_request.connect(_on_GraphNode_raise_request)

	if !dragged.is_connected(_on_GraphNode_dragged):
		dragged.connect(_on_GraphNode_dragged)

	if !close_request.is_connected(_on_GraphNode_closed):
		close_request.connect(_on_GraphNode_closed)


func delete_inputs(fork: ForkCommand) -> void:
	var block: Block = get_meta("block")
	remove_slot(block.inputs, c_inputs, true, fork)


func delete_outputs(fork: ForkCommand) -> void:
	var block: Block = get_meta("block")
	remove_slot(block.outputs, c_outputs, false, fork)


# remove a slot from true:  right, false: left
func remove_slot(meta_slots: Array, control_slots: Array, left: bool, fork: ForkCommand) -> void:
	var idx := meta_slots.find(fork)

	for f in meta_slots:
		if left:
			set_slot_enabled_left(meta_slots.find(f), false)
		else:
			set_slot_enabled_right(meta_slots.find(f), false)

	if control_slots.size() > 0:
		control_slots[idx].queue_free()
		control_slots.remove_at(idx)
	meta_slots.erase(fork)

	for f in meta_slots:
		if left:
			set_slot_enabled_left(meta_slots.find(f), true)
			set_slot_type_left(meta_slots.find(f), 1)
			set_slot_color_left(meta_slots.find(f), f.f_color)
		else:
			set_slot_enabled_right(meta_slots.find(f), true)
			set_slot_type_right(meta_slots.find(f), 1)
			set_slot_color_right(meta_slots.find(f), f.f_color)


func add_g_node_output(fork: ForkCommand) -> void:
	var block: Block = get_meta("block")
	if !block.outputs.has(fork):
		block.outputs.append(fork)
	var idx := block.outputs.find(fork)
	if !is_slot_enabled_right(idx):
		create_contorl_for_g_node_connection(c_outputs, fork)
		set_slot_enabled_right(idx, true)
		set_slot_type_right(idx, 1)
		set_slot_color_right(idx, fork.f_color)


func add_g_node_input(fork: ForkCommand) -> void:
	var block: Block = get_meta("block")
	if !block.inputs.has(fork):
		block.inputs.append(fork)
	var idx := block.inputs.find(fork)
	if !is_slot_enabled_left(idx):
		create_contorl_for_g_node_connection(c_inputs, fork)
		set_slot_enabled_left(idx, true)
		set_slot_type_left(idx, 1)
		set_slot_color_left(idx, fork.f_color)


func create_contorl_for_g_node_connection(io_c: Array, fork: ForkCommand) -> void:
	var cc: Control = Control.new()
	cc.custom_minimum_size = Vector2(10, 10)
	add_child(cc)
	cc.set_owner(self)
	io_c.append(cc)


func _on_GraphNode_raise_request() -> void:
	graph_node_meta.emit(self)


func _on_GraphNode_dragged(from, too) -> void:
	dragging.emit(from, too, self.title)


func _on_GraphNode_closed() -> void:
	node_closed.emit(self)