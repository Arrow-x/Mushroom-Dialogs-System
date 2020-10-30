class_name dialog_ui_control
#an interface for the dialog UI controller
extends Node

func hide_say() -> void:
	pass
	
func show_say() -> void:
	pass
	
func hide_choice() -> void:
	pass
	
func show_choice() -> void:
	pass
	
func add_portrait (portrait: StreamTexture, por_pos) -> void:
	pass 
	
func hide_portriats ()-> void :
	pass
	
func add_text (got_text, got_name = "", append = false) -> void: 
	pass
	
func add_choice_button(block, id, index) -> void:
	pass

func hide_next_button() -> void:
	pass
	
func show_next_button()-> void:
	pass
	
func _on_SayText_message_done():
	pass

func _on_SayText_message_start():
	pass
