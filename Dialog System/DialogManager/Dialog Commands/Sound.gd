extends Command

class_name sound_command

var type : String = "sound_command"

enum  MixTarget {MIX_TARGET_STEREO,MIX_TARGET_SURROUND,MIX_TARGET_CENTER}

export var stream : AudioStream
export (float,-80,24) var volume_db : float = 0.0
export (float,0.01,4) var pitch_scale : float = 1
export (MixTarget) var mix_target = 0
export var bus : String = "Master"
export var effect : AudioEffect

