tool
extends EditorPlugin

const editor := preload("res://DialogManager/Editor/Editor.tscn")
var editor_instance


func _enter_tree():
	editor_instance = editor.instance()
	get_editor_interface().get_editor_viewport().add_child(editor_instance)
	make_visible(false)


func _exit_tree():
	editor_instance.queue_free()


func handles(object):
	if object is FlowChart:
		return true


func edit(object):
	editor_instance.open_flowchart_scene(object)
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