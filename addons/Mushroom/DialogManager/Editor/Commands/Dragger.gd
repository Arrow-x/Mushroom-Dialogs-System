@tool
extends Control

@export var type: String
@export var extension: String

signal value_dragged(value)


func _can_drop_data(position: Vector2, data) -> bool:
	if not data is Dictionary or not "type" in data:
		print("is not Dict")
		return false

	if extension != "":
		if not data.type == "files":
			print("is not files")
			return false
		if not data.files.size() == 1:
			print("is not size")
			return false
		if not data.files[0].get_extension() == extension:
			print("is not extension")
			return false

	if type != "":
		if data.has("files"):
			if not load(data["files"][0]).is_class(type):
				print("is not type")
				return false
		if data.has("nodes"):
			# TODO: search the currnt opend scene in the editor, and find the dragged data there somehow
			# Hover this will work find at run time
			if not get_node(str(data["nodes"][0])).is_class(type):
				print("is not type")
				return false
	return true


func _drop_data(position: Vector2, data) -> void:
	if data.has("files"):
		value_dragged.emit(load(data["files"][0]))
	if data.has("nodes"):
		value_dragged.emit(get_node(str(data["nodes"][0])))
