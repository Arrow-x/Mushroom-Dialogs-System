tool
extends GraphEdit

onready var enter_name_scene: PackedScene = preload(
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


func sync_flowchart_graph(fl: FlowChart) -> void:
	flowchart = fl
	var fb := flowchart.blocks
	for b in fb:
		create_GraphNode_from_block(b, flowchart.get_block_offset(b), flowchart.get_block(b))
	for b in fb:
		connect_block_outputs(flowchart.get_block(b))


func _on_AddBlockButton_pressed() -> void:
	var enter_name: WindowDialog = enter_name_scene.instance()
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.connect("new_text_confirm", self, "on_new_text_confirm")


func add_block(title: String, offset = null, in_block: block = null) -> void:
	create_GraphNode_from_block(title, offset, in_block)
	if in_block != null:
		connect_block_inputs(in_block)
		connect_block_outputs(in_block)


func create_GraphNode_from_block(title: String, offset = null, in_block: block = null) -> void:
	var node: GraphNode = load("res://addons/Mushroom/DialogManager/Editor/GraphNode.tscn").instance()
	node.title = title
	if offset == null:
		node.offset += g_node_posititon + ((get_child_count() - 3) * Vector2(20, 20))
	else:
		node.offset = offset
	var _new_block: block
	if in_block == null:
		_new_block = block.new()
		_new_block.name = title
	else:
		_new_block = in_block

	flowchart.blocks[title] = {block = _new_block, offset = node.offset}
	node.set_meta("block", _new_block)
	node.connect("graph_node_meta", self, "on_GraphNode_clicked", [], CONNECT_PERSIST)
	node.connect("dragging", self, "on_node_dragged", [], CONNECT_PERSIST)
	node.connect("node_closed", self, "on_node_close", [], CONNECT_PERSIST)
	add_child(node)
	node.set_owner(self)
	graph_nodes[title] = node


func connect_block_inputs(_new_block: block) -> void:
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


func connect_block_outputs(_new_block: block, del_first: bool = false) -> void:
	for o in _new_block.outputs:
		update_block_flow(_new_block, o, del_first)


func close_node(d_node: String) -> void:
	for closed_node_output in flowchart.get_block(d_node).outputs:
		for c in closed_node_output.choices:
			var deconecting_node: String = c.next_block
			delete_connected_input(deconecting_node, closed_node_output)

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


func delete_connected_input(deconecting_node: String, closed_node_output: fork_command) -> void:
	for d_input in flowchart.get_block(deconecting_node).inputs:
		disconnect_node(
			graph_nodes[d_input.origin_block].get_name(),
			flowchart.get_block(d_input.origin_block).outputs.find(d_input),
			graph_nodes[deconecting_node].get_name(),
			flowchart.get_block(deconecting_node).inputs.find(d_input)
		)
	graph_nodes[deconecting_node].delete_inputs(closed_node_output)

	for d_input in flowchart.get_block(deconecting_node).inputs:
		connect_node(
			graph_nodes[d_input.origin_block].get_name(),
			flowchart.get_block(d_input.origin_block).outputs.find(d_input),
			graph_nodes[deconecting_node].get_name(),
			flowchart.get_block(deconecting_node).inputs.find(d_input)
		)


func on_node_close(node: GraphNode) -> void:
	undo_redo.create_action("Block Closed")
	undo_redo.add_do_method(self, "close_node", node.get_title())
	undo_redo.add_undo_method(
		self, "add_block", node.get_title(), node.offset, node.get_meta("block")
	)
	undo_redo.commit_action()


func on_GraphNode_clicked(node: GraphNode) -> void:
	undo_redo.create_action("select Block node")
	undo_redo.add_do_method(self, "send_block_to_tree", node.title)
	undo_redo.add_undo_method(self, "send_block_to_tree", current_selected_graph_node)
	undo_redo.commit_action()
	current_selected_graph_node = node.title


func send_block_to_tree(node: String) -> void:
	emit_signal("g_node_clicked", flowchart.get_block(node))
	set_selected(graph_nodes[node])


func on_node_dragged(start_offset: Vector2, finished_offset: Vector2, node_title: String) -> void:
	undo_redo.create_action("Moving Block")
	undo_redo.add_do_method(self, "set_node_offset", node_title, finished_offset)
	undo_redo.add_undo_method(self, "set_node_offset", node_title, start_offset)
	undo_redo.commit_action()
	emit_signal("flow_changed")


func set_node_offset(title: String, offset: Vector2) -> void:
	graph_nodes[title].set_offset(offset)
	flowchart.blocks[title].offset = offset


func on_new_text_confirm(new_title: String) -> void:
	if $"../../".check_for_duplicates(new_title) == true or new_title == "":
		_on_AddBlockButton_pressed()
		print("The Title is a duplicate!")
		return

	undo_redo.create_action("Creating a block")
	undo_redo.add_do_method(self, "add_block", new_title)
	undo_redo.add_undo_method(self, "close_node", new_title)
	undo_redo.commit_action()


func update_block_flow(sender: block, fork: fork_command, delete_first: bool) -> void:
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
			delete_connected_input(b, fork)

	for c in fork.choices:
		var c_destination: String = c.next_block
		if c_destination.empty():
			continue
		graph_nodes[c_destination].add_g_node_input(fork)
		graph_nodes[sender.name].already_connected.append(c_destination)
		connect_node(
			graph_nodes[sender.name].get_name(),
			sender.outputs.find(fork),
			graph_nodes[c_destination].get_name(),
			flowchart.get_block(c_destination).inputs.find(fork)
		)
