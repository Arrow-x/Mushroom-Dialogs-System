tool
extends Control

var current_condition: condition_command


func set_up(cc: condition_command) -> void:
	current_condition = cc

	var check_type_popup: PopupMenu = get_node("ReqVar/CheckType").get_popup()
	check_type_popup.connect("id_pressed", self, "_on_CheckTypePopup", [check_type_popup])

	current_condition.condition_block = block.new()

	get_node("ReqNode/ReqNodeInput").text = current_condition.required_node
	get_node("ReqVar/ReqVarInput").text = current_condition.required_var
	get_node("HBoxContainer/CheckValInput").text = current_condition.check_val
	get_node("ReqVar/CheckType").text = current_condition.condition_type


func _on_CheckValInput_text_changed(new_text: String) -> void:
	current_condition.check_val = new_text
	is_changed()


func _on_ReqVarInput_text_changed(new_text: String) -> void:
	current_condition.required_var = new_text
	is_changed()


func _on_ReqNodeInput_text_changed(new_text: String) -> void:
	current_condition.required_node = new_text
	is_changed()


func _on_CheckTypePopup(id: int, popup: PopupMenu) -> void:
	var pp_text: String = popup.get_item_text(id)
	current_condition.condition_type = pp_text
	get_node("ReqVar/CheckType").text = pp_text
	is_changed()


func get_command() -> Command:
	return current_condition


func is_changed() -> void:
	current_condition.emit_signal("changed")
