extends Control
onready var choices_container: Control = $ScrollContainer/ChoicesContainer
onready var add_choice_button: Button = $ScrollContainer/ChoicesContainer/InfoBar/AddChoiceButton

var current_fork: fork_command
var fc: FlowChart


func _on_AddChoiceButton_pressed():
	var choice_control: Control = load("res://DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
	choices_container.add_child(choice_control)
	choice_control.flowchart = fc
	var n_c: choice = choice.new()
	current_fork.choices.append(n_c)
	choice_control.current_choice = n_c


func set_up(f: fork_command, flowchart: FlowChart):
	current_fork = f
	fc = flowchart
	if f.choices != null:
		for i in f.choices:
			var choice_control: Control = load("res://DialogManager/Editor/Commands/ChoiceControl.tscn").instance()
			choices_container.add_child(choice_control)
			choice_control.set_up(i, flowchart)
