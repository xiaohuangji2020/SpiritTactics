extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var units: Node2D = $units
var player_beast: Node2D = null

func _on_beast_ready(beast_node):
	print("收到了来自 ", beast_node.name, " 的通知！")
	self.player_beast = beast_node

func _ready() -> void:
	await self.ready 
	var grid_pos = Vector2i(2,5)
	var pixel_pos = tile_map_layer.map_to_local(grid_pos)
	player_beast.position = pixel_pos

var selected_beast = null
func _input(event: InputEvent) -> void:
	# 不是左键直接返回
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	# 获取物理世界并准备射线查询
	var space_state = get_world_2d().direct_space_state
	var mouse_pos = get_global_mouse_position()
	# 设置查询参数，获取在鼠标位置的所有碰撞题
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	# 指定碰撞掩码，精灵都在第2个物理层
	query.collision_mask = 2
	# 查询默认不包含area2D
	query.collide_with_areas = true

	var results = space_state.intersect_point(query)
	# 分析查询结果
	if results.is_empty():
		# 情况A：点击到了空白区域
		if selected_beast != null and selected_beast.can_act:
			var target_grid_pos = tile_map_layer.local_to_map(mouse_pos)
			var target_pixel_pos = tile_map_layer.map_to_local(target_grid_pos)
			selected_beast.position = target_pixel_pos
			print('移动到格子', target_grid_pos)
			selected_beast.get_node("Sprite2D").modulate = Color.WHITE
			# 移动也是一种行动，消耗体力和行动机会
			selected_beast.current_stamina -= 10 # 假设移动消耗10体力
			selected_beast.can_act = false
			selected_beast = null
	else:
		# 情况B：点击到了一个或多个精灵
		var top_beast = null
		var max_y = -INF
		for result in results:
			var beast = result.collider.get_owner() #获取碰撞器的容器area2D，再找area2D的owner 即beast的根节点
			# Y值越大，在屏幕上越靠下，视觉上越靠前
			if beast.global_position.y > max_y:
				max_y = beast.global_position.y
				top_beast = beast
		if top_beast != null:
			if top_beast.can_act:
				if selected_beast != null:
					selected_beast.get_node("Sprite2D").modulate = Color.WHITE
				selected_beast = top_beast
				selected_beast.get_node("Sprite2D").modulate = Color.BLUE
				print("选中了精灵：", selected_beast.name)
			else:
				print(top_beast.name, " 体力不足，无法行动！")
	#get_viewport().set_input_as_handled()


func _on_end_turn_button_pressed() -> void:
	print("--- 回合结束 ---")
	# 遍历所有子节点，找到精灵并更新它们的回合状态
	for child in units.get_children():
		if child.is_in_group("beasts"):
			child.on_new_turn_starts()
	pass # Replace with function body.
