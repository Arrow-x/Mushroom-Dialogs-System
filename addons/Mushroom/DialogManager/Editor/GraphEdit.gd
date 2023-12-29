@tool
extends GraphEdit
class_name FlowChartGraphEdit

signal g_node_clicked
signal flow_changed
signal graph_node_close

@export var enter_name_scene: PackedScene
@export var i_graph_node: PackedScene
@export var flowchart_tab: Control
@export var command_tree: Tree

var g_node_posititon := Vector2(40, 40)
var undo_redo: EditorUndoRedoManager
var flowchart: FlowChart
var graph_nodes: Dictionary
var current_selected_graph_node: String
var clipboard: Array[Block]
func _ready() -> void:
	popup_request.connect(_on_popup_request)
	node_selected.connect(_on_node_selected)


func on_add_block_button_pressed(mouse_position := Vector2.ZERO) -> void:
	var enter_name: Window = enter_name_scene.instantiate()
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.new_text_confirm.connect(on_new_text_confirm.bind(mouse_position))


func on_new_text_confirm(new_title: String, mouse_position := Vector2.ZERO) -> void:
	if flowchart_tab.check_for_duplicates(new_title) or new_title.is_empty():
		await get_tree().create_timer(0.01).timeout
		push_error("GraphEdit: The Title is a duplicate! or an Empty string")
		on_add_block_button_pressed()
		return

	undo_redo.create_action("Creating a block")
	undo_redo.add_do_method(self, "add_block", new_title, mouse_position)
	undo_redo.add_undo_method(self, "close_node", new_title)
	undo_redo.commit_action()


func on_node_close(node: GraphNode) -> void:
	undo_redo.create_action("Block Closed")
	undo_redo.add_do_method(self, "close_node", node.get_title())
	undo_redo.add_undo_method(
		self, "add_block", node.get_title(), node.position_offset, node.get_meta("block")
	)
	undo_redo.commit_action()


func add_block(title: String, offset := Vector2.ZERO, in_block: Block = null) -> void:
	create_graph_node_from_block(title, offset, in_block)
	if in_block != null:
		connect_block_inputs(in_block)
		connect_block_outputs(in_block)


func create_graph_node_from_block(
	title: String, offset := Vector2.ZERO, in_block: Block = null
) -> void:
	var node: GraphNode = i_graph_node.instantiate()
	node.title = title
	if offset == Vector2.ZERO:
		node.position_offset += g_node_posititon + ((get_child_count() - 3) * Vector2(20, 20))
	else:
		node.position_offset = offset
	var new_block: Block
	if in_block == null:
		new_block = Block.new()
		new_block.name = title
	else:
		new_block = in_block

	flowchart.blocks[title] = new_block
	flowchart.blocks_offset[title] = node.position_offset
	node.set_meta("block", new_block)
	node.dragging.connect(on_node_dragged)
	node.block_clipboard = flowchart_tab.main_editor.block_clipboard
	node.right_menu_click.connect(handle_right_menu)
	if title != "first_block":
		node.node_closed.connect(on_node_close)
	add_child(node)
	node.set_owner(self)
	graph_nodes[title] = node

	if title == "first_block":
		graph_nodes["first_block"].set_modulate(Color("#f8ac52"))
		flowchart.first_block = flowchart.blocks["first_block"]
		node.selected = true
		return

	node.add_close_button()
	flow_changed.emit(flowchart)


func close_node(d_node: String) -> void:
	for closed_node_output in flowchart.get_block(d_node).outputs:
		for c in closed_node_output.choices:
			var deconecting_node: String = c.next_block
			delete_input(deconecting_node, closed_node_output)

	# Remove the block commands and the it's editor
	if command_tree.current_block == flowchart.get_block(d_node):
		command_tree.full_clear()
		for s in command_tree.commands_settings.get_children():
			s.queue_free()

	flowchart.blocks.erase(d_node)
	flowchart.blocks_offset.erase(d_node)
	# and then delete the node
	graph_nodes[d_node].queue_free()
	graph_nodes.erase(d_node)
	flow_changed.emit(flowchart)


func sync_flowchart_graph(fl: FlowChart) -> void:
	flowchart = fl
	var fb := flowchart.blocks
	for b in fb:
		create_graph_node_from_block(b, flowchart.get_block_offset(b), flowchart.get_block(b))
	for b in fb:
		connect_block_outputs(flowchart.get_block(b))

	if flowchart.first_block == null:
		create_graph_node_from_block("first_block")
		on_graph_node_clicked(graph_nodes["first_block"])


func connect_block_outputs(_new_block: Block, del_first: bool = false) -> void:
	for o in _new_block.outputs:
		update_block_flow(_new_block, o, del_first)


