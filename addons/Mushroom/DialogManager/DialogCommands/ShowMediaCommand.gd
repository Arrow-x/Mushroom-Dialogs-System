@tool
extends Command
class_name ShowMediaCommand

@export_enum("image", "video", "clear") var media_type := "clear"
@export var media: Resource


func preview() -> String:
	if media_type != "clear":
		return str(
			(
				"ShowMedia: "
				+ media_type
				+ " : "
				+ (media.resource_path.get_file() if media != null else "null")
			)
		)
	else:
		return "ShowMedia: Clear"


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/video.png")


func get_class() -> String:
	return "ShowMediaCommand"


func is_class(c: String) -> bool:
	return c == "ShowMediaCommand"
