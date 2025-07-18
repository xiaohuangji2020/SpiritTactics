# 战场管理器，根据LevelData生成战场
extends Node

const BEAST_SCENE = preload("res://scenes/entities/Beast.tscn")

func setup_battle(level_data: LevelData, units_parent: Node2D):
	# 清理旧单位
	for child in units_parent.get_children():
		child.queue_free()
	# 生成玩家单位
	for unit_setup in level_data.play_units:
		spawn_unit(unit_setup, units_parent)
	for unit_setup in level_data.enemy_units:
		spawn_unit(unit_setup, units_parent)

func spawn_unit(setup_info: UnitData, parent_node: Node2D):
	if not setup_info.beast_data:
		print("错误1001：UnitSetup中缺少BeastData!")
		return
	# 新建一个实例
	var beast_instance = BEAST_SCENE.instantiate()
	# 赋值
	beast_instance.data = setup_info.beast_data
	# 放到场景树中
	parent_node.add_child(beast_instance)
	# 将新创建单位的died信号，连接到TurnManager的处理函数上
	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager:
		beast_instance.died.connect(turn_manager.on_beast_died)
		turn_manager.beast_turn_started.connect(beast_instance.on_turn_started)
		turn_manager.beast_turn_ended.connect(beast_instance.on_turn_ended)
	# 修改虚拟坐标
	beast_instance.set_meta("grid_pos", setup_info.start_position)
