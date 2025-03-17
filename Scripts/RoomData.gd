class_name RoomData extends Resource

# The internal name of the room.
@export var room_name: String = ""

# The name displayed to players upon entering the room.
@export var display_name: String = ""

# The width of the room. Automatically positions elements to fit.
@export var room_width: int = 1000

# Which room the left edge should lead to. Leave blank to make it a wall.
@export var left_edge_destination: String

# Which room the right edge should lead to. Leave blank to make it a wall.
@export var right_edge_destination: String
