extends Node

var rooms: Dictionary[String, PackedScene] = {}
var flags: Dictionary[String, String] = {}

const ROOM_DATA_PATH = "res://Assets/Resources/RoomData/"
const ROOM_SCENE_PATH = "res://Scenes/Rooms/"

func _ready():
	# Load rooms for wiring purposes.
	var dir = DirAccess.open(ROOM_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var room_data: RoomData = load(ROOM_DATA_PATH + file_name)
				rooms[room_data.room_name] = load(ROOM_SCENE_PATH + file_name.replace(".tres", ".tscn"))
			file_name = dir.get_next()
