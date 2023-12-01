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

var audio_skip: bool = false


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
				audio_player.play()
				if cbi.wait == true:
					audio_skip = true
					await audio_player.finished
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
	if value.is_valid_int():
		return value.to_int()
	elif value.is_valid_float():
		return value.to_float()
	elif value.to_lower() == "true":
		return true
	elif value.to_lower() == "false":
		return false
	elif value.begins_with("(") and value.ends_with(")"):
		var first := value.erase(0, 1)
		value = first.erase(first.length() - 1, 1) as String
		var value_split := value.split(",")
		match value_split.size():
			2:
				return Vector2(value_split[0].to_float(), value_split[1].to_float())
			3:
				return Vector3(
					value_split[0].to_float(), value_split[1].to_float(), value_split[2].to_float()
				)
			4:
				return Vector4(
					value_split[0].to_float(),
					value_split[1].to_float(),
					value_split[2].to_float(),
					value_split[3].to_float()
				)
	elif value.begins_with("i(") and value.ends_with(")"):
		var first := value.erase(0, 2)
		value = first.erase(first.length() - 1, 1)
		var value_split := value.split(",")
		match value_split.size():
			2:
				return Vector2i(value_split[0].to_int(), value_split[1].to_float())
			3:
				return Vector3i(
					value_split[0].to_int(), value_split[1].to_float(), value_split[2].to_float()
				)
			4:
				return Vector4i(
					value_split[0].to_int(),
					value_split[1].to_int(),
					value_split[2].to_int(),
					value_split[3].to_int()
				)
	elif value.begins_with("[") and value.ends_with("]"):
		var first := value.erase(0, 1)
		value = first.erase(first.length() - 1, 1)
		var value_split := structure_string(value)	
		var typed_value := []
		for v in value_split:
			typed_value.append(get_type_from_string(v))
		return typed_value
	elif value.begins_with("{") and value.ends_with("}"):
		#TODO: make the Dictionary parser
		var first := value.erase(0, 1)
		value = first.erase(first.length() - 1, 1)
		var value_split := value.split(",")

	return value


func structure_string(input: String) -> Array:
	var regexs := [r"\,? ?(i?\(.*?\))", r"\,? ?(i?\[.*?\])", r"\,? ?(i?\{.*?\})"]
	var resault := []
	var string := input

	for r: String in regexs:
		if string == "":
			break
		var _resault_left := search_and_delete(string, r)
		resault.append_array(_resault_left[0])
		if _resault_left[1] != "":
			string = _resault_left[1]
	if string != "":
		var raw_splits := string.split(",")
		var splits := []
		for s in raw_splits:
			splits.append(s.dedent())
		resault.append_array(splits)
	return resault

func search_and_delete(input: String, in_regex: String) -> Array:
	var regex := RegEx.new()
	regex.compile(in_regex)
	var regex_resault := regex.search_all(input)
	var resault_array := []
	var left := ""
	if regex_resault != []:
		for r in regex_resault:
			resault_array.append(r.get_string(1))
		left = regex.sub(input, "", true)

	return [resault_array, left]


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

	if audio_player.playing and audio_skip == true:
		audio_player.stop()
		audio_player.finished.emit()
		audio_skip = false
		return

	execute_dialog()
