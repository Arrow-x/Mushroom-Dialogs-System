@tool
extends Node

@export var type_menu: MenuButton
@export var image_label: Label
@export var image_container: Control
@export var video_label: Label
@export var video_container: Control

enum { CLEAR, IMAGE, VIDEO }

var current_show_media: ShowMediaCommand
var undo_redo: EditorUndoRedoManager
var prev_id: int = CLEAR
var commands_container: Node


func set_up(s_m: ShowMediaCommand, u_r: EditorUndoRedoManager, cmd_c: Node) -> void:
	current_show_media = s_m
	undo_redo = u_r
	commands_container = cmd_c
	match current_show_media.media_type:
		"clear":
			show_draggable(CLEAR)
		"image":
			show_draggable(IMAGE)
			image_label.text = (
				current_show_media.media.resource_path.get_file()
				if current_show_media.media != null
				else "..."
			)
		"video":
			show_draggable(VIDEO)
			video_label.text = (
				current_show_media.media.resource_path.get_file()
				if current_show_media.media != null
				else "..."
			)

	var popup: Popup = type_menu.get_popup()
	popup.id_pressed.connect(choose_mode)


func choose_mode(id: int) -> void:
	undo_redo.create_action("Chose A Media Mode")
	undo_redo.add_do_method(commands_container, "command_undo_redo_caller", "show_draggable", [id])
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "show_draggable", [prev_id]
	)
	undo_redo.commit_action()
	prev_id = id


func show_draggable(id: int) -> void:
	match id:
		CLEAR:
			image_container.visible = false
			video_container.visible = false
			current_show_media.media_type = "clear"
			type_menu.text = "clear"
		IMAGE:
			image_container.visible = true
			video_container.visible = false
			current_show_media.media_type = "image"
			type_menu.text = "image"
		VIDEO:
			image_container.visible = false
			video_container.visible = true
			current_show_media.media_type = "video"
			type_menu.text = "video"

	is_changed()


func _on_label_drag_image_value_dragged(value: Variant) -> void:
	undo_redo.create_action("drag media")
	undo_redo.add_do_method(commands_container, "command_undo_redo_caller", "set_image", [value])
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "set_image", [current_show_media.media]
	)
	undo_redo.commit_action()


func _on_label_drag_video_value_dragged(value: Variant) -> void:
	undo_redo.create_action("drag media")
	undo_redo.add_do_method(commands_container, "command_undo_redo_caller", "set_video", [value])
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "set_video", [current_show_media.media]
	)
	undo_redo.commit_action()


func _on_clear_video_button_pressed() -> void:
	undo_redo.create_action("drag media")
	undo_redo.add_do_method(commands_container, "command_undo_redo_caller", "set_video", [null])
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "set_video", [current_show_media.media]
	)
	undo_redo.commit_action()


func _on_clear_image_button_pressed() -> void:
	undo_redo.create_action("drag media")
	undo_redo.add_do_method(commands_container, "command_undo_redo_caller", "set_image", [null])
	undo_redo.add_undo_method(
		commands_container, "command_undo_redo_caller", "set_image", [current_show_media.media]
	)
	undo_redo.commit_action()


func set_image(media) -> void:
	current_show_media.media = media
	if media != null:
		image_label.text = media.resource_path.get_file()
	else:
		image_label.text = "..."
	is_changed()


func set_video(media) -> void:
	current_show_media.media = media
	if media != null:
		video_label.text = media.resource_path.get_file()
	else:
		video_label.text = "..."
	is_changed()


func is_changed() -> void:
	current_show_media.changed.emit(current_show_media)


func get_command() -> ShowMediaCommand:
	return current_show_media
