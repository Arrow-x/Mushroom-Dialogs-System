tool
extends Control

var editor : PackedScene = load("res://DialogManager/Editor/FlowChartTab.tscn")
onready var editorUI : TabContainer = $FlowChartTabs

var current_tab

func _ready():
	pass

func _on_FlowChartTabs_tab_selected(tab):
	#Create a new FlowChart Resource and assosiate the meta data
	current_tab = tab
	var _tab := editorUI.get_tab_control(tab)
	if _tab.get_child_count() == 0 : 
		var _editor := editor.instance()
		_tab.add_child(_editor, true)
		
		var _plus := Tabs.new()
		_plus.name = "FlowChart*"
		editorUI.add_child(_plus, true)
	
