extends Control
#This Need a refactor
var editor: PackedScene = preload("res://DialogManager/Editor/FlowChartTab.tscn")
onready var editorUI: TabContainer = $FlowChartTabs
var clicked_tab: Control
var file_dialog: FileDialog


func _on_FlowChartTabs_tab_selected(tab) -> void:
	var _tab := editorUI.get_tab_control(tab)
	#this checks if the tab have any childern if they do nothing will happend
	#if the don't (only the + tab should not have any childern at any given time)
	clicked_tab = _tab
	if _tab.get_child_count() != 0:
		return
	file_dialog_save()


func file_dialog_save(saved: PackedScene = null, io: String = "Save") -> void:
	file_dialog = FileDialog.new()
	file_dialog.resizable = true
	$Misc.add_child(file_dialog)
	file_dialog.margin_right = 500
	file_dialog.margin_bottom = 300
	if saved == null and io == "Save":
		file_dialog.current_file = "new_flowchart"
		file_dialog.connect("file_selected", self, "_on_FileDialog_flowchart_selected")

	if saved is PackedScene and io == "Save":
		file_dialog.current_file = "new_flowchart_scene"
		file_dialog.connect(
			"file_selected", self, "_on_FileDialog_flowchart_scene_selected", [saved]
		)

	if saved is PackedScene and io == "Open":
		file_dialog.mode = 1

	file_dialog.popup_exclusive = true
	file_dialog.popup_centered()
	file_dialog.get_cancel().connect("pressed", self, "_on_FileDialog_Closed")
	file_dialog.get_close_button().connect("pressed", self, "_on_FileDialog_Closed")
	$Panel.visible = true


func _on_FileDialog_Closed() -> void:
	$Panel.visible = false
	#when canseling a new file creation tab it will stay on the new empty tab but this resets to the previews seleceted tab
	if editorUI.current_tab != 0:
		editorUI.current_tab = editorUI.get_previous_tab()
	for c in $Misc.get_children():
		c.queue_free()


func _on_FileDialog_flowchart_selected(path: String) -> void:
	if path.is_valid_filename() == true:
		throw_warning("Please Enter a valid name!\nwithout : / \u005c ? * \u0022 | % < >")
		return

	if clicked_tab.get_child_count() == 0:
		var flowchart = FlowChart.new()
		var _editor := editor.instance()

		if !path.ends_with(".tres"):
			var mod_path: String = path.insert(path.length(), ".tres")
			ResourceSaver.save(mod_path, flowchart)
			_editor.flowchart_path = mod_path
		else:
			ResourceSaver.save(path, flowchart)
			_editor.flowchart_path = path

		clicked_tab.add_child(_editor, true)
		_editor.flowchart = flowchart

		clicked_tab.name = path.get_file().trim_suffix(".tres")
		var _plus := Tabs.new()
		_plus.name = "+"
		editorUI.add_child(_plus, true)
		$Panel.visible = false
		for c in $Misc.get_children():
			c.queue_free()


func _open_flowchart_scene(flowchart_scene: PackedScene):
	editorUI.add_child(flowchart_scene.instance(), true)


func _on_FileDialog_flowchart_scene_selected(path: String, saved: PackedScene):
	ResourceSaver.save(path, saved)
	$Panel.visible = false
	for c in $Misc.get_children():
		c.queue_free()


func throw_warning(warning: String) -> void:
	var _warning = AcceptDialog.new()
	$Misc.add_child(_warning)
	_warning.dialog_text = warning
	_warning.connect("confirmed", self, "_on_warning_confirmed")
	_warning.popup_centered()


func _on_warning_confirmed() -> void:
	for c in $Misc.get_children():
		c.queue_free()
	file_dialog_save()
