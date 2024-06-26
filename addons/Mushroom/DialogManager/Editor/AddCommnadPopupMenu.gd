@tool
extends PopupMenu

var commands := [
	"Say",
	"Fork",
	"If",
	"Else",
	"If Else",
	"General Container",
	"Random",
	"Call Function",
	"Emit Signal",
	"Set Variable",
	"Animation",
	"Play Sound",
	"Jump",
	"Change UI",
	"ShowMedia"
]


func ready_commands():
	clear()

	for i in range(commands.size()):
		match commands[i]:
			"Say":
				add_item("Say", i)
				set_item_metadata(i, SayCommand.new())
			"Animation":
				add_item("Animation", i)
				set_item_metadata(i, AnimationCommand.new())
			"Fork":
				add_item("Fork", i)
				set_item_metadata(i, ForkCommand.new())
			"If":
				add_item("If", i)
				set_item_metadata(i, ConditionCommand.new())
			"Else":
				add_item("Else", i)
				set_item_metadata(i, ElseCommand.new())
			"If Else":
				add_item("If Else", i)
				set_item_metadata(i, IfElseCommand.new())
			"Play Sound":
				add_item("Play Sound", i)
				set_item_metadata(i, SoundCommand.new())
			"Change UI":
				add_item("Change UI", i)
				set_item_metadata(i, ChangeUICommand.new())
			"Call Function":
				add_item("Call Function", i)
				set_item_metadata(i, CallFunctionCommand.new())
			"Emit Signal":
				add_item("Emit Signal", i)
				set_item_metadata(i, SignalCommand.new())
			"General Container":
				add_item("General Container", i)
				set_item_metadata(i, GeneralContainerCommand.new())
			"Jump":
				add_item("Jump", i)
				set_item_metadata(i, JumpCommand.new())
			"Set Variable":
				add_item("Set Variable", i)
				set_item_metadata(i, SetVarCommand.new())
			"Random":
				add_item("Random", i)
				set_item_metadata(i, RandomCommand.new())
			"ShowMedia":
				add_item("ShowMedia", i)
				set_item_metadata(i, ShowMediaCommand.new())
			_:
				push_error("Add Command Popup: unknown command")
				return
