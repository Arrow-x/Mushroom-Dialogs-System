extends RichTextLabel

export var speed : int = 1

var _isready : bool
var _speed_mult
var _last_speed
var _done
var _error

onready var _tween: Tween = Tween.new()

signal message_done

func _ready():
    add_child(_tween)
    _tween.playback_speed = speed

func _process(delta):
    if _speed_mult != _last_speed:
        _last_speed = _speed_mult
        _tween.playback_speed = _speed_mult * speed
        
    _error = delta
func send_message(val: String , append : bool = false):
    if append : 
        var _start_value = get_bbcode().length()
        _error = append_bbcode (" " + val)
        if _isready:
            _start_msg(_start_value)
        return

    set_bbcode(val)
    if _isready:
        _start_msg()

func _start_msg (start_tween : int = 0):
    _speed_mult = 1
    _last_speed = 1

    if _tween.is_active():
        _error = _tween.remove_all()
	
    if speed != 0:
        _tween.playback_speed = speed
        _done = false
        _error = _tween.interpolate_property(self, "visible_characters", start_tween, text.length(), text.length() - start_tween)
        _error = _tween.start()
        yield (_tween, "tween_completed")
        _on_done()
    else:
        percent_visible = 1.0
        _on_done()
        
func _on_done():
    _done = true
    emit_signal("message_done")

func skip_tween():
    _error = _tween.stop(self, "visible_characters")
    visible_characters = -1