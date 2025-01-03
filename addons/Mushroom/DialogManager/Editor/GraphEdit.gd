@tool
extends GraphEdit

signal g_node_clicked
signal flow_changed
signal graph_node_close

@export var enter_name_scene: PackedScene
@export var i_graph_node: PackedScene
@export var flowchart_tab: FlowChartTabs
@export var command_tree: Tree

var g_node_posititon := Vector2(0, 0)
var undo_redo: EditorUndoRedoManager
var flowchart: FlowChart

var graph_nodes: Dictionary
var current_selected_graph_node: String
var selected_graph_nodes: Dictionary


func _ready() -> void:
	selected_graph_nodes = {}
	popup_request.connect(_on_popup_request)
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)
	copy_nodes_request.connect(on_copy)
	paste_nodes_request.connect(on_paste.bind(Vector2.ZERO))

	delete_nodes_request.connect(
		func _on_delete_nodes_request(_node: Array) -> void: on_node_close(selected_graph_nodes)
	)


func on_add_block_button_pressed(mouse_position := Vector2.ZERO) -> void:
	var enter_name: Window = enter_name_scene.instantiate()
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.new_text_confirm.connect(_on_new_text_confirm.bind(mouse_position))


func _on_new_text_confirm(block_name: String, mouse_position := Vector2.ZERO) -> void:
	if flowchart_tab.check_for_duplicates(block_name) or block_name.is_empty():
		await get_tree().create_timer(0.01).timeout
		push_error("GraphEdit: The Title is a duplicate! or an Empty string")
		on_add_block_button_pressed()
		return

	undo_redo.create_action("Creating a block")
	undo_redo.add_do_method(self, "add_block", block_name, mouse_position)
	undo_redo.add_undo_method(self, "close_node", block_name)
	undo_redo.commit_action()


func on_node_close(_d = null) -> void:
	var curr_sel: Dictionary = {}
	for s in selected_graph_nodes:
		curr_sel[s] = {
			"offset": selected_graph_nodes[s]["offset"], "block": selected_graph_nodes[s]["block"]
		}
	undo_redo.create_action("Block Closed")
	undo_redo.add_do_method(self, "close_nodes", curr_sel)
	undo_redo.add_undo_method(self, "add_blocks", curr_sel)
	undo_redo.commit_action()


func close_nodes(nodes: Dictionary) -> void:
	for block_name in nodes:
		if block_name == "first_block":
			continue
		close_node(block_name)
	selected_graph_nodes = {}


func add_blocks(nodes: Dictionary) -> void:
	for node in nodes:
		if node == "first_block":
			continue
		add_block(node, nodes[node]["offset"], nodes[node]["block"])


func add_block(title: String, offset := Vector2.ZERO, in_block: Block = null) -> void:
	create_graph_node_from_block(title, offset, in_block)
	if in_block != null:
		connect_block_inputs(in_block)
		connect_block_outputs(in_block)


func create_graph_node_from_block(
	title: String, offset := Vector2.ZERO, in_block: Block = null
) -> void:
	var g_node: GraphNode = i_graph_node.instantiate()
	g_node.title = title
	if offset == Vector2.ZERO:
		g_node.position_offset += g_node_posititon + ((get_child_count() - 3) * Vector2(20, 20))
	else:
		g_node.position_offset = (offset + scroll_offset) / zoom
	var new_block: Block
	if in_block == null:
		new_block = Block.new()
		new_block.name = title
	else:
		new_block = in_block

	flowchart.blocks[title] = new_block
	flowchart.blocks_offset[title] = g_node.position_offset
	g_node.set_meta("block", new_block)
	g_node.graph_edit = self
	add_child(g_node)
	g_node.set_owner(self)
	graph_nodes[title] = g_node

	if title == "first_block":
		graph_nodes["first_block"].set_modulate(Color("#f8ac52"))
		flowchart.first_block = flowchart.blocks["first_block"]
		g_node.selected = true
		return

	g_node.add_close_button()
	flow_changed.emit(flowchart)