func connect_block_inputs(_new_block: Block) -> void:
	for i in _new_block.inputs:
		graph_nodes[_new_block.name].add_g_node_input(i)
		var err := connect_node(
			graph_nodes[i.origin_block].get_name(),
			flowchart.get_block(i.origin_block).outputs.find(i),
			graph_nodes[_new_block.name].get_name(),
			_new_block.inputs.find(i)
		)
		if err != OK:
			print("failure! to connect inputs")


func delete_output(deconecting_node: String, del_output: ForkCommand) -> void:
	disconnect_outputs(deconecting_node)
	for c in del_output.choices:
		delete_input(c.next_block, del_output)
	graph_nodes[deconecting_node].delete_outputs(del_output)
	reconnect_outputs(deconecting_node)


func delete_input(deconecting_node: String, closed_node_output: ForkCommand) -> void:
	disconnect_inputs(deconecting_node)
	graph_nodes[deconecting_node].delete_inputs(closed_node_output)
	reconnect_inputs(deconecting_node)


func disconnect_outputs(deconecting_node: String) -> void:
	for o in flowchart.get_block(deconecting_node).outputs:
		for c in o.choices:
			var dest: String = c.next_block
			if dest.is_empty():
				continue
			disconnect_node(
				graph_nodes[deconecting_node].get_name(),
				flowchart.get_block(deconecting_node).outputs.find(o),
				graph_nodes[dest].get_name(),
				flowchart.get_block(dest).inputs.find(o)
			)


func disconnect_inputs(deconecting_node: String) -> void:
	for o in flowchart.get_block(deconecting_node).inputs:
		disconnect_node(
			graph_nodes[o.origin_block].get_name(),
			flowchart.get_block(o.origin_block).outputs.find(o),
			graph_nodes[deconecting_node].get_name(),
			flowchart.get_block(deconecting_node).inputs.find(o)
		)


func reconnect_outputs(deconecting_node: String) -> void:
	for o in flowchart.get_block(deconecting_node).outputs:
		for c in o.choices:
			var dest: String = c.next_block
			if dest.is_empty():
				continue
			connect_node(
				graph_nodes[deconecting_node].get_name(),
				flowchart.get_block(deconecting_node).outputs.find(o),
				graph_nodes[dest].get_name(),
				flowchart.get_block(dest).inputs.find(o)
			)


func reconnect_inputs(deconecting_node: String) -> void:
	for o in flowchart.get_block(deconecting_node).inputs:
		connect_node(
			graph_nodes[o.origin_block].get_name(),
			flowchart.get_block(o.origin_block).outputs.find(o),
			graph_nodes[deconecting_node].get_name(),
			flowchart.get_block(deconecting_node).inputs.find(o)
		)


func update_block_flow(sender: Block, fork: ForkCommand, delete_first: bool) -> void:
	graph_nodes[sender.name].add_g_node_output(fork)
	if delete_first:
		for c_destination in graph_nodes[sender.name].connected_destenation_blocks:
			if not flowchart.get_block(c_destination).inputs.has(fork):
				continue
			disconnect_node(
				graph_nodes[sender.name].get_name(),
				sender.outputs.find(fork),
				graph_nodes[c_destination].get_name(),
				flowchart.get_block(c_destination).inputs.find(fork)
			)
			graph_nodes[sender.name].connected_destenation_blocks.erase(c_destination)
			delete_input(c_destination, fork)

	for c in fork.choices:
		var c_destination: String = c.next_block
		if c_destination.is_empty():
			continue
		graph_nodes[c_destination].add_g_node_input(fork)
		graph_nodes[sender.name].connected_destenation_blocks.append(c_destination)
		connect_node(
			graph_nodes[sender.name].get_name(),
			sender.outputs.find(fork),
			graph_nodes[c_destination].get_name(),
			flowchart.get_block(c_destination).inputs.find(fork)
		)
	flow_changed.emit(flowchart)


func on_graph_node_clicked(node: GraphNode) -> void:
	undo_redo.create_action("select Block node")
	undo_redo.add_do_method(self, "send_block_to_tree", node.title)
	undo_redo.add_undo_method(self, "send_block_to_tree", current_selected_graph_node)
	undo_redo.commit_action()
	current_selected_graph_node = node.title


func send_block_to_tree(node: String) -> void:
	set_selected(graph_nodes[node])
	g_node_clicked.emit(flowchart.get_block(node))


func on_node_dragged(start_offset: Vector2, finished_offset: Vector2, node_title: String) -> void:
	undo_redo.create_action("Moving Block")
	undo_redo.add_do_method(self, "set_node_offset", node_title, finished_offset)
	undo_redo.add_undo_method(self, "set_node_offset", node_title, start_offset)
	undo_redo.commit_action()


