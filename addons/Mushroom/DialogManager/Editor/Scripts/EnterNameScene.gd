@tool
extends Window

@export var ok: Button
@export var cancel: Button
@export var line_edit: LineEdit

var node_text: String

signal new_text_confirm


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		self.queue_free()


func _ready():
	close_requested.connect(_on_cancel_pressed)
	get_child(0).focus_mode = Control.FOCUS_CLICK
	line_edit.grab_focus()
	set_size(Vector2(218, 141))


func _on_line_edit_text_changed(new_text):
	node_text = new_text


func _on_ok_pressed():
	if node_text != null:
		new_text_confirm.emit(node_text)
		self.queue_free()


func _on_cancel_pressed():
	self.queue_free()


func _on_line_edit_text_entered(new_text):
	if node_text != null:
		node_text = new_text
		new_text_confirm.emit(node_text)
		self.queue_free()
