extends Control

var editor : PackedScene = load("res://DialogManager/Editor/FlowChartTab.tscn")
onready var editorUI : TabContainer = $FlowChartTabs
var clicked_tab : Control

func _on_FlowChartTabs_tab_selected(tab):
	#Create a new FlowChart Resource and assosiate the meta data
	var _tab := editorUI.get_tab_control(tab)
	clicked_tab = _tab
	if _tab.get_child_count() != 0 : 
		return
	add_tab()
	
func add_tab():
	var file_dialog := FileDialog.new()
	file_dialog.resizable = true
	$Misc.add_child(file_dialog)
	file_dialog.margin_right = 500
	file_dialog.margin_bottom =  300
	file_dialog.popup_centered()
	$Panel.visible = true
	file_dialog.get_cancel().connect("pressed",self,"_on_FileDialog_Closed")
	file_dialog.get_close_button().connect("pressed",self,"_on_FileDialog_Closed")
	file_dialog.connect("file_selected",self,"_on_FileDialog_file_selected")

func _on_FileDialog_Closed ():
	$Panel.visible = false
	if editorUI.current_tab != 0: 
		editorUI.current_tab = editorUI.get_previous_tab()
	for c in $Misc.get_children():
		c.queue_free()

func _on_FileDialog_file_selected(path: String):
	if path == "res://" :
		var _warning = AcceptDialog.new()
		$Misc.add_child(_warning)
		_warning.dialog_text = "Please Enter a name!"
		_warning.connect("confirmed", self, "_on_warning_confirmed")
		_warning.popup_centered()
		return

	if path.is_valid_filename() == true:
		var _warning = AcceptDialog.new()
		$Misc.add_child(_warning)
		_warning.dialog_text = "Please Enter a valid name!\nwithout : / \u005c ? * \u0022 | % < >"
		_warning.connect("confirmed", self, "_on_warning_confirmed")
		_warning.popup_centered()
		return
		
	if clicked_tab.get_child_count() == 0 : 
		var flowchart = FlowChart.new()
		var _editor := editor.instance()
		_editor.flowchart = flowchart
	#   somehow pass the entered name of the file to
	#	SAVE THE FLOWCHART INTO DISK!!!!!
		clicked_tab.add_child(_editor, true)
		
		var _plus := Tabs.new()
		_plus.name = "FlowChart*"
		editorUI.add_child(_plus, true)
		$Panel.visible = false
		for c in $Misc.get_children():
			c.queue_free()

func _on_warning_confirmed():
	for c in $Misc.get_children():
		c.queue_free()
	add_tab()
