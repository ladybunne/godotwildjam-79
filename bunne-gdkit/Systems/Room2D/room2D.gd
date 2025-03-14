class_name Room2D
extends Node2D

@export_group("Exits")
@export var up_exit: bool = true
@export var down_exit: bool = true
@export var left_exit: bool = true
@export var right_exit: bool = true
@export_group("")

@export var tilemap: TileMap = null
@export var search_for_tilemap: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if tilemap == null and search_for_tilemap:
		var possible_tilemap = get_node_or_null("TileMap")
		tilemap = possible_tilemap
