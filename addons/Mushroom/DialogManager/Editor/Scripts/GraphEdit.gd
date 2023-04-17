tool
extends GraphEdit

onready var enter_name_scene: PackedScene = preload(
	"res://addons/Mushroom/DialogManager/Editor/EnterNameScene.tscn"
)

var g_node_posititon := Vector2(40, 40)
var undo_redo: UndoRedo

var flowchart: FlowChart
var graph_nodes: Dictionary

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


func connect_block_outputs(_new_block: block) -> void:
	for o in _new_block.outputs:
		update_block_flow(_new_block, o)


# TODO: oooh I am looking forwadf to refactoring this massive boy
func close_node(d_node: String) -> void:
	for closed_node in get_children():
		if not closed_node is GraphNode:
			continue
		if closed_node.title != d_node:
			continue

		var closed_node_meta: block = closed_node.get_meta("block")

		for closed_node_output in closed_node_meta.outputs:
			for deconecting_node in get_children():
				if not deconecting_node is GraphNode:
					continue

				var deconnecting_node_meta: block = deconecting_node.get_meta("block")

				if not deconnecting_node_meta.inputs.has(closed_node_output):
					continue

				# disconnect all the nodes that are connected first
				for d_input in deconnecting_node_meta.inputs:
					for refresh_node in get_children():
						if not refresh_node is GraphNode:
							continue
						if not refresh_node.get_meta("block").outputs.has(d_input):
							continue

						disconnect_node(
							refresh_node.get_name(),
							refresh_node.get_meta("block").outputs.find(d_input),
							deconecting_node.get_name(),
							deconnecting_node_meta.inputs.find(d_input)
						)

						break

				# delete the deleted fork
				deconecting_node.delete_inputs(closed_node_output)

				# reconect all the inputs
				for i in deconnecting_node_meta.inputs:
					for g in get_children():
						if not g is GraphNode:
							continue
						if not g.get_meta("block").outputs.has(i):
							continue
						connect_node(
							g.get_name(),
							g.get_meta("block").outputs.find(i),
							deconecting_node.get_name(),
							deconnecting_node_meta.inputs.find(i)
						)
						break

		# Removie the blook commands and the it's editor
		var command_tree: Tree = get_node(
			"../../InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"
		)
		if command_tree.current_block == closed_node_meta:
			command_tree.full_clear()
			for s in command_tree.commands_settings.get_children():
				s.queue_free()

		flowchart.blocks.erase(closed_node_meta.name)
		graph_nodes.erase(closed_node_meta.name)

		# and then delete the node
		closed_node.queue_free()


func on_node_close(node: GraphNode) -> void:
	undo_redo.create_action("Block Closed")
	undo_redo.add_do_method(self, "close_node", node.get_title())
	undo_redo.add_undo_method(
		self, "add_block", node.get_title(), node.offset, node.get_meta("block")
	)
	undo_redo.commit_action()


func on_GraphNode_clicked(node):
	emit_signal("g_node_clicked", self, node.get_title())


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


func update_block_flow(sender: block, fork: fork_command) -> void:
	graph_nodes[sender.name].add_g_node_output(fork)
	for b in graph_nodes[sender.name].already_connected:
		if flowchart.get_block(b).inputs.has(fork):
			disconnect_node(
				graph_nodes[sender.name].get_name(),
				sender.outputs.find(fork),
				graph_nodes[b].get_name(),
				flowchart.get_block(b).inputs.find(fork)
			)
			graph_nodes[sender.name].already_connected.erase(b)
			graph_nodes[b].delete_inputs(fork)

	for c in fork.choices:
		var c_destination = c.next_block
		graph_nodes[c_destination].add_g_node_input(fork)
		graph_nodes[sender.name].already_connected.append(c_destination)
		connect_node(
			graph_nodes[sender.name].get_name(),
			sender.outputs.find(fork),
			graph_nodes[c_destination].get_name(),
			flowchart.get_block(c_destination).inputs.find(fork)
		)
