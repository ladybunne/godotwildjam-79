class_name RoomEdge extends Node2D

@onready var wall: StaticBody2D = $Wall
@onready var transition_area: Area2D = $TransitionArea

var room_transporter: RoomTransporter = null

func reposition(p_room_width: int, is_left: bool):
	pass

func set_edge(p_destination: String, p_callback: Callable):
	if p_destination.is_empty() or not Globals.rooms.has(p_destination):
		wall.process_mode = Node.PROCESS_MODE_INHERIT
		wall.visible = true
		transition_area.process_mode = Node.PROCESS_MODE_DISABLED
		transition_area.visible = false
	else:
		transition_area.process_mode = Node.PROCESS_MODE_INHERIT
		transition_area.visible = true
		wall.process_mode = Node.PROCESS_MODE_DISABLED
		wall.visible = false
		if room_transporter == null:
			room_transporter = RoomTransporter.new(Globals.rooms[p_destination])
		room_transporter.change_room_callback = p_callback
		add_child(room_transporter)
		transition_area.body_entered.connect(room_transporter.transport)
