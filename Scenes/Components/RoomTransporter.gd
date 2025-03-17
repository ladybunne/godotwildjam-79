class_name RoomTransporter extends Node

@export var to_scene: PackedScene = null

var change_room_callback: Callable

func _init(p_to_scene: PackedScene = to_scene):
	to_scene = p_to_scene

func transport(_body):
	if to_scene:
		change_room_callback.call(to_scene)
