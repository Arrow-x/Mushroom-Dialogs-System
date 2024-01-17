@tool
extends EditorPlugin

const editor := preload("res://addons/Mushroom/DialogManager/Editor/Scenes/Editor.tscn")
var editor_instance
var counter: int = 2


func _enter_tree():
	editor_instance = editor.instantiate()
	remove_autoload_singleton("DialogManagerNode")
	add_autoload_singleton(
		"DialogManagerNode", "res://addons/Mushroom/DialogManager/DialogManagerNode.tscn"
	)
	get_editor_interface().get_editor_main_screen().add_child(editor_instance)
	EditorInterface.get_file_system_dock().resource_removed.connect(
		remove_flowchart_entries_from_translation
	)
	_make_visible(false)


func remove_flowchart_entries_from_translation(deleted_resoruce: Resource):
	if not deleted_resoruce is FlowChart:
		return
	var tr_obj := TranslationServer.get_translation_object("en")
	for b: StringName in deleted_resoruce.blocks:
		for c: Command in deleted_resoruce.blocks[b].commands:
			if c is SayCommand:
				tr_obj.erase_message(c.tr_code)
			elif c is ForkCommand:
				for cc: Choice in c.choices:
					tr_obj.erase_message(cc.tr_code)


func _exit_tree():
	editor_instance.queue_free()


func _handles(object: Object):
	if object is FlowChart:
		if object.get_flowchart_name() != "":
			return true


func _edit(object: Object):
	if object == null:
		return
	editor_instance.open_flowchart_scene(object, get_undo_redo())
	_make_visible(true)


func _apply_changes() -> void:
	# HACK: this event fire twice for some reason
	if counter == 2:
		counter -= 1
	elif counter == 1:
		editor_instance.save_flowcharts()
		counter = 2


func _has_main_screen():
	return true


func _make_visible(visible):
	if editor_instance:
		editor_instance.visible = visible


func _get_plugin_name():
	return "Mushroom"

# func _get_plugin_icon():
# 	# Must return some kind of Texture for the icon.
# 	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