func close_node(block_name: String) -> void:
	if flowchart.get_block(block_name) != null:
		for closed_node_output in flowchart.get_block(block_name).outputs:
			for c in closed_node_output.choices:
				var deconecting_node: String = c.next_block
				delete_input(deconecting_node, closed_node_output)

	# Remove the block commands and the it's editor
	if command_tree.current_block == flowchart.get_block(block_name):
		command_tree.full_clear()
		for s in command_tree.commands_settings.get_children():
			s.queue_free()

	flowchart.blocks.erase(block_name)
	flowchart.blocks_offset.erase(block_name)
	# and then delete the node
	graph_nodes[block_name].queue_free()
	graph_nodes.erase(block_name)
	flow_changed.emit(flowchart)


func sync_flowchart_graph(fl: FlowChart) -> void:
	flowchart = fl
	var fb := flowchart.blocks
	for block_name in fb:
		create_graph_node_from_block(block_name, flowchart.get_block_offset(block_name), flowchart.get_block(block_name))
	for block_name in fb:
		connect_block_outputs(flowchart.get_block(block_name))

	if flowchart.first_block == null:
		create_graph_node_from_block("first_block")
		on_graph_node_clicked(graph_nodes["first_block"])


func connect_block_outputs(_new_block: Block, del_first: bool = false) -> void:
	for fork in _new_block.outputs:
		update_block_flow(_new_block, fork, del_first)


func connect_block_inputs(_new_block: Block) -> void:
	for fork in _new_block.inputs:
		graph_nodes[_new_block.name].add_g_node_input(fork)
		var err := connect_node(
			graph_nodes[fork.origin_block_name].get_name(),
			flowchart.get_block(fork.origin_block_name).outputs.find(fork),
			graph_nodes[_new_block.name].get_name(),
			_new_block.inputs.find(fork)
		)
		if err != OK:
			print("failure! to connect inputs")


func delete_output(deconecting_node: String, del_output: ForkCommand) -> void:
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
	for c in del_output.choices:
		delete_input(c.next_block, del_output)
	graph_nodes[deconecting_node].delete_outputs(del_output)
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


func delete_input(deconecting_node: String, closed_node_output: ForkCommand) -> void:
	for o in flowchart.get_block(deconecting_node).inputs:
		disconnect_node(
			graph_nodes[o.origin_block_name].get_name(),
			flowchart.get_block(o.origin_block_name).outputs.find(o),
			graph_nodes[deconecting_node].get_name(),
			flowchart.get_block(deconecting_node).inputs.find(o)
		)
	graph_nodes[deconecting_node].delete_inputs(closed_node_output)
	for o in flowchart.get_block(deconecting_node).inputs:
		connect_node(
			graph_nodes[o.origin_block_name].get_name(),
			flowchart.get_block(o.origin_block_name).outputs.find(o),
			graph_nodes[deconecting_node].get_name(),
			flowchart.get_block(deconecting_node).inputs.find(o)
		)


func update_block_flow(sender: Block, fork: ForkCommand, delete_first: bool) -> void:
	graph_nodes[sender.name].add_g_node_output(fork)
	if delete_first:
		var destenations_to_delete: Array = []
		for c_destination in graph_nodes[sender.name].connected_destenation_blocks:
			if not flowchart.get_block(c_destination).inputs.has(fork):
				continue
			disconnect_node(
				graph_nodes[sender.name].get_name(),
				sender.outputs.find(fork),
				graph_nodes[c_destination].get_name(),
				flowchart.get_block(c_destination).inputs.find(fork)
			)
			destenations_to_delete.append(c_destination)

		for d in destenations_to_delete:
			graph_nodes[sender.name].connected_destenation_blocks.erase(d)
			delete_input(d, fork)

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
	enter_name.new_text_confirm.connect(_on_new_rename_text_confirm.bind(block_to_rename))


