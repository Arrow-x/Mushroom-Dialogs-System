tool
extends GraphEdit

onready var graph_node: PackedScene = preload("res://addons/Mushroom/DialogManager/Editor/GraphNode.tscn")
onready var enter_name_scene: PackedScene = preload("res://addons/Mushroom/DialogManager/Editor/HelperScenes/EnterNameScene/Scenes/EnterNameScene.tscn")

var g_node_posititon := Vector2(40, 40)
var undo_redo: UndoRedo

signal add_block_to_flow
signal g_node_clicked
signal flow_changed
signal graph_node_close


func sync_flowchart_graph() -> void:
	for g_node in get_children():
		if g_node is GraphNode:
			for command in g_node.get_meta("block").commands:
				if command is fork_command:
					update_block_flow(g_node.get_meta("block"), command)


func _on_AddBlockButton_pressed() -> void:
	var enter_name: WindowDialog = enter_name_scene.instance()
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.connect("new_text_confirm", self, "on_new_text_confirm")


func add_block(title) -> void:
	var node: GraphNode = graph_node.instance()
	node.title = title
	node.offset += g_node_posititon + ((get_child_count() - 3) * Vector2(20, 20))

	var _new_block = block.new()
	_new_block.name = title
	node.set_meta("block", _new_block)
	emit_signal("add_block_to_flow", _new_block, node)
	node.connect("graph_node_meta", self, "on_GraphNode_clicked", [], CONNECT_PERSIST)
	node.connect("dragging", self, "on_node_dragged", [], CONNECT_PERSIST)
	node.connect("node_closed", self, "on_node_close", [], CONNECT_PERSIST)
	add_child(node)
	node.set_owner(self)


func delete_block(title) -> void:
	for b in get_children():
		if b is GraphNode:
			if b.title == title:
				b.queue_free()


func close_node(deletable_node: GraphNode) -> void:
	for f in deletable_node.get_meta("block").commands:
		if f is fork_command:
			remove_fork_connections(f)

	deletable_node.queue_free()


func on_node_close(node) -> void:
	emit_signal("graph_node_close", self, node.title, "close_node")


func on_GraphNode_clicked(node):
	emit_signal("g_node_clicked", node)


func on_node_dragged(start_offset: Vector2, finished_offset: Vector2, node: GraphNode) -> void:
	# BUG this gets messed up when replacing the Graphedit on an Undo
	undo_redo.create_action("Moving Block")
	undo_redo.add_do_method(node, "set_offset", finished_offset)
	undo_redo.add_undo_method(node, "set_offset", start_offset)
	undo_redo.commit_action()
	emit_signal("flow_changed")


func on_new_text_confirm(new_title: String) -> void:
	if $"../../".check_for_duplicates(new_title) == true or new_title == "":
		_on_AddBlockButton_pressed()
		print("The Title is a duplicate!")
		return

	undo_redo.create_action("Creating a block")
	undo_redo.add_do_method(self, "add_block", new_title)
	undo_redo.add_undo_method(self, "delete_block", new_title)
	undo_redo.commit_action()


func update_block_flow(sender: block, fork: fork_command) -> void:
	remove_fork_connections(fork)
	for c in fork.choices:
		connect_blocks(c.next_block, sender, fork)


func remove_fork_connections(fork: fork_command) -> void:
	var g_node_name: String
	var g_node_output_idx: int

	for g_node in get_children():
		if g_node is GraphNode:
			if g_node.outputs.has(fork):
				g_node_name = g_node.get_name()
				g_node_output_idx = g_node.outputs.find(fork)
				break

	for g_node in get_children():
		if g_node is GraphNode:
			if g_node.inputs.has(fork):
				disconnect_node(
					g_node_name, g_node_output_idx, g_node.get_name(), g_node.inputs.find(fork)
				)
				g_node.delete_inputs(fork)

	for g_node in get_children():
		if g_node is GraphNode:
			if g_node.outputs.has(fork):
				g_node.delete_outputs(fork)


func connect_blocks(receiver: block, sender: block, fork: fork_command) -> void:
	var sender_idx
	var receiver_idx
	var sender_name: String
	var receiver_name: String
	for g_node in get_children():
		if g_node is GraphNode:
			var g_node_meta: block = g_node.get_meta("block")
			if g_node_meta == sender:
				g_node.add_g_node_output(fork)
				sender_idx = g_node.outputs.find(fork)
				sender_name = g_node.get_name()

			if g_node_meta == receiver:
				g_node.add_g_node_input(fork)
				receiver_idx = g_node.inputs.find(fork)
				receiver_name = g_node.get_name()

	connect_node(sender_name, sender_idx, receiver_name, receiver_idx)
