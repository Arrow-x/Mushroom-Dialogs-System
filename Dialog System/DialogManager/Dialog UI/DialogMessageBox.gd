tool
extends RichTextLabel
# Provides a character-by-character rich text box
# Credit TO https://github.com/tlitookilakin
#Needs Clean up ALOT of unneeded functionalty`
signal message_done
signal message_start

export(float) var speed = 1.0 setget _set_speed
export(float) var acceleration = 2 setget _set_accel
export(String) var skip_action = ""
export(String) var accelerate_action = ""

var _isready: bool = false
var _speed_mult: float = 1
var _last_speed: float = 1
var _done: bool = false
var _last_char: int = 0
var _accel: bool = false
var _cool: bool = true

#github 37720
var _line_size: int = 1
var _max_lines: int = 1
#end hacks
onready var _tween: Tween = Tween.new()
onready var _old_theme: Theme = theme
onready var _cooldown: Timer = Timer.new()

# none of the functions here return anything,
# so I didn't bother with return typing

### main loop ###
func _init():
	scroll_active = false

func _ready():
	if Engine.editor_hint:
		return
	
	add_child(_tween)
	add_child(_cooldown)
	
	_tween.connect("tween_all_completed", self, "_on_done")
	_tween.connect("tween_started", self, "_on_start")
	_cooldown.connect("timeout", self, "_on_cool")
	connect("resized", self, "_resized")
	
	_cooldown.wait_time = .1
	bbcode_enabled = true
	scroll_active = false
	scroll_following = false
	
	var sbb = speedbb.new()
	sbb.caller = self
	install_effect(sbb)
	
	_resized()
	_isready = true
	
	_start_msg()

func _unhandled_input(event):
	if InputMap.has_action(skip_action) and event.is_action_pressed(skip_action):
		if !_done and _cool:
			if speed >= 0:
				_tween.seek(_tween.get_runtime() * _tween.playback_speed)
			else:
				_tween.seek(0)
			get_tree().set_input_as_handled()
	
	elif InputMap.has_action(accelerate_action) and event.is_action_pressed(accelerate_action):
		_accel = true
		_tween.playback_speed = speed * _speed_mult * acceleration
		get_tree().set_input_as_handled()
	
	elif InputMap.has_action(accelerate_action) and event.is_action_released(accelerate_action):
		_accel = false
		_tween.playback_speed = speed * _speed_mult
		get_tree().set_input_as_handled()

func _process(delta):
	if Engine.editor_hint:
		return
	
	# recalculate sizing when theme is changed
	if theme != _old_theme:
		_old_theme = theme
		_resized()
	
	# scroll up or down to show current text
	if get_visible_line_count() > _max_lines and visible_characters > 0 and speed > 0:
		_scroll(3)
	if get_visible_line_count() <= _max_lines and visible_characters > 0 and speed < 0:
		_scroll(-3)
	
	# inline speed multiplier change
	if _speed_mult != _last_speed:
		_last_speed = _speed_mult
		_tween.playback_speed = _speed_mult * speed

### Setgets ###
func _set_speed(val: float):
	speed = float(val)
	
	if _tween == null:
		return
	
	if val != 0:
		_tween.playback_speed = _speed_mult * speed
	else:
		_tween.stop_all()
		percent_visible = 1.0
		_on_done()

func _set_accel(val: float):
	if val <= 0:
		return
	
	acceleration = float(val)
	if _accel and _tween != null:
		_tween.playback_speed = _speed_mult * speed * acceleration

### signal callbacks ###
func _on_start(obj, key):
	emit_signal("message_start",[obj,key])
	
func _on_done():
	_done = true
	emit_signal("message_done")

func _on_cool():
	_cool = true

func _resized():
	_line_size = get_font("normal_font").get_height() + get_constant("line_separation")
	_max_lines = int(get_rect().size.y / _line_size) - 1

### other ###
func send_message(val: String , append : bool = false):
	if append : 
		var _start_value = get_bbcode().length()
		append_bbcode (" " + val)
		if _isready:
			_start_msg(_start_value)
		return
	set_bbcode(val)
	if _isready:
		_start_msg()

func _scroll(v: float):
	get_v_scroll().value += v

func _block_speed(val: float):
	if val > 0:
		_speed_mult = val

func _start_msg (start_tween : int = 0):
	_speed_mult = 1
	_last_speed = 1
	_cool = false
	_cooldown.start()
	if _tween.is_active():
		_tween.remove_all()
	
	if speed != 0:
		_tween.playback_speed = speed
		_done = false
		_tween.interpolate_property(self, "visible_characters", start_tween, text.length(), text.length() - start_tween)
		_tween.start()
		yield (_tween, "tween_completed")
		_on_done()
	else:
		percent_visible = 1.0
		_on_done()

class speedbb extends RichTextEffect:
	var bbcode: String = "spd"
	var caller: Node = null
	
	func _process_custom_fx(char_fx) :
		if Engine.editor_hint:
			return true
		
		# main loop
		if char_fx.visible and caller != null and char_fx.env.has(""):
			# first char of speed sequence
			if char_fx.relative_index == 0 and (
					(caller.speed >= 0 and caller.percent_visible < 1.0)
					 or caller.speed < 0):
				
				caller._block_speed(char_fx.env[""])
				
			# last char of speed sequence
			if char_fx.env.get("_ct", -1) == char_fx.relative_index:
				caller._block_speed(1)

		# character counting, so it knows where to start and stop the speed
		char_fx.env["_ct"] = max(char_fx.relative_index, char_fx.env.get("_ct", 0))
		return true
