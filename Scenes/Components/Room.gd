class_name Room extends Node2D

@export var room_data: RoomData = null
var fallback_room_data: RoomData = load("res://Assets/Resources/RoomData/A0-01-Test1.tres")

@onready var room_floor: StaticBody2D = $Floor
@onready var left_edge: RoomEdge = $LeftEdge
@onready var right_edge: RoomEdge = $RightEdge

# Provided by game controller to allow rooms to transition to other rooms.
var change_room_callback: Callable :
	set(p_callback):
		change_room_callback = p_callback
		setup_edges()

func _ready():
	if room_data == null:
		room_data = fallback_room_data
	
	reposition()
	setup_edges()

func reposition():
	# Floor
	var floor_shape: CollisionShape2D = room_floor.get_child(0)
	
	# Edges
	left_edge.reposition(room_data.room_width, true)
	right_edge.reposition(room_data.room_width, false)

func setup_edges():
	left_edge.set_edge(room_data.left_edge_destination, change_room_callback)
	right_edge.set_edge(room_data.right_edge_destination, change_room_callback)
