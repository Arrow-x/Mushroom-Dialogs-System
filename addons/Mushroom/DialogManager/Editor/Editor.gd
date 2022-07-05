tool
extends Control
var editor_scn: PackedScene = preload("res://addons/Mushroom/DialogManager/Editor/FlowChartTab.tscn")
# onready var flowchart_tabs: TabContainer = $FlowChartTabs
onready var flowchart_tabs: Control = $VBoxContainer/FlowCharTabs
onready var f_tabs: Tabs = $VBoxContainer/Tabs


func open_flowchart_scene(flowchart_scene: FlowChart):
	##### TODO if the file currently being editied is deleted form disk, ask user where they want to safe a new file
	# TODO have the tab show if the flowchart is modified
	##### TODO For the Say Command
	##### TODO For The Fork Command

	# BUG when creating a flowchart an empty editor appear
	if flowchart_scene.get_name() == "":
		return

	for tab in flowchart_tabs.get_children():
		if tab.flowchart == flowchart_scene:
			var c_tab_idx = flowchart_tabs.get_children().find(tab)
			f_tabs.set_current_tab(c_tab_idx)
			_on_NewFlowChartTabs_tab_clicked(c_tab_idx)
			tab.name = flowchart_scene.get_name()
			return
	var ed := editor_scn.instance()
	ed.set_flowchart(flowchart_scene)
	flowchart_tabs.add_child(ed)

	ed.name = flowchart_scene.get_name()
	ed.flow_tabs = f_tabs

	f_tabs.add_tab(flowchart_scene.get_name())
	f_tabs.set_current_tab(flowchart_tabs.get_children().find(ed))


func _on_NewFlowChartTabs_tab_clicked(tab: int) -> void:
	var tab_c := flowchart_tabs.get_children()
	for c in tab_c:
		c.visible = false
	tab_c[tab].visible = true


func _on_NewFlowChartTabs_tab_close(tab: int) -> void:
	var tab_c := flowchart_tabs.get_children()
	f_tabs.remove_tab(tab)
	tab_c[tab].queue_free()
	if tab_c.size() != 0:
		tab_c[tab - 1].visible = true


func _on_Tabs_reposition_active_tab_request(idx_to: int) -> void:
	var tab_c: Control = flowchart_tabs.get_children()[f_tabs.get_current_tab()]
	flowchart_tabs.move_child(tab_c, idx_to)
