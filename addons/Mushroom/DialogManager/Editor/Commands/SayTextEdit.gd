@tool
extends TextEdit


func _make_custom_tooltip(for_text: String) -> Object:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.shortcut_keys_enabled = false
	t.scroll_active = false
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.threaded = true
	t.append_text(for_text)
	return t
