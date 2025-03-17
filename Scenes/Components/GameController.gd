class_name GameController extends Node

@export var player: PlatformerCharacter
@export var room_creation_root_node: Node

@export var current_room: Room

func _ready():
	current_room.change_room_callback = change_room
	
func change_room(p_new_room):
	var new_room = load(p_new_room).new()
	new_room.change_room_callback = change_room
	current_room.queue_free()
	room_creation_root_node.add_child(new_room)
	player.position.x = 1920/2
