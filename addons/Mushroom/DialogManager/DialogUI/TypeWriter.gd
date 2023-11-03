extends RichTextLabel

@export_range(0, 1000) var speed: int = 50

@onready var tween: Tween = create_tween()

signal message_done
signal message_start


func _ready():
	var sbb := SpeedBB.new()
	sbb.caller = self
	install_effect(sbb)
	tween.finished.connect(tween_done)


func send_message(new_text: String, append: bool) -> void:
	message_start.emit()
	if append:
		append_text(new_text)
	else:
		text = new_text

	tween.set_speed_scale(speed)
	tween.tween_property(self, "visible_ratio", 1.0, get_total_character_count() / 2)


func set_speed(val: float) -> void:
	tween.set_speed_scale(val)


func skip_tween() -> void:
	tween.stop()
	visible_ratio = 1.0
	message_done.emit()


func tween_done() -> void:
	message_done.emit()
