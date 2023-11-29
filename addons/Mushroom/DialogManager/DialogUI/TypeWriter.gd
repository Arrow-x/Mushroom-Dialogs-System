extends RichTextLabel

@export_range(0, 1000) var speed: int = 50

var tween: Tween

signal message_done
signal message_start


func send_message(new_text: String, append: bool) -> void:
	visible_ratio = 0
	var sbb := SpeedBB.new()
	sbb.caller = self
	install_effect(sbb)
	tween = create_tween()
	tween.finished.connect(tween_done)
	if append:
		append_text(new_text)
	else:
		text = new_text

	message_start.emit()
	tween.set_speed_scale(speed).tween_property(
		self, "visible_ratio", 1.0, get_total_character_count() / 2
	)


func set_speed(val: float) -> void:
	tween.set_speed_scale(val)


func skip_tween() -> void:
	tween.stop()
	visible_ratio = 1.0
	message_done.emit()


func tween_done() -> void:
	message_done.emit()
