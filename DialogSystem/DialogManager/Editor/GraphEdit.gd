tool
extends GraphEdit

onready var graph_node: PackedScene = preload("res://DialogManager/Editor/GraphNode.tscn")
onready var enter_name_scene: PackedScene = preload("res://DialogManager/Editor/HelperScenes/EnterNameScene/Scenes/EnterNameScene.tscn")

var node_offset: int = 0
var types: Array

signal add_block_to_flow


func _on_AddBlockButton_pressed() -> void:
	var enter_name: WindowDialog = enter_name_scene.instance()
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.connect("new_text_confirm", self, "on_new_text_confirm")


func add_block(title) -> void:
	var node: GraphNode = graph_node.instance()
	node.title = title
	node.offset = Vector2(node_offset, 0)
	if node_offset < 240:
		node_offset = node_offset + 120
	else:
		node_offset = 0

	var _new_block = block.new()
	_new_block.name = title
	node.set_meta("block", _new_block)
	emit_signal("add_block_to_flow", _new_block, node)
	node.connect(
		"graph_node_meta",
		get_node("../../InspectorTabContainer/Block Settings/InspectorVContainer/CommandsTree"),
		"on_GraphNode_clicked"
	)
	# node.set_name(title)
	add_child(node)


func on_new_text_confirm(new_title: String) -> void:
	if $"../../".check_for_duplicates(new_title) == true or new_title == "":
		_on_AddBlockButton_pressed()
		print("The Title is a duplicate!")
		# TODO add a popup window here to give info on the error
		return
	add_block(new_title)


func update_block_flow(sender, fork) -> void:
	var sed: String
	var sed_i: int

	for i_gnode in get_children():
		if i_gnode is GraphNode:
			if i_gnode.outputs.has(fork):
				sed = i_gnode.get_name()
				sed_i = i_gnode.outputs.find(fork)
				break

	for i_gnode in get_children():
		if i_gnode is GraphNode:
			if i_gnode.inputs.has(fork):
				disconnect_node(sed, sed_i, i_gnode.get_name(), i_gnode.inputs.find(fork))
				i_gnode.delete_inputs(fork)

	for i_gnode in get_children():
		if i_gnode is GraphNode:
			if i_gnode.outputs.has(fork):
				i_gnode.delete_outputs(fork)

	for c in fork.choices:
		connect_blocks(c.next_block, sender, fork)


func connect_blocks(recivier: block, sender: block, fork: fork_command) -> void:
	if !types.has(fork):
		types.append(fork)

	var i_sender
	var i_recivier
	var sender_name: String
	var recivier_name: String
	for i in get_children():
		if i is GraphNode:
			var i_meta: block = i.get_meta("block")
			if i_meta == sender:
				if !i.outputs.has(fork):
					var cc: Control = Control.new()
					cc.rect_min_size = Vector2(10, 10)
					i.add_child(cc)
					i.outputs.append(fork)
					i.c_outputs.append(cc)

				i_sender = i.outputs.find(fork)
				sender_name = i.get_name()
				i.set_slot_enabled_right(i_sender, true)
				i.set_slot_type_right(i_sender, types.find(fork))
				i.set_slot_color_right(i_sender, fork.f_color)

			if i_meta == recivier:
				if !i.inputs.has(fork):
					var cc: Control = Control.new()
					cc.rect_min_size = Vector2(10, 10)
					i.add_child(cc)
					i.inputs.append(fork)
					i.c_inputs.append(cc)

				i_recivier = i.inputs.find(fork)
				recivier_name = i.get_name()
				i.set_slot_enabled_left(i_recivier, true)
				i.set_slot_type_left(i_recivier, types.find(fork))
				i.set_slot_color_left(i_recivier, fork.f_color)

	connect_node(sender_name, i_sender, recivier_name, i_recivier)
