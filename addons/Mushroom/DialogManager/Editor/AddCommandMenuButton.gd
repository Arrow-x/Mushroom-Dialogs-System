@tool
extends MenuButton

@export var commands_tree: Tree

var popup := get_popup()
var commands := [
	"Say",
	"Animation",
	"Fork",
	"Conditional",
	"Call Function",
	"Change UI",
	"Else",
	"Emit Signal",
	"General Container",
	"If Else",
	"Jump",
	"Play Sound",
	"Set Variable",
]


func _ready():
	popup.id_pressed.connect(commands_tree._on_add_command.bind(popup))
	about_to_popup.connect(_on_about_to_popup)


func _on_about_to_popup() -> void:
	popup.clear()
	for i in range(commands.size()):
		match commands[i]:
			"Say":
				popup.add_item("Say", i)
				popup.set_item_metadata(i, SayCommand.new())
			"Animation":
				popup.add_item("Animation", i)
				popup.set_item_metadata(i, AnimationCommand.new())
			"Fork":
				popup.add_item("Fork", i)
				popup.set_item_metadata(i, ForkCommand.new())
			"Conditional":
				popup.add_item("Conditional", i)
				popup.set_item_metadata(i, ConditionCommand.new())
			"Else":
				popup.add_item("Else", i)
				popup.set_item_metadata(i, ElseCommand.new())
			"If Else":
				popup.add_item("If Else", i)
				popup.set_item_metadata(i, IfElseCommand.new())
			"Play Sound":
				popup.add_item("Play Sound", i)
				popup.set_item_metadata(i, SoundCommand.new())
			"Change UI":
				popup.add_item("Change UI", i)
				popup.set_item_metadata(i, ChangeUICommand.new())
			"Call Function":
				popup.add_item("Call Function", i)
				popup.set_item_metadata(i, CallFunctionCommand.new())
			"Emit Signal":
				popup.add_item("Emit Signal", i)
				popup.set_item_metadata(i, SignalCommand.new())
			"General Container":
				popup.add_item("General Container", i)
				popup.set_item_metadata(i, GeneralContainerCommand.new())
			"Jump":
				popup.add_item("Jump", i)
				popup.set_item_metadata(i, JumpCommand.new())
			"Set Variable":
				popup.add_item("Set Variable", i)
				popup.set_item_metadata(i, SetVarCommand.new())
			_:
				push_error("Add Command Popup: unknown command")
				return
