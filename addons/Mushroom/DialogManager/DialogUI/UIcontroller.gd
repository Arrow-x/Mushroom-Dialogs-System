extends Control

var portraits: Dictionary

@export var say_pannel: Control
@export var say_text: Control
@export var say_name: Control
@export var next_button: Control
@export var choice_container: Control
@export var right_portrait: Control
@export var center_portrait: Control
@export var left_portrait: Control
@export var image_media: TextureRect
@export var video_media: VideoStreamPlayer

var is_tweening := false


func _ready():
	next_button.pressed.connect(DialogManagerNode.advance)
	say_text.text = ""

	say_text.message_done.connect(_on_SayText_message_done)
	say_text.message_start.connect(_on_SayText_message_start)


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


func add_portrait(portrait: CompressedTexture2D, por_pos) -> void:
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


func add_text(got_text: String, got_name: String, append: bool) -> void:
	say_text.send_message(got_text, append)
	say_name.text = got_name


func add_choice(text: String, id: int, index: int) -> void:
	var s := Button.new()
	s.text = text
	choice_container.add_child(s)
	s.pressed.connect(DialogManagerNode._on_make_choice.bind(id, index))


func _on_SayText_message_done():
	is_tweening = false


func _on_SayText_message_start():
	is_tweening = true


func show_image(image: Texture2D) -> void:
	clear_media()
	image_media.texture = image
	image_media.visible = true


func show_video(video: VideoStreamTheora) -> void:
	clear_media()
	video_media.stream = video
	video_media.visible = true
	video_media.play()


func clear_media() -> void:
	image_media.visible = false
	video_media.visible = false
	video_media.stream = null
	image_media.texture = null
