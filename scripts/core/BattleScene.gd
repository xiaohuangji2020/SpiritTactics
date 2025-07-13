extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var beast_base: Node2D = $TileMapLayer/BeastBase

var selected_beast = null

func _ready() -> void:
	beast_base.selected.connect(on_beast_selected)

	var grid_pos = Vector2i(2,5)
	var pixel_pos = tile_map_layer.map_to_local(grid_pos)
	beast_base.position = pixel_pos

func on_beast_selected(beast_instance) -> void:
	print('信号：', beast_instance.name)
	selected_beast = beast_instance

func _unhandled_input(event: InputEvent) -> void:
	if selected_beast != null and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var target_grid_pos = tile_map_layer.local_to_map(event.position)
			var target_pixel_pos = tile_map_layer.map_to_local(target_grid_pos)
			selected_beast.position = target_pixel_pos
			print('移动到格子', target_grid_pos)
			selected_beast = null
