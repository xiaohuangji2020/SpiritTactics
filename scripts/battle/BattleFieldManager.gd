# BattlefieldManager.gd
# 职责：
# 1. 在战斗开始时，根据TileMap的“蓝图”创建一份可修改的“运行时”战场数据。
# 2. 管理所有地块的临时状态（如燃烧、潮湿）及其持续时间。
# 3. 在每回合结束时，处理所有地块状态的演变（扣血、倒计时、状态转化）。
# 4. 提供接口供其他系统查询和修改地块状态。
extends Node

const Enums = preload("res://scripts/core/Enums.gd")

# ==================== 内部类：运行时地块数据 ====================
# 这个类的一个实例，就代表战场上一个格子的所有当前信息
class MyTileData:
	var grid_pos: Vector2i
	# --- 固有属性 (从TileSet蓝图读取，只能被“转化”技能修改) ---
	var base_attribute: Enums.TerrainAttribute
	var base_is_flammable: bool = false

	# --- 临时状态 (在战斗中动态添加和移除) ---
	# 数组中存放的元素格式: { "data": TerrainStateData, "duration": 2 }
	var active_states: Array = []

	# --- 辅助查询函数 ---
	
	# 获取当前地块的所有属性（基础属性 + 临时状态赋予的属性）
	func get_current_attributes() -> Array:
		var attrs = [base_attribute]
		for state_wrapper in active_states:
			var state_data: TerrainStateData = state_wrapper.data
			if state_data.grants_temporary_attribute != Enums.Attribute.NONE:
				if not attrs.has(state_data.grants_temporary_attribute):
					attrs.append(state_data.grants_temporary_attribute)
		return attrs

	# 判断地块当前是否易燃
	func is_currently_flammable() -> bool:
		var flammable = base_is_flammable
		# 临时状态可以覆盖这个属性
		for state_wrapper in active_states:
			var state_data: TerrainStateData = state_wrapper.data
			if state_data.makes_flammable:
				flammable = true
		# 比如[燃尽]状态可以使其不再易燃 (假设makes_flammable在burn_out.tres里为false)
		# 这里需要更精细的规则，比如一个“潮湿”状态可以强制覆盖易燃为false
		# 暂时先用简单逻辑
		return flammable

	# 判断是否拥有某个临时状态
	func has_state(state_type: Enums.TerrainState) -> bool:
		for state_wrapper in active_states:
			if state_wrapper.data.state_type == state_type:
				return true
		return false

# ==================== 管理器核心逻辑 ====================

# 运行时网格数据, Key: Vector2i, Value: MyTileData 实例
var runtime_grid_data: Dictionary = {}
# 保存对TileMapLayer的引用，方便修改地块外观
var _tilemap_node: TileMapLayer = null

# === 初始化 ===

# 在战斗开始时调用，用于根据“蓝图”初始化战场
func setup_battlefield(tilemap_node: TileMapLayer):
	runtime_grid_data.clear()
	_tilemap_node = tilemap_node # 保存引用
	
	if not _tilemap_node:
		Log.error("BattlefieldManager: TileMapLayer节点无效！")
		return

	# 遍历所有被绘制过的格子，创建运行时数据
	for grid_pos in _tilemap_node.get_used_cells():
		var cell_data_from_tileset = _tilemap_node.get_cell_tile_data(grid_pos)
		
		var new_tile_data = MyTileData.new()
		new_tile_data.grid_pos = grid_pos
		
		if cell_data_from_tileset:
			# 从TileSet蓝图中读取初始属性
			new_tile_data.base_attribute = cell_data_from_tileset.get_custom_data("terrain_type")
			new_tile_data.base_is_flammable = cell_data_from_tileset.get_custom_data("is_flammable")
		
		runtime_grid_data[grid_pos] = new_tile_data
	Log.info("战场地块数据初始化完成。")

# === 公共接口 (Public API) ===

# 获取地块的运行时数据
func get_tile_data(grid_pos: Vector2i) -> MyTileData:
	return runtime_grid_data.get(grid_pos, null)

# 对地块施加一个临时状态
func apply_state_to_tile(grid_pos: Vector2i, state_data: TerrainStateData):
	var tile_data = get_tile_data(grid_pos)
	if not tile_data or not state_data:
		return

	# 检查是否已有同类状态，有则刷新持续时间
	for existing_state in tile_data.active_states:
		if existing_state.data.state_type == state_data.state_type:
			existing_state.duration = state_data.duration
			Log.info("地块", grid_pos, "的", Enums.TerrainState.keys()[state_data.state_type], "状态已刷新。")
			return

	# 如果没有，则添加新状态
	var new_state_wrapper = {
		"data": state_data,
		"duration": state_data.duration
	}
	tile_data.active_states.append(new_state_wrapper)
	Log.info("地块", grid_pos, " 附加了", Enums.TerrainState.keys()[state_data.state_type], "状态。")
	# TODO: 在这里可以生成对应的视觉特效（VFX）

# 永久转化地块的基础属性
func transform_tile_attribute(grid_pos: Vector2i, new_attribute: Enums.TerrainAttribute, new_tile_atlas_coords: Vector2i):
	var tile_data = get_tile_data(grid_pos)
	if tile_data and _tilemap_node:
		tile_data.base_attribute = new_attribute
		_tilemap_node.set_cell(grid_pos, 0, new_tile_atlas_coords) # 0是source_id
		Log.info("地块", grid_pos, "属性被永久转化为", Enums.TerrainAttribute.keys()[new_attribute])

# === 回合处理 (Turn Processing) ===

# 由TurnManager在每个单位行动结束后调用
func process_end_of_turn():
	var units_node = get_tree().get_first_node_in_group("units_container") # 假设单位都在这个群组的节点下
	if not units_node: return

	for grid_pos in runtime_grid_data.keys():
		var tile_data = runtime_grid_data[grid_pos]
		if tile_data.active_states.is_empty():
			continue

		var states_to_remove = []
		var states_to_add = []

		# 处理站在这个地块上的单位
		var unit_on_tile = _get_unit_on_tile(grid_pos, units_node)

		for state_wrapper in tile_data.active_states:
			var state_data: TerrainStateData = state_wrapper.data

			# 1. 处理对单位的效果 (比如伤害)
			if unit_on_tile and state_data.damage_per_turn > 0:
				Log.info(unit_on_tile.name, "因地块的", Enums.TerrainState.keys()[state_data.state_type], "效果受到了伤害！")
				unit_on_tile.take_damage(state_data.damage_per_turn)

			# 2. 状态持续时间减少
			state_wrapper.duration -= 1
			if state_wrapper.duration <= 0:
				states_to_remove.append(state_wrapper)
				# 检查是否有后继状态
				if state_wrapper.data.successor_state_data:
					states_to_add.append(state_wrapper.data.successor_state_data)
		
		# 3. 清理到期状态
		for state_to_remove in states_to_remove:
			tile_data.active_states.erase(state_to_remove)
			Log.info("地块 ",grid_pos, " 的 ", Enums.TerrainState.keys()[state_to_remove.data.state_type], " 状态已结束。")
			# TODO: 在这里移除对应的视觉特效

		# 4. 添加后继状态
		for state_data_to_add in states_to_add:
			apply_state_to_tile(grid_pos, state_data_to_add)

# === 私有辅助函数 ===
func _get_unit_on_tile(grid_pos: Vector2i, units_parent: Node) -> Node2D:
	for unit in units_parent.get_children():
		if unit.is_in_group("beasts") and unit.current_grid_pos == grid_pos:
			return unit
	return null
