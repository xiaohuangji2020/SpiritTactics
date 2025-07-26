# 战斗场景
extends Node2D

@onready var tile_map_battle: TileMapLayer = $TileMap/Battle
@onready var units: Node2D = $Units
@onready var turn_manager: Node = $Utils/TurnManager
@onready var damage_manager: Node = $Utils/DamageManager
@onready var setup_manager: Node = $Utils/SetupManager
@onready var map_manager: Node = $Utils/MapManager

var selected_beast: Node2D = null
var movable_tiles = []

func _ready() -> void:
	# 1. 从全局单例中读取数据
	var current_level_info = GameManager.currentLevelInfo
	var current_level_data = current_level_info.tres
	if not current_level_data:
		Log.error("1001：关卡数据错误!")
		return
	# 调用SetupManger来布置场景
	setup_manager.setup_battle(current_level_data, units)
	# 等待整个项目ready，区别于await self.ready
	await get_tree().process_frame
	# 设置位置
	var beasts_array: Array[Node2D] = []
	for beast in units.get_children():
		# is_in_group是比类型检查更稳妥的方式
		if beast.is_in_group("beasts"):
			beasts_array.append(beast)
		if beast.has_meta("grid_pos"):
			var grid_pos = beast.get_meta("grid_pos")
			beast.position = tile_map_battle.map_to_local(grid_pos)
	# 开始战斗
	turn_manager.start_battle(beasts_array)

# 当TurnManager分配了行动权
func _on_beast_turn_started(beast_node):
	selected_beast = beast_node
	# 在这里可以更新UI，高亮当前行动的单位等
	_show_select_effect(selected_beast, true)

func _input(event: InputEvent) -> void:
	# 不是左键直接返回
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var mouse_pos = get_global_mouse_position()
	# 射线查询
	var results = _ray_query(mouse_pos)
	# 分析查询结果
	if results.is_empty():
		# 情况A：点击到了空白区域
		_handle_move(mouse_pos)
	else:
		# 情况B：点击到了一个或多个精灵
		var top_beast = _get_top_beast(results) # 本次射线查询最上面的精灵
		if top_beast != null:
			if selected_beast == null:
			# 没有已选中的
				_handle_select(top_beast)
			else:
				if top_beast == selected_beast:
				# 点击自己，取消选中
					_show_select_effect(selected_beast, false)
					selected_beast = null
				else:
				# 点击了另一只精灵，执行攻击逻辑！
					_handle_attack(top_beast)
	# get_viewport().set_input_as_handled() # 消耗事件

func _ray_query(mouse_pos):
	# 获取物理世界并准备射线查询
	var space_state = get_world_2d().direct_space_state
	# 设置查询参数，获取在鼠标位置的所有碰撞题
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	# 指定碰撞掩码，精灵都在第2个物理层
	query.collision_mask = 2
	# 查询默认不包含area2D
	query.collide_with_areas = true

	var results = space_state.intersect_point(query)
	return results

func _get_top_beast(results):
	var top_beast = null # 本次input射线查询，最上面的
	var max_y = -INF
	for result in results:
		var beast = result.collider.get_owner() #获取碰撞器的容器area2D，再找area2D的owner 即beast的根节点
		# Y值越大，在屏幕上越靠下，视觉上越靠前
		if beast.global_position.y > max_y:
			max_y = beast.global_position.y
			top_beast = beast
	return top_beast

func _handle_move(mouse_pos):
	if selected_beast != null and selected_beast.can_perform_action():
		var target_grid_pos = tile_map_battle.local_to_map(mouse_pos)
		var target_pixel_pos = tile_map_battle.map_to_local(target_grid_pos)
		selected_beast.position = target_pixel_pos
		Log.debug("移动到格子", target_grid_pos)
		_show_select_effect(selected_beast, false)
		clear_highlight()
		movable_tiles.clear()
		selected_beast = null

func _handle_attack(top_beast):
	# 1. 获取攻击技能 (我们先假设第一个技能就是攻击)
	var attack_skill = selected_beast.data.skills[0]
	# 2. 检查距离和体力
	var distance = tile_map_battle.local_to_map(selected_beast.position).distance_to(tile_map_battle.local_to_map(top_beast.position))
	if distance <= attack_skill.range and selected_beast.current_stamina > attack_skill.stamina_cost:
		Log.debug(selected_beast.current_name, " 对 ", top_beast.current_name, " 使用了 ", attack_skill.skill_name)
		# 造成伤害
		var final_damage = damage_manager.calculate_skill_damage(top_beast, selected_beast, attack_skill)
		top_beast.take_damage(final_damage)
		# 计算异常
		damage_manager.process_skill_effects(top_beast, selected_beast, attack_skill)
		_on_skill_used_successfully(attack_skill)
	else:
		Log.debug("距离过远或体力不足，无法攻击！")

func _handle_select(top_beast):
	if top_beast.can_perform_action():
		selected_beast = top_beast
		_show_select_effect(selected_beast, true)
		_on_character_selected(selected_beast)
		Log.debug("选中了精灵：", selected_beast.current_name)
	else:
		Log.debug(top_beast.current_name, " 体力不足，无法行动（无法选择）！")

# 在你的主游戏场景或UI控制器中

# 被选中时高亮
func _on_character_selected(beast):
	selected_beast = beast
	var start_tile = tile_map_battle.local_to_map(beast.global_position)
	# 1. 计算可移动范围
	movable_tiles = map_manager.get_reachable_tiles(start_tile, beast.data.movement)
	# 2. 显示高亮
	highlight_tiles(movable_tiles)

# --- 高亮显示的辅助函数 ---
func highlight_tiles(tiles: Array[Vector2i]):
	# 实现高亮逻辑，例如：
	# 1. 在TileMap上添加一个新的图层 (Layer)专门用于显示高亮
	# 2. 在该图层上，为每个可移动格子设置一个蓝色或绿色的高亮瓦片
	for tile_pos in tiles:
		Log.debug(tile_pos)
		# tile_map_battle.set_cell(highlight_layer, tile_pos, source_id, atlas_coords_of_highlight_tile)
		pass

func clear_highlight():
	# 清除高亮图层的所有瓦片
	# tile_map_battle.clear_layer(highlight_layer)
	pass

func _show_select_effect(beast, isSelected: bool = false):
	if (isSelected):
		beast.get_node("Sprite2D").modulate = Color.BLUE
	else:
		beast.get_node("Sprite2D").modulate = Color.WHITE


# 在_input函数中，当一次行动（移动或攻击）成功后
func _on_skill_used_successfully(skill: SkillData):
	selected_beast.after_use_skill(skill)
	# 检查是否还有足够体力行动
	if not selected_beast.can_perform_action():
		# 如果体力不够任何行动了，可以自动结束回合
		_end_current_turn()

func _end_current_turn():
	if selected_beast == null: return
	# 恢复单位的视觉状态
	_show_select_effect(selected_beast, false)
	selected_beast = null
	# 通知TurnManager，玩家操作已完成
	turn_manager.on_action_completed()