func _on_new_rename_text_confirm(new_title: String, block_to_rename: Block) -> void:
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

	var current_data: Block = flowchart.blocks.get(prev_name)
	current_data.name = new_name
	flowchart.blocks[new_name] = current_data
	flowchart.blocks_offset[new_name] = graph_nodes[new_name].position_offset

	for output in flowchart.blocks[new_name].outputs:
		output.origin_block_name = new_name
	for input in flowchart.blocks[new_name].inputs:
		for choice in input.choices:
			choice.next_block = new_name

	block_to_rename.name = new_name
	flowchart.blocks.erase(prev_name)
	flowchart.blocks_offset.erase(prev_name)
	selected_graph_nodes = {}
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
	match case:
		"Add Block":
			on_add_block_button_pressed(pos)
		"Copy":
			on_copy()
		"Paste":
			on_paste(pos)
		"Cut":
			on_cut()
		"Delete":
			if node != null:
				on_node_close(selected_graph_nodes)
		"Rename":
			on_rename_button_pressed(node.get_meta("block"))
		_:
			push_error("GraphEdit: no idea what have you pressed: ", case)
	if node != null:
		set_selected(node)


func on_copy() -> void:
	flowchart_tab.main_editor.block_clipboard = {}
	for s in selected_graph_nodes:
		flowchart_tab.main_editor.block_clipboard[s] = {
			"offset": selected_graph_nodes[s]["offset"],
			"block": flowchart_tab.deep_duplicate_block(selected_graph_nodes[s]["block"])
		}


func on_cut() -> void:
	var sel_blocks: Dictionary = {}
	for s in selected_graph_nodes:
		sel_blocks[s] = {
			"offset": selected_graph_nodes[s]["offset"], "block": selected_graph_nodes[s]["block"]
		}

	undo_redo.create_action("Cut block")
	undo_redo.add_do_method(self, "cut_block", sel_blocks)
	undo_redo.add_undo_method(self, "paste_block", sel_blocks)
	undo_redo.commit_action()


func on_paste(pos: Vector2) -> void:
	var dupes: Dictionary = {}
	if pos == Vector2.ZERO:
		pos = get_local_mouse_position()
	var last_pos := pos
	for c: String in flowchart_tab.main_editor.block_clipboard:
		last_pos += Vector2(30, 30)
		dupes[c] = {
			"block":
			flowchart_tab.deep_duplicate_block(
				flowchart_tab.main_editor.block_clipboard[c]["block"]
			),
			"offset": last_pos
		}
	var keys_to_delete: Array[String] = []
	for block_key in dupes:
		if flowchart.blocks.has(block_key) != true:
			continue
		for i in range(1, 999):
			var mod_name: String = str(block_key) + " (" + str(i) + ")"
			if flowchart.blocks.has(mod_name) == true:
				continue
			dupes[block_key]["block"].name = mod_name
			dupes[mod_name] = {
				"block": dupes[block_key]["block"], "offset": dupes[block_key]["offset"]
			}
			keys_to_delete.append(block_key)
			break
	for b in keys_to_delete:
		dupes.erase(b)
	undo_redo.create_action("Paste block")
	undo_redo.add_do_method(self, "paste_block", dupes)
	undo_redo.add_undo_method(self, "close_nodes", dupes)
	undo_redo.commit_action()


func cut_block(blocks: Dictionary) -> void:
	flow_changed.emit(flowchart)
	flowchart_tab.main_editor.block_clipboard = {}
	selected_graph_nodes = {}
	set_selected(null)
	for block_name: String in blocks:
		flowchart_tab.main_editor.block_clipboard[block_name] = {
			"offset": blocks[block_name]["offset"],
			"block_name": flowchart_tab.deep_duplicate_block_name(blocks[block_name]["block_name"])
		}
		if block_name == "first_block_name":
			continue
		close_node(block_name)


func paste_block(blocks: Dictionary) -> void:
	flow_changed.emit(flowchart)
	for block: String in blocks:
		for c: ForkCommand in blocks[block]["block"].outputs:
			c.origin_block_name = blocks[block]["block"].name
		add_block(blocks[block]["block"].name, blocks[block]["offset"], blocks[block]["block"])


func _on_node_selected(node: Node) -> void:
	selected_graph_nodes[node.title] = {
		"block": node.get_meta("block"), "offset": node.position_offset
	}


func _on_node_deselected(node: Node) -> void:
	selected_graph_nodes.erase(node.title)
