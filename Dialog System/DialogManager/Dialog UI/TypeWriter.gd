extends RichTextLabel

export var speed : int = 50

var _isready : bool
var _speed_mult : int = 1
var _last_speed : int = 1
var _done : bool
var _error

onready var _tween: Tween = Tween.new()

signal message_done
signal message_start

func _ready():
	add_child(_tween)
	
	_tween.playback_speed = speed
	
	clear()
	
func _process(delta):
	if _speed_mult != _last_speed:
		_last_speed = _speed_mult
		_tween.playback_speed = _speed_mult * speed

func send_message(val: String , append : bool = false):
	if append : 
		var _start_value = get_bbcode().length()
		append_bbcode (" " + val)
		_start_msg(_start_value)
		return

	set_bbcode(val)
	_start_msg()

func _start_msg (start_tween : int = 0):
	_speed_mult = 1
	_last_speed = 1
	
	visible_characters = 0
	percent_visible = 0
	
	if _tween.is_active():
		_tween.remove_all()

	if speed != 0:
		_tween.playback_speed = speed
		_done = false
		_error = _tween.interpolate_property(self, "visible_characters", start_tween, text.length(), text.length() - start_tween)
		
		print("_tween.interpolate_property returns: ",_error)
		print("Start: ",start_tween, " to: ",text.length()," for: ",text.length() - start_tween )
		
		_tween.start()
		emit_signal("message_start")
		yield (_tween, "tween_completed")
		_on_done()
	else:
		print ("Why?")
		percent_visible = 1.0
		_on_done()
		
func _on_done():
	_done = true
	emit_signal("message_done")

func skip_tween():
	_on_done()
	_tween.remove_all()
	visible_characters = -1
