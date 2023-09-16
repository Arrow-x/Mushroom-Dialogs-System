tool
extends Control

export var type: String
export var extension: String
signal value_dragged(value)


func can_drop_data(position: Vector2, data) -> bool:
	if not data is Dictionary or not "type" in data:
		print("is not Dict")
		return false

	if not data.type == "files":
		print("is not files")
		return false

	if not data.files.size() == 1:
		print("is not size")
		return false

	if extension != null:
		if not data.files[0].get_extension() == extension:
			print("is not extension")
			return false

	if type != null:
		if not load(data["files"][0]).is_class(type):
			print("is not type")
			return false
	return true


func drop_data(position: Vector2, data) -> void:
	print("loaded")
	emit_signal("value_dragged", load(data["files"][0]))
