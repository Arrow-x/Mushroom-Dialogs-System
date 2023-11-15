extends RichTextEffect
class_name SpeedBB

var bbcode := "spd"

var caller: RichTextLabel

# HACK: don't end the tag just start another one to reset the speed manualy
# [/spd] will stop the effect since the CharFXTransform is loopng through it
# the relative_index doesn't count the characters hidden by the visible_ratio
# To fix another way to tween the visible characteres that allow CharFXTransform
# to draw and count


func _process_custom_fx(fx: CharFXTransform) -> bool:
	if fx.visible and caller != null and fx.env.has(""):
		if fx.relative_index == 0 and caller.visible_ratio < 1.0:
			caller.set_speed(fx.env[""])
	return true
