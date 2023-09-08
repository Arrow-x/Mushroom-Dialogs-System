tool
extends Control

var current_sound: sound_command

onready var stream = $StremHBoxContainer/Stream
onready var volume_slider = $VoilumHBoxContainer2/Volume
onready var pitch_slider = $PitchHBoxContainer/Pitch
onready var mix_menu = $MixHBoxContainer/MixMenuButton
onready var bus_lineedit = $BusHBoxContainer/BusLineEdit
onready var effect = $EffectHBoxContainer/Effect


func set_up(cmd: sound_command) -> void:
	current_sound = cmd
	stream.text = (
		current_sound.stream.resource_path.get_file()
		if current_sound.stream != null
		else "Drag an AudioStream!"
	)
	volume_slider.value = current_sound.volume_db
	pitch_slider.value = current_sound.pitch_scale
	bus_lineedit.text = current_sound.bus
	effect.text = (
		current_sound.effect.resource_path.get_file()
		if current_sound.effect != null
		else "Drag an AudioEffect!"
	)
	var mix_menu_pop: Popup = mix_menu.get_popup()
	if !mix_menu_pop.is_connected("id_pressed", self, "_on_MixMenu_id_pressed"):
		mix_menu_pop.connect("id_pressed", self, "_on_MixMenu_id_pressed", [mix_menu_pop])
	mix_menu.text = mix_menu_pop.get_item_text(current_sound.mix_target)


func _on_Stream_value_dragged(data) -> void:
	current_sound.stream = data
	stream.text = data.resource_path.get_file()
	is_changed()


func _on_Volume_value_changed(value: float) -> void:
	current_sound.volume_db = value
	is_changed()


func _on_Pitch_value_changed(value: float) -> void:
	current_sound.pitch_scale = value
	is_changed()


func _on_Effect_value_dragged(data) -> void:
	current_sound.effect = data
	effect.text = data.resource_path.get_file()
	is_changed()


func _on_BusLineEdit_text_changed(new_text: String) -> void:
	current_sound.bus = new_text
	is_changed()


func _on_MixMenu_id_pressed(id: int, mix_menu_pop: Popup) -> void:
	current_sound.mix_target = id
	mix_menu.text = mix_menu_pop.get_item_text(id)
	is_changed()


func is_changed() -> void:
	current_sound.emit_signal("changed")


func get_command() -> Command:
	return current_sound
