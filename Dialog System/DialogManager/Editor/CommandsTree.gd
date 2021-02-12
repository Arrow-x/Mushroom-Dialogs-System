extends Tree

onready var tree = self
onready var root = tree.create_item()
onready var current_block_label : Label = $"../inspectorHeader/inspectorHeaderHBoxContainer/CurrentBlock"
onready var commands_settings : Panel = $"../../CommandsSettings"


var current_block : block
#Set up drag and droping, multiselect...
func _ready():
	tree.set_hide_root(true)

func _on_GraphNode_graph_node_meta(meta, title) -> void:
	commands_settings._currnet_title = title
	current_block = meta
	current_block_label.text = "current block: " + title
	tree.clear()
	for i in meta.commands :
		_add_command(i)

func _on_add_command (id: int, pop_up : Popup) -> void:
	var _command : Command
	if current_block == null:
		return
		
	var _getter : Command = pop_up.get_item_metadata(id)
	_command = _getter.duplicate() #Carful with the Conditional Command
	_add_command(_command)
	current_block.commands.append(_command)

func _add_command(command : Command) -> void:
	if root == null :
		root = tree.create_item()
		tree.set_hide_root(true)
		
	var _item : TreeItem = tree.create_item(root)
	_item.set_text(0, command.type)
	_item.set_meta("0", command)

func _on_CommandsTree_item_activated() -> void:
	if get_selected():
		if get_selected().get_meta("0") != null:
			if commands_settings.get_child_count() != 0:
				if commands_settings.get_child(0) != null :
					commands_settings.get_child(0).free()
					
			match get_selected().get_meta("0").type : 
				"say" :
					var say_control = load("res://DialogManager/Editor/Commands/SayControl.tscn").instance()
					commands_settings.add_child(say_control, true)
				

