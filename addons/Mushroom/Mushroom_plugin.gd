tool
extends EditorPlugin

const editor := preload("res://addons/Mushroom/DialogManager/Editor/Editor.tscn")
var editor_instance


func _enter_tree():
	editor_instance = editor.instance()
	remove_autoload_singleton("DialogManagerNode")
	add_autoload_singleton(
		"DialogManagerNode", "res://addons/Mushroom/DialogManager/DialogManagerNode.tscn"
	)
	get_editor_interface().get_editor_viewport().add_child(editor_instance)
	make_visible(false)


func _exit_tree():
	editor_instance.queue_free()


func handles(object):
	if object is FlowChart:
		if object.get_name() != "":
			return true


func edit(object):
	editor_instance.open_flowchart_scene(object, get_undo_redo())
	make_visible(true)


func has_main_screen():
	return true


func make_visible(visible):
	if editor_instance:
		editor_instance.visible = visible


func get_plugin_name():
	return "Mushroom"


func get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
