tool
extends Control
var editor_scn := preload("res://addons/Mushroom/DialogManager/Editor/FlowChartTab.tscn")
onready var flowcharts_container := $VBoxContainer/FlowCharTabs
onready var f_tabs := $VBoxContainer/Tabs


func open_flowchart_scene(flowchart_scene: FlowChart, undo_redo: UndoRedo) -> void:
	for tab in flowcharts_container.get_children():
		if tab.flowchart == flowchart_scene:
			var c_tab_idx = flowcharts_container.get_children().find(tab)
			f_tabs.set_current_tab(c_tab_idx)
			_on_NewFlowChartTabs_tab_clicked(c_tab_idx)
			return

	var ed := editor_scn.instance()
	flowcharts_container.add_child(ed)
	ed.set_flowchart(flowchart_scene, undo_redo)

	ed.name = flowchart_scene.get_name()
	ed.flow_tabs = f_tabs

	f_tabs.add_tab(flowchart_scene.get_name())
	f_tabs.set_current_tab(flowcharts_container.get_children().find(ed))


func _on_NewFlowChartTabs_tab_clicked(tab: int) -> void:
	var flowchart_editors := flowcharts_container.get_children()
	for c in flowchart_editors:
		c.visible = false
	flowchart_editors[tab].visible = true


func _on_NewFlowChartTabs_tab_close(tab: int) -> void:
	var flowchart_editors := flowcharts_container.get_children()
	if (
		flowchart_editors[tab].modified == true
		or flowchart_editors[tab].flowchart.resource_path == ""
	):
		var _c := AcceptDialog.new()
		_c.set_text("Save changes in flowchart before closing?")
		_c.set_title("Please Confirm...")
		_c.add_button("Cancel", OS.is_ok_left_and_cancel_right(), "cancel")
		_c.add_button("Don't Save", OS.is_ok_left_and_cancel_right(), "discard")
		_c.get_ok().set_text("Save & Close")
		_c.connect("confirmed", self, "_close_confirm_choice", ["save", flowchart_editors, tab, _c])
		_c.connect("custom_action", self, "_close_confirm_choice", [flowchart_editors, tab, _c])
		_c.set_size(Vector2(0, 0))
		add_child(_c)
		_c.popup_centered()
		return
	_free_tab_and_select_another(flowchart_editors, tab)


func _close_confirm_choice(custom_action, flowchart_editors, tab, confirm_window) -> void:
	if custom_action == "cancel":
		confirm_window.queue_free()
		return
	if custom_action == "save":
		flowchart_editors[tab]._on_Button_pressed()
		flowchart_editors[tab].connect(
			"done_saving",
			self,
			"_free_tab_and_select_another",
			[flowchart_editors, tab, confirm_window]
		)
		return

	_free_tab_and_select_another(flowchart_editors, tab, confirm_window)


func _on_Tabs_reposition_active_tab_request(idx_to: int) -> void:
	var flowchart_editor: Control = flowcharts_container.get_children()[f_tabs.get_current_tab()]
	flowcharts_container.move_child(flowchart_editor, idx_to)


func _free_tab_and_select_another(flowchart_editors, tab, confirm_window = null) -> void:
	if confirm_window != null:
		confirm_window.queue_free()
	if tab == f_tabs.get_current_tab():
		for c in flowchart_editors:
			c.visible = false
		if tab > 0:
			flowchart_editors[tab - 1].visible = true
		elif tab == 0:
			if tab + 1 < flowchart_editors.size():
				flowchart_editors[tab + 1].visible = true

	flowchart_editors[tab].queue_free()
	f_tabs.remove_tab(tab)
