extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var sprite_base: Node2D = $TileMapLayer/SpriteBase

func _ready() -> void:
	var grid_pos = Vector2i(2,2)
	var pixel_pos = tile_map_layer.map_to_local(grid_pos)
	sprite_base.position = pixel_pos
