extends Node

@export var UI_pc: PackedScene  #A Default UI sceen Is required

@onready var indexer: int = 0
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var current_flowchart: FlowChart
var current_block: Block
var current_choices: Array
var UI: Control
var is_ON: bool
var cbi

var audio_skip: bool = false


#This is for Debug perpesos but a button to skip the dialog is needed
func _input(event):
	if event.is_action_pressed("ui_accept") and is_ON:
		advance()


func execute_dialog() -> void:
	if current_block == null:
		push_error("Dialog Manager: No block has been added")
		end_dialog()
		return

	#Needed for the The Conditional Command to work
	if indexer >= current_block.commands.size() or current_block.rand_times == 0:
		if current_block._next_block != null:
			var temp_block = current_block
			current_block = temp_block._next_block
			indexer = temp_block._next_indexer
			advance()
			return
		end_dialog()
		return

	cbi = current_block.commands[indexer]

	if cbi == null:
		push_error("Dialog Manager: this command in the block is empty")
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
				get_placeholders(cbi.say, cbi),
				cbi.character.name if cbi.character != null else "",
				cbi.append_text
			)
			UI.add_portrait(cbi.portrait, cbi.por_pos)
			UI.show_say()
			indexer = indexer + 1
			if cbi.follow_through == true:
				await UI.say_text.message_done
				advance()

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
				UI.add_choice(get_placeholders(ci.text), choice_idx, ci.next_index)
			UI.show_choice()

		"JumpCommand":
			if cbi.global:
				current_block = cbi.jump_block
			indexer = cbi.jump_index
			advance()

		"ConditionCommand":
			if parse_conditionals(cbi.conditionals) == true:
				cbi.container_block._next_block = current_block
				cbi.container_block._next_indexer = indexer + 1
				indexer = 0
				current_block = cbi.container_block
				advance()
				return
			else:
				var cbi_plus = current_block.commands[indexer + 1]
				if current_block.commands.size() > indexer + 1:
					if cbi_plus is ElseCommand:
						cbi_plus.container_block._next_block = current_block
						cbi_plus.container_block._next_indexer = indexer + 2
						indexer = 0
						current_block = cbi_plus.container_block
						advance()
						return
					elif cbi_plus is IfElseCommand:
						if parse_conditionals(cbi_plus.conditionals) == true:
							cbi_plus.container_block._next_block = current_block
							cbi_plus.container_block._next_indexer = indexer + 2
							indexer = 0
							current_block = cbi_plus.container_block
							advance()
							return
			indexer = indexer + 1
			advance()

		"ElseCommand", "IfElseCommand":
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
			if cbi.var_path == "self":
				current_flowchart.local_vars[cbi.var_name] = cbi.var_value
			elif cbi.var_path.is_rel_path():
				var req_node_path := NodePath(cbi.var_path.insert(0, "/root/"))
				get_node(req_node_path).set(cbi.var_name, cbi.var_value)
			else:
				push_error("NodePath in change var command is not valid")
			indexer = indexer + 1
			advance()

		"ChangeUICommand":
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

		"CallFunctionCommand":
			get_node(cbi.req_node.insert(0, "/root/")).callv(cbi.func_name, cbi.parsed_args)
			indexer = indexer + 1
			advance()

		"SignalCommand":
			var _args: Array = cbi.singal_args_parsed.duplicate()
			if _args.insert(0, cbi.signal_name) == OK:
				get_node(cbi.req_node.insert(0, "/root/")).callv("emit_signal", _args)
			indexer = indexer + 1
			advance()

		"GeneralContainerCommand":
			cbi.container_block._next_block = current_block
			cbi.container_block._next_indexer = indexer + 1
			indexer = 0
			current_block = cbi.container_block
			advance()

		"RandomCommand":
			cbi.container_block._next_block = current_block
			cbi.container_block._next_indexer = indexer + 1
			current_block = cbi.container_block
			current_block.rand_times = 2
			randomize()
			indexer = randi_range(0, cbi.container_block.commands.size() - 1)
			advance()

		_:
			push_error("Dialog Manager: Unknown Command ", cbi.get_class())
			return


func get_placeholders(input: String, cmd: Command = null) -> String:
	var regex := RegEx.new()
	regex.compile(r"{(.*?)}")
	var regex_resault := regex.search_all(input)
	var resault_array := []
	if regex_resault:
		for r in regex_resault:
			resault_array.append(r.get_string(1))
	var format_dictionary: Dictionary = {}
	for res: String in resault_array:
		if res.begins_with("F|"):
			var raw_call := res.erase(0, 2)
			var split = raw_call.split(".")
			regex.compile(r"\((.*)\)")
			var just_call := raw_call.erase(0, split[0].length() + 1)
			var res_call := regex.search(just_call).get_string(1)
			if res_call and cmd != null:
				format_dictionary[res] = str(
					get_node(split[0].insert(0, "/root/")).callv(
						just_call.left(just_call.find("(")), cmd.placeholder_args[res_call]
					)
				)
		elif res.contains("."):
			var split := res.split(".")
			if split.size() == 2:
				var val_node
				if split[0] == "self":
					val_node = current_flowchart.local_vars
				else:
					val_node = get_node(split[0].insert(0, "/root/"))

				var val_container = val_node.get(res.erase(0, split[0].length() + 1))

				if val_container:
					format_dictionary[res] = val_container
		elif res.begins_with("R|"):
			var rand := res.erase(0, 2).split("|")
			randomize()
			format_dictionary[res] = rand[randi_range(0, rand.size() - 1)]

	return input.format(format_dictionary)


func parse_conditionals(conditionals: Array[ConditionResource]) -> bool:
	for c_idx in conditionals.size():
		var resault := calc_var(
			conditionals[c_idx].required_node,
			conditionals[c_idx].required_var,
			conditionals[c_idx].is_property,
			conditionals[c_idx].parsed_args,
			conditionals[c_idx].parsed_check_val,
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


func calc_var(
	req_node: String,
	req_var_or_func: String,
	is_prop: bool,
	args: Array,
	chek_val: Array,
	type_cond: String
) -> bool:
	var val_node
	if req_node == "self":
		val_node = current_flowchart.local_vars
	else:
		val_node = get_node(req_node.insert(0, "/root/"))

	var val_container
	if is_prop == true:
		val_container = val_node.get(req_var_or_func)
	else:
		if val_node.has_method(req_var_or_func):
			val_container = val_node.call(req_var_or_func, args)

	if val_container == null:
		push_error("calc_var couldn't get the node")
		return false

	var typed_check_val = chek_val if chek_val.size() > 1 else chek_val[0]

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
		_:
			return false

	return false


func _on_make_choice(id: int, index: int) -> void:
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

	if current_block.rand_times != -1:
		current_block.rand_times -= 1

	execute_dialog()
