tool
extends Control
var editor_scn: PackedScene = preload("res://addons/Mushroom/DialogManager/Editor/FlowChartTab.tscn")
onready var flowchart_tabs: TabContainer = $FlowChartTabs


func open_flowchart_scene(flowchart_scene: FlowChart):
	# TODO Switch to Tabs Node to get a close button
	##### TODO incease of file being deleted while it is still in memory prompt of saving using the old systme
	# TODO have the tab show if the flowchart is modified
	if flowchart_scene.get_name() == "":
		return
	for tab in flowchart_tabs.get_children():
		if tab.flowchart == flowchart_scene:
			flowchart_tabs.set_current_tab(flowchart_tabs.get_children().find(tab))
			tab.name = flowchart_scene.get_name()
			return
	var ed := editor_scn.instance()
	ed.set_flowchart(flowchart_scene)
	flowchart_tabs.add_child(ed)
	ed.name = flowchart_scene.get_name()
	flowchart_tabs.set_current_tab(flowchart_tabs.get_children().find(ed))
