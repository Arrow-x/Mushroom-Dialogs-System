tool
extends Command
class_name sound_command

var type: String = "sound_command"

export var stream: AudioStream
export(float, -80, 24) var volume_db: float = 0.0
export(float, 0.01, 4) var pitch_scale: float = 1
export var mix_target = 0
export var bus: String = "Master"
export var effect: AudioEffect


func preview() -> String:
	return String("Play Sound: " + stream.resource_path.get_file())


func get_icon() -> Resource:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/say_icon.png")
