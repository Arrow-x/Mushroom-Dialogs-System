extends Control
onready var choices_container: Control = $ScrollContainer/ChoicesContainer
onready var add_choice_button: Button = $ScrollContainer/ChoicesContainer/InfoBar/AddChoiceButton
onready var graph: GraphEdit = $"/root/Editor/FlowChartTabs/new_flowchart/FlowChartTab/GraphContainer/GraphEdit"

var current_fork: fork_command
var current_block: block
var fc: FlowChart


func _on_AddChoiceButton_pressed() -> void:
	var choice_control: Control = load("res://DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
	choices_container.add_child(choice_control)
	choice_control.flowchart = fc
	var n_c: choice = choice.new()
	current_fork.choices.append(n_c)
	choice_control.current_choice = n_c
	choice_control.connect("conncting", self, "_on_connecting", [current_block])


func set_up(f: fork_command, flowchart: FlowChart, cb: block) -> void:
	current_fork = f
	fc = flowchart
	current_block = cb

	if f.choices != null:
		for i in f.choices:
			var choice_control: Control = load("res://DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
			choices_container.add_child(choice_control)
			choice_control.set_up(i, flowchart)
			choice_control.connect("conncting", self, "_on_connecting", [current_block])


func _on_connecting(rec, sender) -> void:
	graph.connect_blocks(rec, sender, current_fork)
