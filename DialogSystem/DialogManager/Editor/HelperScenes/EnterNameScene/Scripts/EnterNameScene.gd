extends WindowDialog 

signal new_text_confirm

onready var ok : Button = $VBoxContainer/HBoxContainer/OK
onready var cancel : Button = $VBoxContainer/HBoxContainer/Cancel

var node_text : String

func _ready():
	pass # Replace with function body.

func _on_LineEdit_text_changed(new_text):
	node_text = new_text

func _on_OK_pressed():
	if node_text != null :
		emit_signal("new_text_confirm", node_text)
		self.queue_free()

func _on_Cancel_pressed():
	self.queue_free()
