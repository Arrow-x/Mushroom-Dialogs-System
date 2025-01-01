extends RichTextEffect
class_name SpeedBB

var bbcode := "spd"

var caller: RichTextLabel


func _process_custom_fx(fx: CharFXTransform) -> bool:
	if fx.visible and caller != null and fx.env.has("a"):
		if fx.relative_index == 0 and caller.visible_ratio < 1.0:
			caller.set_speed(fx.env["a"])
	return true
