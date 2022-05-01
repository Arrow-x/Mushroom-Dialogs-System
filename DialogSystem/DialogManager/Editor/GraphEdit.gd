extends GraphEdit

onready var graph_node: PackedScene = preload("res://DialogManager/Editor/GraphNode.tscn")
onready var enter_name_scene: PackedScene = preload("res://DialogManager/Editor/HelperScenes/EnterNameScene/Scenes/EnterNameScene.tscn")

var node_offset: int = 0
var types : Array

signal add_block_to_flow


func _on_AddBlockButton_pressed():
	var enter_name: WindowDialog = enter_name_scene.instance()
	add_child(enter_name, true)
	enter_name.popup_centered()
	enter_name.connect("new_text_confirm", self, "on_new_text_confirm")


func add_block(title):
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
		"_on_GraphNode_graph_node_meta"
	)
	node.set_name(title)
	add_child(node)


func on_new_text_confirm(new_title: String) -> void:
	if $"../../".check_for_duplicates(new_title) == true or new_title == "":
		_on_AddBlockButton_pressed()
		print("The Title is a duplicate!")
		#add a popup window here to give info on the error
		return
	add_block(new_title)


func connect_blocks(recivier: block, sender: block, fork : fork_command):
	if !types.has(fork):
		types.append(fork)

	var i_sender
	var i_recivier
	for i in get_children():
		if i is GraphNode:
			#TODO use block comparision instead of names
			if i.title == sender.name:
				if !i.outputs.has(fork):
					var cc :Control = Control.new()
					cc.rect_min_size = Vector2(10,10)
					i.add_child(cc)
					i.outputs.append(fork)

				i_sender = i.outputs.find(fork)
				i.set_slot_enabled_right(i_sender, true)
				i.set_slot_type_right(i_sender, types.find(fork))

			if i.title == recivier.name:
				if !i.inputs.has(fork):
					var cc : Control = Control.new()
					cc.rect_min_size = Vector2(10,10)
					i.add_child(cc)
					i.inputs.append(fork)

				i_recivier = i.inputs.find(fork)
				i.set_slot_enabled_left(i_recivier, true)
				i.set_slot_type_left(i_recivier, types.find(fork))
	# find the name of the Graphnode by checking all of thier meta data and if it matches get the name of the node graph
	connect_node(sender.name, i_sender, recivier.name, i_recivier)
