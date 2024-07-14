@tool
extends GraphNode

var c_inputs: Array
var c_outputs: Array

var connected_destenation_blocks: Array
var graph_edit: GraphEdit

enum Direction { LEFT, RIGHT }


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.double_click == true:
					graph_edit.on_graph_node_clicked(self)
			MOUSE_BUTTON_RIGHT:
				accept_event()
				righ_click_menu()


func _ready() -> void:
	dragged.connect(_on_graph_node_dragged)


func righ_click_menu():
	var pop := PopupMenu.new()
	pop.popup_hide.connect(func(): pop.queue_free())
	pop.index_pressed.connect(handle_right_click.bind(pop))
	pop.add_item("Copy")
	if not self.title == "first_block":
		pop.add_item("Cut")
		pop.add_item("Rename")
		pop.add_item("Delete")
	add_child(pop)
	var gmp := DisplayServer.mouse_get_position()
	pop.popup(Rect2(gmp.x, gmp.y, 0, 0))


func handle_right_click(idx: int, pop: PopupMenu) -> void:
	var state: String
	match pop.get_item_text(idx):
		"Copy":
			state = "Copy"
		"Cut":
			state = "Cut"
		"Delete":
			state = "Delete"
		"Rename":
			state = "Rename"
		_:
			push_error("GraphNode: Unknow option in right click menu")
			return
	graph_edit.handle_right_menu(state, position_offset, self)


func add_close_button() -> void:
	var button := Button.new()
	button.text = "x"
	button.flat = true
	get_titlebar_hbox().add_child(button)
	button.pressed.connect(_close_button_pressed)


func _close_button_pressed() -> void:
	graph_edit.selected_graph_nodes.clear()
	graph_edit._on_node_selected(self)
	graph_edit.on_node_close()


func delete_inputs(fork: ForkCommand) -> void:
	var block: Block = get_meta("block")
	remove_slot(block.inputs, c_inputs, Direction.LEFT, fork)


func delete_outputs(fork: ForkCommand) -> void:
	var block: Block = get_meta("block")
	remove_slot(block.outputs, c_outputs, Direction.RIGHT, fork)


func remove_slot(
	meta_slots: Array, control_slots: Array, dir: Direction, fork: ForkCommand
) -> void:
	var idx := meta_slots.find(fork)
	if idx == -1:
		return

	for f in meta_slots:
		if dir == Direction.LEFT:
			set_slot_enabled_left(meta_slots.find(f), false)
		elif dir == Direction.RIGHT:
			set_slot_enabled_right(meta_slots.find(f), false)

	if control_slots.size() > 0:
		control_slots[idx].queue_free()
		control_slots.remove_at(idx)
		meta_slots.erase(fork)

	for f in meta_slots:
		if dir == Direction.LEFT:
			set_slot_enabled_left(meta_slots.find(f), true)
			set_slot_type_left(meta_slots.find(f), 1)
			set_slot_color_left(meta_slots.find(f), f.f_color)
		elif dir == Direction.RIGHT:
			set_slot_enabled_right(meta_slots.find(f), true)
			set_slot_type_right(meta_slots.find(f), 1)
			set_slot_color_right(meta_slots.find(f), f.f_color)


func add_g_node_output(fork: ForkCommand) -> void:
	var block: Block = get_meta("block")
	if !block.outputs.has(fork):
		block.outputs.append(fork)
	var idx := block.outputs.find(fork)
	if !is_slot_enabled_right(idx):
		create_contorl_for_g_node_connection(c_outputs, fork)
		set_slot_enabled_right(idx, true)
		set_slot_type_right(idx, 1)
		set_slot_color_right(idx, fork.f_color)


func add_g_node_input(fork: ForkCommand) -> void:
	var block: Block = get_meta("block")
	if !block.inputs.has(fork):
		block.inputs.append(fork)
	var idx := block.inputs.find(fork)
	if !is_slot_enabled_left(idx):
		create_contorl_for_g_node_connection(c_inputs, fork)
		set_slot_enabled_left(idx, true)
		set_slot_type_left(idx, 1)
		set_slot_color_left(idx, fork.f_color)


func create_contorl_for_g_node_connection(io_c: Array, fork: ForkCommand) -> void:
	var cc: Control = Control.new()
	cc.custom_minimum_size = Vector2(10, 10)
	add_child(cc)
	cc.set_owner(self)
	io_c.append(cc)


func _on_graph_node_dragged(from, too) -> void:
	graph_edit.on_node_dragged(from, too, title)