func set_node_offset(title: String, offset: Vector2) -> void:
	graph_nodes[title].position_offset = offset
	flowchart.blocks_offset[title] = offset
	flow_changed.emit(flowchart)


func on_rename_button_pressed(block_to_rename: Block) -> void:
	var enter_name: Window = enter_name_scene.instantiate()
	enter_name.line_edit.text = block_to_rename.name
	enter_name.line_edit.select(0)
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.new_text_confirm.connect(_on_new_text_confirm.bind(block_to_rename))


func _on_new_text_confirm(new_title: String, block_to_rename: Block) -> void:
	if flowchart_tab.check_for_duplicates(new_title) or new_title.is_empty():
		await get_tree().create_timer(0.01).timeout
		push_error("GraphEdi: The Title is a duplicate! or an Empty string")
		on_rename_button_pressed(block_to_rename)
		return

	undo_redo.create_action("Rename a block")
	undo_redo.add_do_method(self, "rename_block", new_title, block_to_rename.name, block_to_rename)
	undo_redo.add_undo_method(
		self, "rename_block", block_to_rename.name, new_title, block_to_rename
	)
	undo_redo.commit_action()


func rename_block(new_name: String, prev_name: String, block_to_rename: Block) -> void:
	graph_nodes[prev_name].title = new_name
	graph_nodes[new_name] = graph_nodes.get(prev_name)
	graph_nodes.erase(prev_name)

	var current_data := flowchart.blocks.get(prev_name)
	current_data.name = new_name
	flowchart.blocks[new_name] = current_data
	flowchart.blocks_offset[new_name] = graph_nodes[new_name].position_offset

	for output in flowchart.blocks[new_name].outputs:
		output.origin_block = new_name
	for input in flowchart.blocks[new_name].inputs:
		for choice in input.choices:
			choice.next_block = new_name

	block_to_rename.name = new_name
	flowchart.blocks.erase(prev_name)
	flowchart.blocks_offset.erase(prev_name)
	g_node_clicked.emit(block_to_rename)


func _on_popup_request(position: Vector2):
	accept_event()
	var pop := PopupMenu.new()
	pop.popup_hide.connect(func(): pop.queue_free())
	pop.index_pressed.connect(
		func(idx: int) -> void: handle_right_menu(pop.get_item_text(idx), position)
	)
	pop.add_item("Add Block")
	if not flowchart_tab.main_editor.block_clipboard.is_empty():
		pop.add_item("Paste")
	add_child(pop)
	var gmp := get_global_mouse_position()
	pop.popup(Rect2(gmp.x, gmp.y, 0, 0))


func handle_right_menu(case: String, pos: Vector2, node: GraphNode = null) -> void:
	if node != null:
		set_selected(node)
	match case:
		"Add Block":
			on_add_block_button_pressed(pos)
		"Copy":
			# TODO: add all selected graph nodes
			if node != null:
				clipboard.clear()
				clipboard.append(node.get_meta("block"))
		"Paste":
			var dupes: Array[Block] = []
			for c in clipboard:
				dupes.append(c.duplicate())
			for block in dupes:
				if flowchart.blocks.has(block.name) == true:
					for i in range(1, 999):
						if flowchart.blocks.has(str(block.name) + " (" + str(i) + ")") == true:
							continue
						block.name = str(str(block.name) + " (" + str(i) + ")")
						break
			undo_redo.create_action("Paste block")
			undo_redo.add_do_method(self, "paste_block", dupes, pos)
			undo_redo.add_undo_method(self, "close_nodes", dupes)
			undo_redo.commit_action()
		"Cut":
			var block: Array[Block] = []
			# TODO: add all selected graph nodes
			block.append(node.get_meta("block"))
			undo_redo.create_action("Cut block")
			undo_redo.add_do_method(self, "cut_block", block)
			undo_redo.add_undo_method(self, "paste_block", block, pos)
			undo_redo.commit_action()
		"Delete":
			if node != null:
				on_node_close(node)
		"Rename":
			on_rename_button_pressed(node.get_meta("block"))
		_:
			push_error("GraphEdit: no idea what have you pressed: ", case)


func cut_block(blocks: Array[Block]) -> void:
	flow_changed.emit(flowchart)
	flowchart_tab.main_editor.block_clipboard.clear()
	flowchart_tab.main_editor.block_clipboard.append_array(blocks)
	for block: Block in blocks:
		close_node(block.name)


func paste_block(blocks: Array[Block], pos: Vector2) -> void:
	flow_changed.emit(flowchart)
	for block: Block in blocks:
		create_graph_node_from_block(block.name, pos, block)


func close_nodes(blocks: Array[Block]) -> void:
	flow_changed.emit(flowchart)
	for block: Block in blocks:
		close_node(block.name)
