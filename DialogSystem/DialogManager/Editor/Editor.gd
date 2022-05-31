tool
extends Control
var editor_scn: PackedScene = preload("res://DialogManager/Editor/FlowChartTab.tscn")
onready var flowchart_tabs: TabContainer = $FlowChartTabs


func open_flowchart_scene(flowchart_scene: FlowChart):
	# TODO Check if the flowchart is already open and switch to it instead
	# TODO have the tab show if the flowchart is modified
	# TODO add close button
	# TODO incease of file being deleted while it is still in memory prompt of saving using the old systme
	var ed := editor_scn.instance()
	ed.set_flowchart(flowchart_scene)
	flowchart_tabs.add_child(ed)
	ed.name = flowchart_scene.get_name()
