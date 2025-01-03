@tool
extends Command
class_name SoundCommand

@export var stream: AudioStream
@export_range(-80, 24) var volume_db: float = 0.0
@export_range(0.01, 4) var pitch_scale: float = 1
@export_enum("Stereo", "Surround", "Center") var mix_target = 0
@export var bus: String = "Master"
@export var effect: AudioEffect
@export var wait: bool = false


func preview() -> String:
	var stream_name: String = stream.resource_path.get_file() if stream != null else "null"
	return str("Play Sound: " + stream_name)


static func get_icon() -> Texture2D:
	return load("res://addons/Mushroom/DialogManager/Editor/icons/musicOn.png")


func get_class() -> String:
	return "SoundCommand"


func is_class(c: String) -> bool:
	return c == "SoundCommand"
