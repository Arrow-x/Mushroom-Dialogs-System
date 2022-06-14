extends Node

var portraits: Dictionary

export(NodePath) var _say_pannel
export(NodePath) var _say_text
export(NodePath) var _say_name
export(NodePath) var _next_button
export(NodePath) var _choice_container
export(NodePath) var _right_portrait
export(NodePath) var _center_portrait
export(NodePath) var _left_portrait

var say_pannel
var say_text
var say_name
var next_button
var choice_container
var right_portrait
var center_portrait
var left_portrait

var is_tweening = false


func _ready():
	say_pannel = get_node(_say_pannel)
	say_text = get_node(_say_text)
	say_name = get_node(_say_name)
	next_button = get_node(_next_button)
	choice_container = get_node(_choice_container)
	right_portrait = get_node(_right_portrait)
	center_portrait = get_node(_center_portrait)
	left_portrait = get_node(_left_portrait)

	next_button.connect("pressed", DialogManager, "advance")
	say_text.text = ""

	say_text.connect("message_done", self, "_on_SayText_message_done")
	say_text.connect("message_start", self, "_on_SayText_message_start")


func hide_say() -> void:
	if say_pannel.visible:
		say_pannel.visible = false
		var port: Array = [right_portrait, center_portrait, left_portrait]
		for i in port:
			i.visible = false


func show_say() -> void:
	if !say_pannel.visible:
		say_pannel.visible = true


func hide_choice() -> void:
	if choice_container.visible:
		choice_container.visible = false
		var ac: Array = choice_container.get_children()
		for i in ac.size():
			ac[i].queue_free()


func show_choice() -> void:
	if !choice_container.visible:
		choice_container.visible = true


func add_portrait(portrait: StreamTexture, por_pos) -> void:
	match por_pos:
		"Right":
			right_portrait.texture = portrait
			right_portrait.visible = true
		"Left":
			left_portrait.texture = portrait
			left_portrait.visible = true
		"Center":
			center_portrait.texture = portrait
			center_portrait.visible = true


func add_text(got_text, got_name, append = false) -> void:
	say_text.send_message(got_text, append)
	say_name.text = got_name


func add_choice(block, id, index) -> void:
	var s = Button.new()
	s.text = block.text
	choice_container.add_child(s)
	s.connect("pressed", DialogManager, "_on_make_choice", [id, index])


func _on_SayText_message_done():
	is_tweening = false


func _on_SayText_message_start():
	is_tweening = true
