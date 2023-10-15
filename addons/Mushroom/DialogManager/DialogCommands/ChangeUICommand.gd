tool
extends Command
class_name ChangeUICommand

export(PackedScene) var next_UI
export(bool) var change_to_default = false


func preview() -> String:
	if change_to_default:
		return String("change_ui to default")
	else:
		if next_UI != null:
			return String("change_ui to " + next_UI.resource_path.get_file())
		else:
			return "Change to null!"


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")


func get_class() -> String:
	return "ChangeUICommand"


func is_class(c: String) -> bool:
	return c == "ChangeUICommand"
