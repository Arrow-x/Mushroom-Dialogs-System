@tool
extends Node

@export var stream: Label
@export var volume_slider: SpinBox
@export var pitch_slider: SpinBox
@export var mix_menu: MenuButton
@export var bus_lineedit: LineEdit
@export var effect: Label
@export var wait_check: CheckButton

var current_sound: SoundCommand
var undo_redo: EditorUndoRedoManager
var commands_tree: Tree
var default_stream_text := "..."
var default_effect_text := "..."


func set_up(cmd: SoundCommand, u_r: EditorUndoRedoManager, cmd_tree: Tree) -> void:
	current_sound = cmd
	undo_redo = u_r
	commands_tree = cmd_tree
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
	if !mix_menu_pop.id_pressed.is_connected(_on_mix_menu_id_pressed):
		mix_menu_pop.id_pressed.connect(_on_mix_menu_id_pressed.bind(mix_menu_pop))
	mix_menu.text = mix_menu_pop.get_item_text(current_sound.mix_target)
	toggle_wait(cmd.wait)


func _on_clean_stream_pressed() -> void:
	undo_redo.create_action("clear stream")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "add_stream", [null])
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "add_stream", [current_sound.stream]
	)
	undo_redo.commit_action()


func _on_stream_value_dragged(data: AudioStream) -> void:
	undo_redo.create_action("drag in stream")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "add_stream", [data])
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "add_stream", [current_sound.stream]
	)
	undo_redo.commit_action()


func add_stream(data: AudioStream = null) -> void:
	current_sound.stream = data
	if data != null:
		stream.text = data.resource_path.get_file()
	else:
		stream.text = default_stream_text
	is_changed()


func _on_volume_value_changed(value: float) -> void:
	current_sound.volume_db = value
	is_changed()


func _on_pitch_value_changed(value: float) -> void:
	current_sound.pitch_scale = value
	is_changed()


func _on_clean_effect_pressed() -> void:
	undo_redo.create_action("clear effect")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "add_effect")
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "add_effect", [current_sound.effect]
	)
	undo_redo.commit_action()


func _on_effect_value_dragged(data: AudioEffect) -> void:
	undo_redo.create_action("drag in effect")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "add_effect", [data])
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "add_effect", [current_sound.effect]
	)
	undo_redo.commit_action()


func add_effect(data: AudioEffect = null) -> void:
	current_sound.effect = data
	if data != null:
		effect.text = data.resource_path.get_file()
	else:
		effect.text = default_effect_text
	is_changed()


func _on_bus_line_edit_text_changed(new_text: String) -> void:
	current_sound.bus = new_text
	is_changed()


func _on_mix_menu_id_pressed(id: int, mix_menu_pop: Popup) -> void:
	var next_mix_menu_text: String = mix_menu_pop.get_item_text(id)
	var prev_mix_menu_text: String = mix_menu_pop.get_item_text(current_sound.mix_target)
	undo_redo.create_action("select mix target")
	undo_redo.add_do_method(
		commands_tree, "command_undo_redo_caller", "select_mix", [id, next_mix_menu_text]
	)
	undo_redo.add_undo_method(
		commands_tree,
		"command_undo_redo_caller",
		"select_mix",
		[current_sound.mix_target, prev_mix_menu_text]
	)
	undo_redo.commit_action()


func _on_wait_check_toggled(toggled_on: bool) -> void:
	undo_redo.create_action("toggle wait")
	undo_redo.add_do_method(commands_tree, "command_undo_redo_caller", "toggle_wait", [toggled_on])
	undo_redo.add_undo_method(
		commands_tree, "command_undo_redo_caller", "toggle_wait", [current_sound.wait]
	)
	undo_redo.commit_action()


func toggle_wait(toggle: bool) -> void:
	wait_check.set_pressed_no_signal(toggle)
	current_sound.wait = toggle
	if toggle == true:
		wait_check.text = "Wait"
	if toggle == false:
		wait_check.text = "Continue"
	is_changed()


func select_mix(id: int, mix_menu_text: String) -> void:
	current_sound.mix_target = id
	mix_menu.text = mix_menu_text
	is_changed()


func get_command() -> Command:
	return current_sound


func is_changed() -> void:
	current_sound.changed.emit(current_sound)
