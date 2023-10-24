@tool
extends GraphEdit

# TODO: rewrite update_block_flow logic

@onready var enter_name_scene: PackedScene = preload(
	"res://addons/Mushroom/DialogManager/Editor/EnterNameScene.tscn"
)

var g_node_posititon := Vector2(40, 40)
var undo_redo: UndoRedo

var flowchart: FlowChart
var graph_nodes: Dictionary

var current_selected_graph_node: String

signal g_node_clicked
signal flow_changed
signal graph_node_close


func _on_AddBlockButton_pressed() -> void:
	var enter_name: Window = enter_name_scene.instantiate()
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.new_text_confirm.connect(on_new_text_confirm)


func on_new_text_confirm(new_title: String) -> void:
	if $"../../".check_for_duplicates(new_title) == true or new_title == "":
		_on_AddBlockButton_pressed()
		print("The Title is a duplicate!")
		return

	undo_redo.create_action("Creating a block")
	undo_redo.add_do_method(add_block.bind(new_title))
	undo_redo.add_undo_method(close_node.bind(new_title))
	undo_redo.commit_action()


func on_node_close(node: GraphNode) -> void:
	undo_redo.create_action("Block Closed")
	undo_redo.add_do_method(close_node.bind(node.get_title()))
	undo_redo.add_undo_method(
		add_block.bind(node.get_title(), node.position_offset, node.get_meta("block"))
	)
	undo_redo.commit_action()


func add_block(title: String, offset = null, in_block: Block = null) -> void:
	create_GraphNode_from_block(title, offset, in_block)
	if in_block != null:
		connect_block_inputs(in_block)
		connect_block_outputs(in_block)


func create_GraphNode_from_block(title: String, offset = null, in_block: Block = null) -> void:
	var node: GraphNode = (
		load("res://addons/Mushroom/DialogManager/Editor/GraphNode.tscn").instantiate()
	)
	node.title = title
	if offset == null:
		node.position_offset += g_node_posititon + ((get_child_count() - 3) * Vector2(20, 20))
	else:
		node.position_offset = offset
	var _new_block: Block
	if in_block == null:
		_new_block = Block.new()
		_new_block.name = title
	else:
		_new_block = in_block

	flowchart.blocks[title] = {block = _new_block, offset = node.position_offset}
	node.set_meta("block", _new_block)
	node.graph_node_meta.connect(on_GraphNode_clicked, CONNECT_PERSIST)
	node.dragging.connect(on_node_dragged, CONNECT_PERSIST)
	if title != "first_block":
		node.node_closed.connect(on_node_close, CONNECT_PERSIST)
	add_child(node)
	node.set_owner(self)
	graph_nodes[title] = node

	if title == "first_block":
		graph_nodes["first_block"].set_modulate(Color("#f8ac52"))
		flowchart.first_block = flowchart.blocks["first_block"].block
		node.show_close = false
		node.selected = true


func close_node(d_node: String) -> void:
	for closed_node_output in flowchart.get_block(d_node).outputs:
		for c in closed_node_output.choices:
			var deconecting_node: String = c.next_block
			delete_input(deconecting_node, closed_node_output)

	# Removie the blook commands and the it's editor
	var command_tree: Tree = get_node(
		"../../InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"
	)
	if command_tree.current_block == flowchart.get_block(d_node):
		command_tree.full_clear()
		for s in command_tree.commands_settings.get_children():
			s.queue_free()

	flowchart.blocks.erase(d_node)
	# and then delete the node
	graph_nodes[d_node].queue_free()
	graph_nodes.erase(d_node)


func sync_flowchart_graph(fl: FlowChart) -> void:
	flowchart = fl
	var fb := flowchart.blocks
	for b in fb:
		create_GraphNode_from_block(b, flowchart.get_block_offset(b), flowchart.get_block(b))
	for b in fb:
		connect_block_outputs(flowchart.get_block(b))

	if flowchart.first_block == null:
		create_GraphNode_from_block("first_block")
		on_GraphNode_clicked(graph_nodes["first_block"])


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
		for b in graph_nodes[sender.name].already_connected:
			if not flowchart.get_block(b).inputs.has(fork):
				continue
			disconnect_node(
				graph_nodes[sender.name].get_name(),
				sender.outputs.find(fork),
				graph_nodes[b].get_name(),
				flowchart.get_block(b).inputs.find(fork)
			)
			graph_nodes[sender.name].already_connected.erase(b)
			delete_input(b, fork)

	for c in fork.choices:
		var c_destination: String = c.next_block
		if c_destination.is_empty():
			continue
		graph_nodes[c_destination].add_g_node_input(fork)
		graph_nodes[sender.name].already_connected.append(c_destination)
		connect_node(
			graph_nodes[sender.name].get_name(),
			sender.outputs.find(fork),
			graph_nodes[c_destination].get_name(),
			flowchart.get_block(c_destination).inputs.find(fork)
		)


func on_GraphNode_clicked(node: GraphNode) -> void:
	undo_redo.create_action("select Block node")
	undo_redo.add_do_method(send_block_to_tree.bind(node.title))
	undo_redo.add_undo_method(send_block_to_tree.bind(current_selected_graph_node))
	undo_redo.commit_action()
	current_selected_graph_node = node.title


func send_block_to_tree(node: String) -> void:
	emit_signal("g_node_clicked", flowchart.get_block(node))
	set_selected(graph_nodes[node])


func on_node_dragged(start_offset: Vector2, finished_offset: Vector2, node_title: String) -> void:
	undo_redo.create_action("Moving Block")
	undo_redo.add_do_method(set_node_offset.bind(node_title, finished_offset))
	undo_redo.add_undo_method(set_node_offset.bind(node_title, start_offset))
	undo_redo.commit_action()
	emit_signal("flow_changed")


func set_node_offset(title: String, offset: Vector2) -> void:
	graph_nodes[title].set_position(offset)
	flowchart.blocks[title].offset = offset
