@tool
extends Control

@export var i_flowchart_control: PackedScene
@export var flowcharts_container: Control
@export var f_tabs: TabBar

var undo_redo: EditorUndoRedoManager
var commands_clipboard: Array


func open_flowchart_scene(flowchart: FlowChart, u_r: EditorUndoRedoManager) -> void:
	undo_redo = u_r
	for tab in flowcharts_container.get_children():
		if tab.flowchart == flowchart:
			var c_tab_idx = flowcharts_container.get_children().find(tab)
			f_tabs.set_current_tab(c_tab_idx)
			_on_new_flowchart_tabs_tab_clicked(c_tab_idx)
			return

	var fc_control: Control = i_flowchart_control.instantiate()
	flowcharts_container.add_child(fc_control)
	fc_control.set_flowchart(flowchart, u_r, self)

	var flowchart_name := flowchart.get_flowchart_name()
	fc_control.name = flowchart_name
	fc_control.flow_tabs = f_tabs
	f_tabs.add_tab(flowchart_name)
	var fc_control_idx := flowcharts_container.get_children().find(fc_control)
	fc_control.f_tab_changed.connect(select_flowchart_tab)
	f_tabs.set_current_tab(fc_control_idx)


func _on_new_flowchart_tabs_tab_clicked(tab: int) -> void:
	var flowchart_editors := flowcharts_container.get_children()
	for e in flowchart_editors:
		e.visible = false
	flowchart_editors[tab].visible = true
	f_tabs.set_current_tab(tab)


func select_flowchart_tab(fc: FlowChart) -> void:
	var flowchart_editors := flowcharts_container.get_children()
	if flowchart_editors[f_tabs.get_current_tab()].flowchart == fc:
		return
	for i in range(flowchart_editors.size()):
		var e := flowchart_editors[i]
		e.visible = false
		if e.flowchart == fc:
			e.visible = true
			f_tabs.set_current_tab(i)


func _on_new_flowchart_tabs_tab_close(tab: int) -> void:
	var flowchart_editors := flowcharts_container.get_children()
	if (
		flowchart_editors[tab].modified == true
		or flowchart_editors[tab].flowchart.resource_path == ""
	):
		var accept_d := AcceptDialog.new()
		accept_d.set_text("Save changes in flowchart before closing?")
		accept_d.set_title("Please Confirm...")
		accept_d.add_cancel_button("Cancel")
		accept_d.add_button("Don't Save", false, "discard")
		accept_d.get_ok_button().set_text("Save & Close")
		accept_d.confirmed.connect(
			_close_confirm_choice.bind("save", flowchart_editors, tab, accept_d)
		)
		accept_d.custom_action.connect(_close_confirm_choice.bind(flowchart_editors, tab, accept_d))
		accept_d.set_size(Vector2(0, 0))
		add_child(accept_d)
		accept_d.popup_centered()
		return
	free_tab_and_select_another(flowchart_editors, tab)


func _close_confirm_choice(
	custom_action, flowchart_editors: Array, tab: int, confirm_window: AcceptDialog
) -> void:
	if custom_action == "cancel":
		confirm_window.queue_free()
		return
	if custom_action == "save":
		flowchart_editors[tab].check_flowchart_path_before_save()
		flowchart_editors[tab].done_saving.connect(
			free_tab_and_select_another.bind(flowchart_editors, tab, confirm_window)
		)
		return

	free_tab_and_select_another(flowchart_editors, tab, confirm_window)


func _on_tabs_reposition_active_tab_request(idx_to: int) -> void:
	var flowchart_editor: Control = flowcharts_container.get_children()[f_tabs.get_current_tab()]
	flowcharts_container.move_child(flowchart_editor, idx_to)


func save_flowcharts() -> void:
	for container in flowcharts_container.get_children():
		container.check_flowchart_path_before_save()


func free_tab_and_select_another(
	flowchart_editors: Array, tab: int, confirm_window: AcceptDialog = null
) -> void:
	if confirm_window != null:
		confirm_window.queue_free()
	if tab == f_tabs.get_current_tab():
		for fc_editor in flowchart_editors:
			fc_editor.visible = false
		if tab > 0:
			flowchart_editors[tab - 1].visible = true
		elif tab == 0:
			if tab + 1 < flowchart_editors.size():
				flowchart_editors[tab + 1].visible = true

	flowchart_editors[tab].queue_free()
	f_tabs.remove_tab(tab)
