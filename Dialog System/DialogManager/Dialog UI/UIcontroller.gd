extends Node

var portraits : Dictionary

onready var say_pannel = $SayPanel
onready var say_text = $SayPanel/SayText
onready var say_name = $SayPanel/NameText
onready var next_button =$SayPanel/NextButton
onready var choice_container = $VBoxChoiceContainer
onready var right_portrait = $RightPortrait
onready var center_portrait = $CenterPortrait
onready var left_portrait = $LeftPortrait

#TODO: BBCode Support, 
#Unlimited Portraits,
#Animations on the SayPanel
#Animations on the Portraits

func _ready():
	next_button.connect("pressed",DialogManager,"execute_dialog")
	say_text.text = ""

func hide_say() -> void:
	if say_pannel.visible:
		say_pannel.visible = false
		var port : Array = [right_portrait, center_portrait, left_portrait]
		for i in port:
			i.visible  = false

func show_say() -> void:
	if !say_pannel.visible:
		say_pannel.visible = true

func hide_choice() -> void:
	if choice_container.visible:
		choice_container.visible = false
		var ac : Array = choice_container.get_children()
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
	
func add_text(got_text, got_name) -> void: 
	say_text.text = got_text
	say_name.text = got_name

func add_choice_button(block, id, index) -> void:
	var s = Button.new()
	s.text = block.text
	choice_container.add_child(s)
	s.connect("pressed",DialogManager,"_on_make_choice",[id,index])
