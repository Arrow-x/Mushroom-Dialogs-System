extends Node

export (PackedScene) var UI_pc : PackedScene #A Default UI sceen Is required

onready var indexer : int = 0
onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

var current_flowchart #The whole flowchart thing is unnessery unitil we make an editor
var current_block : block
var current_choices : Array
var UI 
var is_ON : bool = false
var cbi : Command
var debug

var _skipped : bool = false

#Add and Emit signals for one the system starts, end, and steps through
#Add End Dialog Command
#Add Tween Dialogs
#Add Voice acting Support to Say Command

#This is for Debug perpesos but a button to skip the dialog is needed
func _input(event):
	if event.is_action_pressed("ui_accept") and is_ON:
		advance()

func execute_dialog() -> void:
	is_ON = true
	if current_block == null:
		#print("Error: No block has been added")
		end_dialog()
		return

	#Needed for the The Conditional Command to work	
	if indexer >= current_block.commands.size():
		if current_block._next_block != null :
			var temp_block = current_block
			current_block = temp_block._next_block
			indexer = temp_block._next_indexer
			advance()
			return
		#print("Alert: the block have ended")
		end_dialog()
		return

	cbi = current_block.commands[indexer] #for eas of typing

	if cbi == null:
		#print("Error: this command in the block is empty")
		indexer = indexer + 1
		advance()
		return

	match cbi.type:
		#to add: Better Portraits support
		"say": #ToDebug
			UI.hide_say()
			UI.add_text(cbi.say, cbi.name, cbi.append_text)
			UI.add_portrait(cbi.portrait, cbi.por_pos)
			UI.show_say()
			UI.show_next_button()
			indexer = indexer+1

		"cond_say":
			if calc_var(cbi.required_node, cbi.required_var, cbi.check_val, cbi.condition_type) == true:
				UI.hide_say()
				UI.add_text(cbi.say, cbi.name, cbi.append_text)
				UI.add_portrait(cbi.portrait, cbi.por_pos)
				UI.show_say()
				UI.show_next_button()
				indexer = indexer+1
				return
			indexer = indexer + 1
			advance()	

		"fork":
			#UI.hide_say()
			UI.hide_choice()
			UI.hide_next_button()
			#UI.hide_portriats()
			current_choices.clear()
			for i in cbi.choices.size():
				if cbi.type == "cond_choice":
					if calc_var(cbi.required_node, cbi.required_var, cbi.check_val, cbi.condition_type) == true:
						current_choices.append(null)
						continue
				current_choices.append(cbi.choices[i].next_block)
				UI.add_choice_button(cbi.choices[i], i, cbi.choices[i].next_index)
			UI.show_choice()	

		"jump":  #TO DEBUG
			current_block = cbi.jump_block
			indexer = cbi.jump_index
			advance()

		"condition":
			if calc_var(cbi.required_node, cbi.required_var, cbi.check_val, cbi.condition_type) == true:
				cbi.condition_block._next_block = current_block
				cbi.condition_block._next_indexer = indexer + 1
				indexer = 0
				current_block = cbi.condition_block
				advance()
				return
			indexer = indexer + 1
			advance()

		"animation":
			var a = get_node(cbi.animation_path)
			a.play (cbi.animation_name, cbi.custom_blend, cbi.custom_speed, cbi.from_end)
			match cbi.anim_type:
				"wait":
					while yield (get_node(cbi.animation_path),"animation_finished") != cbi.animation_name:
						pass
					indexer = indexer+1
					advance()
				"continue":
					indexer = indexer+1
					advance()

		"set_var": #TO DEBUG 
			var req_node_string : String = String(cbi.var_path)
			if req_node_string.is_rel_path():
				req_node_string = req_node_string.insert(0,"/root/")
				cbi.var_path = NodePath(req_node_string)
			get_node(cbi.var_path).set(cbi.var_name, cbi.var_value)
			indexer = indexer+1
			advance() 

		"change_ui": #To Debug
			if cbi.change_to_default == true:
				UI.queue_free()
				UI = UI_pc.instance()
				add_child(UI)
				indexer = indexer+1
				advance()
				return
			UI.queue_free()
			UI = cbi.next_UI.instance()
			add_child(UI)
			indexer = indexer+1
			advance()

		"sound_command": 
			if cbi.stream != null : 
				audio_player.stop()
				audio_player.set_stream (cbi.stream)
				audio_player.set_volume_db (cbi.volume_db)
				audio_player.set_pitch_scale (cbi.pitch_scale)
				audio_player.set_mix_target (cbi.mix_target)
				audio_player.set_bus(cbi.bus)
				if cbi.effect != null:
					AudioServer.add_bus_effect (AudioServer.get_bus_index(cbi.bus),cbi.effect)
				_skipped = false
				audio_player.play()
				yield (audio_player, "finished") 

			if _skipped == false: 
				indexer = indexer+1
				advance ()

func calc_var(req_node: NodePath, req_var : String, chek_val : int, type_cond: String) -> bool:
	
	var req_node_string : String = String(req_node)
	
	if req_node_string.is_rel_path():
		req_node_string = req_node_string.insert(0,"/root/")
		req_node = NodePath(req_node_string)

	var req_val = get_node(req_node).get(req_var)
	
	match type_cond:
		">=":
			if chek_val >= req_val:
				return true

		"<=":
			if chek_val <= req_val:
				return true

		">":
			if chek_val > req_val:
				return true

		"<":
			if chek_val < req_val:
				return true

		"==":
			if chek_val == req_val:
				return true

		"!=":
			if chek_val != req_val:
				return true

	return false

func _on_make_choice(id:int, index) -> void:
	current_block = current_choices[id]
	indexer = index
	UI.hide_choice()
	execute_dialog()

func send_dialog(dblock) -> void:
	if !is_ON :
		current_block = dblock
		indexer = 0
		UI = UI_pc.instance()
		add_child(UI)
		execute_dialog()
		is_ON = true
	#print("The Dialog Mangaer Is running")

func end_dialog() -> void:
	indexer = 0
	current_block = null
	current_choices.clear()
	UI.hide_say()
	UI.hide_choice()
	UI.queue_free()
	is_ON = false

func advance () -> void :
	if !is_ON : 
		return
	
	if UI.is_tweening: #UI.say_text.is_active()
		UI.say_text.skip_tween()
		UI.is_tweening = false
		return

	if audio_player.playing and !_skipped and not UI.is_tweening : #To DEBUG
		audio_player.stop()
		_skipped = true
		indexer = indexer+1
		
	if not UI.is_tweening and not audio_player.playing:
		execute_dialog()

