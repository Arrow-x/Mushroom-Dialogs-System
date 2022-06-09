tool
extends Control
onready var choices_container: Control = $ScrollContainer/ChoicesContainer
onready var add_choice_button: Button = $ScrollContainer/ChoicesContainer/InfoBar/AddChoiceButton
onready var graph: GraphEdit

var current_fork: fork_command
var current_block: block
var fc: FlowChart


func _on_AddChoiceButton_pressed() -> void:
	var choice_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
	choices_container.add_child(choice_control)
	choice_control.flowchart = fc
	var n_c: choice = choice.new()
	current_fork.choices.append(n_c)
	choice_control.current_choice = n_c
	choice_control.connect("conncting", self, "_on_connecting", [current_block])


func set_up(f: fork_command, flowcharttab: Control, cb: block) -> void:
	current_fork = f
	fc = flowcharttab.flowchart
	graph = flowcharttab.graph_edit
	current_block = cb

	if f.choices != null:
		for i in f.choices:
			var choice_control: Control = load("res://addons/Mushroom/DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
			choices_container.add_child(choice_control)
			choice_control.set_up(i, flowcharttab)
			choice_control.connect("conncting", self, "_on_connecting", [current_block])


func _on_connecting(sender) -> void:
	graph.update_block_flow(sender, current_fork)
