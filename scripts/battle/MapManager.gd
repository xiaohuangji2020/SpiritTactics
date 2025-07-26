# 地图管理器
extends Node
# 假设你有一个TileMap节点
@onready var tile_map: TileMapLayer = $"../../TileMap/Battle"

# 假设格子大小是 128*128
const TILE_SIZE = 128*128

# --- 计算可移动范围的核心函数 ---
# start_pos: 精灵的当前格子坐标 (Vector2i)
# movement: 精灵的移动力 (int)
# returns: 一个可到达格子坐标的数组 (Array[Vector2i])
func get_reachable_tiles(start_pos: Vector2i, movement: int) -> Array[Vector2i]:
	var reachable_tiles: Array[Vector2i] = [start_pos] # 所有可达的格子，初始只有起点
	var queue = [start_pos] # 待检查的队列，初始只有起点
	var visited = {start_pos: 0} # 记录已访问的格子及到达该格子的成本

	while not queue.is_empty():
		var current_tile = queue.pop_front()
		var current_cost = visited[current_tile]

		# 如果当前格子的成本已达移动力上限，则不再向外探索
		if current_cost >= movement:
			continue

		# 探索周围的四个方向（上、下、左、右）
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor_tile = current_tile + direction

			# --- 在这里添加你的判断逻辑 ---
			# 1. 检查邻居格子是否在地图边界内
			# 2. 检查邻居格子是否是障碍物 (例如山、水)
			# 3. 检查邻居格子是否已被其他单位占据
			if is_valid_and_walkable(neighbor_tile):
				var new_cost = current_cost + 1 # 假设每格消耗1点移动力

				# 如果这个邻居格子还没被访问过，或者找到了更短的路径
				if not visited.has(neighbor_tile) or new_cost < visited[neighbor_tile]:
					visited[neighbor_tile] = new_cost
					queue.push_back(neighbor_tile)
					if not neighbor_tile in reachable_tiles:
						reachable_tiles.append(neighbor_tile)
	return reachable_tiles

# 一个辅助函数，用来判断格子是否有效且可通行
func is_valid_and_walkable(tile_pos: Vector2i) -> bool:
	# 示例：检查是否在TileMap的矩形区域内
	var map_rect = tile_map.get_used_rect()
	if not map_rect.has_point(tile_pos):
		return false

	# 示例：检查特定图层的TileData，判断是否为障碍物
	var tile_data = tile_map.get_cell_tile_data(tile_pos) # 假设在第0层
	if tile_data and tile_data.get_custom_data("is_obstacle"):
		return false

	# 在这里可以继续添加其他判断，比如是否被其他角色占据等...

	return true
