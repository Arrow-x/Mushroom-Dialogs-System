tool
extends Control

var current_sound: sound_command
var undo_redo: UndoRedo
var current_effect: AudioEffect
var current_stream: AudioStream
var default_stream_text := "..."
var default_effect_text := "..."

onready var stream := $StremHBoxContainer/Stream
onready var volume_slider := $VoilumHBoxContainer2/Volume
onready var pitch_slider := $PitchHBoxContainer/Pitch
onready var mix_menu := $MixHBoxContainer/MixMenuButton
onready var bus_lineedit := $BusHBoxContainer/BusLineEdit
onready var effect := $EffectHBoxContainer/Effect


func set_up(cmd: sound_command, u_r: UndoRedo) -> void:
	current_sound = cmd
	undo_redo = u_r
	stream.text = (
		current_sound.stream.resource_path.get_file()
		if current_sound.stream != null
		else default_stream_text
	)
	volume_slider.value = current_sound.volume_db
	pitch_slider.value = current_sound.pitch_scale
	bus_lineedit.text = current_sound.bus
	effect.text = (
		current_sound.effect.resource_path.get_file()
		if current_sound.effect != null
		else default_effect_text
	)
	var mix_menu_pop: Popup = mix_menu.get_popup()
	if !mix_menu_pop.is_connected("id_pressed", self, "_on_MixMenu_id_pressed"):
		mix_menu_pop.connect("id_pressed", self, "_on_MixMenu_id_pressed", [mix_menu_pop])
	mix_menu.text = mix_menu_pop.get_item_text(current_sound.mix_target)


func _on_CleanStream_pressed() -> void:
	undo_redo.create_action("clear stream")
	undo_redo.add_do_method(self, "add_stream", null)
	undo_redo.add_undo_method(self, "add_stream", current_stream)
	undo_redo.commit_action()
	current_stream = null


func _on_Stream_value_dragged(data: AudioStream) -> void:
	undo_redo.create_action("drag in stream")
	undo_redo.add_do_method(self, "add_stream", data)
	undo_redo.add_undo_method(self, "add_stream", current_stream)
	undo_redo.commit_action()
	current_stream = data


func add_stream(data: AudioStream = null) -> void:
	current_sound.stream = data
	if data != null:
		stream.text = data.resource_path.get_file()
	else:
		stream.text = default_stream_text
	is_changed()


func _on_Volume_value_changed(value: float) -> void:
	current_sound.volume_db = value
	is_changed()


func _on_Pitch_value_changed(value: float) -> void:
	current_sound.pitch_scale = value
	is_changed()


func _on_CleanEffect_pressed() -> void:
	undo_redo.create_action("clear effect")
	undo_redo.add_do_method(self, "add_effect", null)
	undo_redo.add_undo_method(self, "add_effect", current_effect)
	undo_redo.commit_action()
	current_effect = null


func _on_Effect_value_dragged(data: AudioEffect) -> void:
	undo_redo.create_action("drag in effect")
	undo_redo.add_do_method(self, "add_effect", data)
	undo_redo.add_undo_method(self, "add_effect", current_effect)
	undo_redo.commit_action()
	current_effect = data


func add_effect(data: AudioEffect = null) -> void:
	current_sound.effect = data
	if data != null:
		effect.text = data.resource_path.get_file()
	else:
		effect.text = default_effect_text
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
