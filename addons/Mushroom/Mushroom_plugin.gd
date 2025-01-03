@tool
extends EditorPlugin

const Editor := preload("res://addons/Mushroom/DialogManager/Editor/Scenes/Editor.tscn")

const DEFAULT_TRANSLATION := "res://Translations/default.en.translation"
const TRANSLATION_SETTING := "internationalization/locale/translations"

var editor_instance: Control

func _enter_tree() -> void:

	var translation_setting := ProjectSettings.get_setting(TRANSLATION_SETTING)

	if translation_setting.is_empty() or TranslationServer.get_translation_object("en") == null:
		var new_defult_translation := Translation.new()
		new_defult_translation.locale = "en"
		DirAccess.make_dir_absolute("res://Translations/")
		ResourceSaver.save(new_defult_translation, DEFAULT_TRANSLATION)
		ProjectSettings.set_setting(TRANSLATION_SETTING, PackedStringArray([DEFAULT_TRANSLATION]))

	remove_autoload_singleton("DialogManagerNode")
	add_autoload_singleton(
		"DialogManagerNode", "res://addons/Mushroom/DialogManager/DialogManagerNode.tscn"
	)

	EditorInterface.get_file_system_dock().resource_removed.connect(
		remove_flowchart_entries_from_translation
	)
	EditorInterface.get_file_system_dock().files_moved.connect(
		move_flowchart_entries_in_translation
	)

	editor_instance = Editor.instantiate()
	editor_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(editor_instance)

	_make_visible(false)


func remove_flowchart_entries_from_translation(deleted_resoruce: Resource) -> void:
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


func move_flowchart_entries_in_translation(old_file: String, new_file: String) -> void:
	var tr_obj := TranslationServer.get_translation_object("en")
	var old_file_fn := str(
		"___" + old_file.get_file().trim_suffix(str("." + old_file.get_extension())) + "___"
	)
	for e: int in range(tr_obj.get_message_count()):
		var msg_idx := tr_obj.get_message_list()[e]
		if msg_idx.contains(old_file_fn):
			var new_name := msg_idx.replace(
				old_file_fn,
				str(
					(
						"___"
						+ new_file.get_file().trim_suffix(str("." + new_file.get_extension()))
						+ "___"
					)
				)
			)
			tr_obj.add_message(new_name, tr_obj.get_translated_message_list()[e])
			tr_obj.erase_message(msg_idx)


func _exit_tree() -> void:
	if editor_instance:
		editor_instance.queue_free()


func _handles(object: Object) -> bool:
	if object is FlowChart:
		if object.get_flowchart_name() != "":
			return true
	return false


func _edit(object: Object) -> void:
	if object == null:
		return
	editor_instance.open_flowchart_scene(object, get_undo_redo())
	_make_visible(true)


func _apply_changes() -> void:
	editor_instance.save_flowcharts()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if editor_instance:
		editor_instance.visible = visible


func _get_plugin_name() -> String:
	return "Mushroom"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
