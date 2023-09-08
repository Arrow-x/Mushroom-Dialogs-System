tool
extends Control

export var type: String
signal value_dragged(value)


func can_drop_data(position: Vector2, data) -> bool:
	if not data is Dictionary or not "type" in data:
		return false

	if not data.type == "files":
		return false

	if not data.files.size() == 1:
		return false

	if not data.files[0].get_extension() == "tres":
		return false

	if load(data["files"][0]).is_class(type):
		return true
	return false


func drop_data(position: Vector2, data) -> void:
	print("loaded")
	emit_signal("value_dragged", load(data["files"][0]))
