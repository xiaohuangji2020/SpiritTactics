# 战斗场景管理
extends Node2D

@export var current_level_data: LevelData

@onready var turn_manager: Node = $TurnManager
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var units: Node2D = $Units
@onready var battle_setup: Node = $BattleSetup

func _ready() -> void:
	if not current_level_data:
		Log.error("1001：没有分配关卡数据!")
		return
	# 调用BattleSetup来布置场景
	battle_setup.setup_battle(current_level_data, units)
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
			beast.position = tile_map_layer.map_to_local(grid_pos)
	# 连接TurnManager的信号
	turn_manager.beast_turn_started.connect(_on_beast_turn_started)
	# 开始战斗
	turn_manager.start_battle(beasts_array)

# 在_input函数中，当一次行动（移动或攻击）成功后
func _on_skill_used_successfully(skill: SkillData):
	selected_beast.current_stamina -= skill.stamina_cost
	Log.debug(selected_beast.current_name, " 剩余体力: ", selected_beast.current_stamina)
	# 检查是否还有足够体力行动
	if not selected_beast.can_perform_action():
		# 如果体力不够任何行动了，可以自动结束回合
		_end_current_turn()

func _end_current_turn():
	if selected_beast == null: return
	# 恢复单位的视觉状态
	selected_beast.get_node("Sprite2D").modulate = Color.WHITE
	selected_beast = null
	# 通知TurnManager，玩家操作已完成
	turn_manager.on_action_completed()

# 当TurnManager分配了行动权
func _on_beast_turn_started(beast_node):
	selected_beast = beast_node
	# 在这里可以更新UI，高亮当前行动的单位等
	selected_beast.get_node("Sprite2D").modulate = Color.LIGHT_BLUE

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
		if selected_beast != null and selected_beast.can_perform_action():
			var target_grid_pos = tile_map_layer.local_to_map(mouse_pos)
			var target_pixel_pos = tile_map_layer.map_to_local(target_grid_pos)
			selected_beast.position = target_pixel_pos
			Log.debug("移动到格子", target_grid_pos)
			selected_beast.get_node("Sprite2D").modulate = Color.WHITE
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
			if selected_beast != null:
			# 如果已经有已选中的精灵了
				if top_beast == selected_beast:
				# 点击自己，取消选中
					selected_beast.get_node("Sprite2D").modulate = Color.WHITE
					selected_beast = null
				else:
				# 点击了另一只精灵，执行攻击逻辑！
					# 1. 获取攻击技能 (我们先假设第一个技能就是攻击)
					var attack_skill = selected_beast.data.skills[0]
					# 2. 检查距离和体力
					var distance = tile_map_layer.local_to_map(selected_beast.position).distance_to(tile_map_layer.local_to_map(top_beast.position))
					if distance <= attack_skill.range and selected_beast.current_stamina > attack_skill.stamina_cost:
						Log.debug(selected_beast.current_name, " 对 ", top_beast.current_name, " 使用了 ", attack_skill.skill_name)
						# 造成伤害
						var final_damage = CombatManager.calculate_skill_damage(top_beast, selected_beast, attack_skill)
						top_beast.take_damage(final_damage)
						# 计算异常
						CombatManager.process_skill_effects(top_beast, selected_beast, attack_skill)
						_on_skill_used_successfully(attack_skill)
					else:
						Log.debug("距离过远或体力不足，无法攻击！")
			else:
			# 没有已选中的
				if top_beast.can_perform_action():
					if selected_beast != null:
						selected_beast.get_node("Sprite2D").modulate = Color.WHITE
					selected_beast = top_beast
					selected_beast.get_node("Sprite2D").modulate = Color.BLUE
					Log.debug("选中了精灵：", selected_beast.current_name)
				else:
					Log.debug(top_beast.current_name, " 体力不足，无法行动！")
	# get_viewport().set_input_as_handled() # 消耗事件
