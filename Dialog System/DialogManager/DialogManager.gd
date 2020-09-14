extends Node

export (PackedScene) var UI_pc : PackedScene #A Default UI sceen Is required

onready var indexer : int = 0

var current_flowchart #The whole flowchart thing is unnessery unitil we make an editor
var current_block : block
var current_choices : Array
var UI 
var is_ON : bool = false
var cbi 

#This is for Debug perpesos but a button to skip the dialog is needed
func _input(event):
	if event.is_action_pressed("ui_select"):
		UI.next_button.emit_signal("pressed")

func execute_dialog() -> void:
	if current_block == null:
		print("Error: No block has been added")
		end_dialog()
		return

	#Needed for the The Conditional Command to work	
	if indexer >= current_block.commands.size():
		if current_block._next_block != null :
			var temp_block = current_block
			current_block = temp_block._next_block
			indexer = temp_block._next_indexer
			UI.next_button.emit_signal("pressed")
			return
		print("Alert: the block have ended")
		end_dialog()
		return

	cbi = current_block.commands[indexer] #for eas of typing

	if cbi == null:
		print("Error: this command in the block is empty")
		indexer = indexer + 1
		UI.next_button.emit_signal("pressed")
		return

	match cbi.type:
		#to add: BBCode Support, Better Portraits support
		"say": #ToDebug
			if cbi.append_text == true:
				UI.add_text(cbi.say, cbi.name, cbi.append_text)
				indexer = indexer+1
				return
			UI.hide_say()
			UI.add_text(cbi.say, cbi.name)
			UI.add_portrait(cbi.portrait, cbi.por_pos)
			UI.show_say()
			indexer = indexer+1
			
		"cond_say":
			if calc_var(cbi.required_node, cbi.required_var, cbi.check_val, cbi.condition_type) == true:
				if cbi.append_text == true:
					UI.say_text += cbi.say
					indexer = indexer+1
					return
				UI.hide_say()
				UI.add_text(cbi.say, cbi.name)
				UI.add_portrait(cbi.portrait, cbi.por_pos)
				UI.show_say()
				indexer = indexer+1
				return
			indexer = indexer + 1
			UI.next_button.emit_signal("pressed")	

		"fork":
			UI.hide_say()
			UI.hide_choice()
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
			UI.next_button.emit_signal("pressed")

		"condition":
			if calc_var(cbi.required_node, cbi.required_var, cbi.check_val, cbi.condition_type) == true:
				cbi.condition_block._next_block = current_block
				cbi.condition_block._next_indexer = indexer + 1
				indexer = 0
				current_block = cbi.condition_block
				UI.next_button.emit_signal("pressed")
				return
			indexer = indexer + 1
			UI.next_button.emit_signal("pressed")

		"animation":
			var a = get_node(cbi.animation_path)
			a.play (cbi.animation_name, cbi.custom_blend, cbi.custom_speed, cbi.from_end)
			match cbi.anim_type:
				"wait":
					while yield (get_node(cbi.animation_path),"animation_finished") != cbi.animation_name:
						pass
					indexer = indexer+1
					UI.next_button.emit_signal("pressed")
				"continue":
					indexer = indexer+1
					UI.next_button.emit_signal("pressed")

		"set_var": #TO DEBUG 
			get_node(cbi.var_path).set(cbi.var_name, cbi.var_value)
			indexer = indexer+1
			UI.next_button.emit_signal("pressed")

		"Change UI": #To Debug
			if cbi.change_to_default == true:
				UI.queue_free()
				UI = UI_pc.instance()
				add_child(UI)
				indexer = indexer+1
				UI.next_button.emit_signal("pressed")
				return

			UI.queue_free()
			UI = cbi.next_UI.instance()
			add_child(UI)
			indexer = indexer+1
			UI.next_button.emit_signal("pressed")

func calc_var(req_node, req_var : String, chek_val : int, type_cond: String) -> bool:
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
	current_block = dblock
	indexer = 0
	UI = UI_pc.instance()
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
