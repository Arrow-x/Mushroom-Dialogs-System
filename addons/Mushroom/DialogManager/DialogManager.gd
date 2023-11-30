extends Node

@export var UI_pc: PackedScene  #A Default UI sceen Is required

@onready var indexer: int = 0
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var current_flowchart: FlowChart
var current_block: Block
var current_choices: Array
var UI
var is_ON: bool
var cbi

var _skipped: bool = false


#This is for Debug perpesos but a button to skip the dialog is needed
func _input(event):
	if event.is_action_pressed("ui_accept") and is_ON:
		advance()


func execute_dialog() -> void:
	if current_block == null:
		#print("Error: No block has been added")
		end_dialog()
		return

	#Needed for the The Conditional Command to work
	if indexer >= current_block.commands.size():
		if current_block._next_block != null:
			var temp_block = current_block
			current_block = temp_block._next_block
			indexer = temp_block._next_indexer
			advance()
			return
		#print("Alert: the block have ended")
		end_dialog()
		return

	cbi = current_block.commands[indexer]  #for eas of typing

	if cbi == null:
		#print("Error: this command in the block is empty")
		indexer = indexer + 1
		advance()
		return

	match cbi.get_class():
		"SayCommand":
			UI.hide_say()
			if cbi.is_cond:
				if parse_conditionals(cbi.conditionals) == false:
					indexer = indexer + 1
					advance()
					return
			UI.add_text(
				cbi.say, cbi.character.name if cbi.character != null else "", cbi.append_text
			)
			UI.add_portrait(cbi.portrait, cbi.por_pos)
			UI.show_say()
			indexer = indexer + 1

		"ForkCommand":
			UI.hide_say()
			UI.hide_choice()
			current_choices.clear()
			for choice_idx in cbi.choices.size():
				var ci: Choice = cbi.choices[choice_idx]
				if ci.is_cond:
					if parse_conditionals(ci.conditionals) == false:
						continue
				current_choices.append(current_flowchart.get_block(ci.next_block))
				UI.add_choice(ci, choice_idx, ci.next_index)
			UI.show_choice()

		"JumpCommand":
			if cbi.global:
				current_block = cbi.jump_block
			indexer = cbi.jump_index
			advance()

		"ConditionCommand":
			if parse_conditionals(cbi.conditionals) == false:
				cbi.condition_block._next_block = current_block
				cbi.condition_block._next_indexer = indexer + 1
				indexer = 0
				current_block = cbi.condition_block
				advance()
				return
			indexer = indexer + 1
			advance()

		"AnimationCommand":
			var a := get_node(cbi.animation_path)
			a.play(cbi.animation_name, cbi.custom_blend, cbi.custom_speed, cbi.from_end)
			if cbi.is_wait == true:
				await a.animation_finished == cbi.animation_name
			indexer = indexer + 1
			advance()

		"SetVarCommand":
			if cbi.var_path.is_rel_path():
				var req_node_path := NodePath(cbi.var_path.insert(0, "/root/"))
				get_node(req_node_path).set(cbi.var_name, cbi.var_value)
			else:
				push_error("NodePath in change var command is not valid")
			indexer = indexer + 1
			advance()

		"ChangeUICommand":  #To Debug
			if cbi.change_to_default == true:
				UI.queue_free()
				UI = UI_pc.instantiate()
				add_child(UI)
				indexer = indexer + 1
				advance()
				return
			UI.queue_free()
			UI = cbi.next_UI.instantiate()
			add_child(UI)
			indexer = indexer + 1
			advance()

		"SoundCommand":
			if cbi.stream != null:
				audio_player.stop()
				audio_player.set_stream(cbi.stream)
				audio_player.set_volume_db(cbi.volume_db)
				audio_player.set_pitch_scale(cbi.pitch_scale)
				audio_player.set_mix_target(cbi.mix_target)
				audio_player.set_bus(cbi.bus)
				if cbi.effect != null:
					AudioServer.add_bus_effect(AudioServer.get_bus_index(cbi.bus), cbi.effect)
				_skipped = false
				audio_player.play()
				await audio_player.finished

			if _skipped == false:
				indexer = indexer + 1
				advance()


func parse_conditionals(conditionals: Array[ConditionResource]) -> bool:
	for c_idx in conditionals.size():
		var resault := calc_var(
			conditionals[c_idx].required_node,
			conditionals[c_idx].required_var,
			conditionals[c_idx].is_property,
			conditionals[c_idx].args,
			conditionals[c_idx].check_val,
			conditionals[c_idx].condition_type
		)
		if c_idx + 1 > conditionals.size() - 1:
			return resault
		if resault == true:
			if conditionals[c_idx + 1].is_and == true:
				continue
			else:
				return true
		elif resault == false:
			if conditionals[c_idx + 1].is_and == false:
				continue
			else:
				return false
	return false


func get_type_from_string(value: String):
	# TODO: parse Array, Vector and Dictionary
	# TODO: make the last default type
	var typed_value
	if value.is_valid_int():
		typed_value = value.to_int() as int
	elif value.is_valid_float():
		typed_value = value.to_float() as float
	elif value.to_lower() == "true":
		typed_value = true as bool
	elif value.to_lower() == "false":
		typed_value = false as bool
	elif value.begins_with('"') or value.begins_with("'"):
		if value.ends_with('"') or value.ends_with("'"):
			var first := value.erase(0, 1)
			typed_value = first.erase(first.length() - 1, 1) as String
	return typed_value


func calc_var(
	req_node: String,
	req_var_or_func: String,
	is_prop: bool,
	args: String,
	chek_val: String,
	type_cond: String
) -> bool:
	var val_node = get_node(req_node.insert(0, "/root/"))
	var val_container
	if is_prop == true:
		val_container = val_node.get(req_var_or_func)
	else:
		if val_node.has_method(req_var_or_func):
			val_container = val_node.call(req_var_or_func, get_type_from_string(args))

	if val_container == null:
		push_error("calc_var couldn't get the node")
		return false

	var typed_check_val = get_type_from_string(chek_val)

	match type_cond:
		">=":
			if typed_check_val >= val_container:
				return true

		"<=":
			if typed_check_val <= val_container:
				return true

		">":
			if typed_check_val > val_container:
				return true

		"<":
			if typed_check_val < val_container:
				return true

		"==":
			if typed_check_val == val_container:
				return true

		"!=":
			if typed_check_val != val_container:
				return true

	return false


func _on_make_choice(id: int, index) -> void:
	current_block = current_choices[id]
	indexer = index
	UI.hide_choice()
	execute_dialog()


func send_flowchart(dblock: FlowChart) -> void:
	if !is_ON:
		current_block = dblock.first_block
		current_flowchart = dblock
		indexer = 0
		UI = UI_pc.instantiate()
		add_child(UI)
		is_ON = true
		execute_dialog()
	#print("The Dialog Mangaer Is running")


func end_dialog() -> void:
	indexer = 0
	current_block = null
	current_choices.clear()
	UI.hide_say()
	UI.hide_choice()
	UI.queue_free()
	is_ON = false


func advance() -> void:
	if is_ON == false:
		return

	if UI.is_tweening:
		UI.say_text.skip_tween()
		UI.is_tweening = false
		return

	if audio_player.playing and !_skipped and not UI.is_tweening:  #To DEBUG
		audio_player.stop()
		_skipped = true
		indexer = indexer + 1

	if not UI.is_tweening and not audio_player.playing:
		execute_dialog()
