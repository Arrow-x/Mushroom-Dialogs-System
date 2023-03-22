tool
extends WindowDialog

signal new_text_confirm

onready var ok: Button = $VBoxContainer/HBoxContainer/OK
onready var cancel: Button = $VBoxContainer/HBoxContainer/Cancel

var node_text: String


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		self.queue_free()


func _ready():
	var get_butt = get_close_button()
	get_butt.connect("pressed", self, "_on_Cancel_pressed")
	get_child(0).focus_mode = Control.FOCUS_CLICK
	$VBoxContainer/LineEdit.grab_focus()
	set_size(Vector2(218, 141))


func _on_LineEdit_text_changed(new_text):
	node_text = new_text


func _on_OK_pressed():
	if node_text != null:
		emit_signal("new_text_confirm", node_text)
		self.queue_free()


func _on_Cancel_pressed():
	self.queue_free()


func _on_LineEdit_text_entered(new_text):
	if node_text != null:
		node_text = new_text
		emit_signal("new_text_confirm", node_text)
		self.queue_free()
