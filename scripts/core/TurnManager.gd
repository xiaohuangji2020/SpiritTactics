# 回合管理器
extends Node


signal beast_turn_started(beast_node) # 行动开始信号
signal beast_turn_ended(beast_node)   # 行动结束信号

var all_beasts: Array[Node2D] = []
var is_battle_running: bool = false
var is_waiting_for_action: bool = false # 是否正在等待玩家操作
var current_turn_beast: Node2D = null # 当前行动的单位

# 新增一个处理函数
func on_beast_died(beast_node):
	print("TurnManager收到了", beast_node.name, "的死亡通知。")
	if all_beasts.has(beast_node):
		all_beasts.erase(beast_node) # 从列表中移除

# 供外部调用，开始战斗
func start_battle(beasts: Array[Node2D]):
	all_beasts = beasts
	is_battle_running = true
	is_waiting_for_action = false # 初始状态不是等待操作
	_calculate_next_turn() # 开始计算第一个行动者

# 当一个单位行动结束后，外部会调用这个函数
func on_action_completed():
	is_waiting_for_action = false
	if current_turn_beast:
		emit_signal("beast_turn_ended", current_turn_beast) # 发出回合结束信号
		current_turn_beast = null
	_calculate_next_turn()

func _calculate_next_turn():
	# 如果不是战斗中 或者是正在等待玩家操作
	if not is_battle_running or is_waiting_for_action:
		return
	var ticks_to_act = INF # 用一个极大的数表示需要无限“时间”才能行动
	var next_beast = null

	# 1. 找到最快能行动的单位
	for beast in all_beasts:
		var effective_speed = beast.get_effective_speed()
		if effective_speed <= 0: continue # 速度为0或负数的单位永远不能行动
		# 计算该单位还需要多少“时间单位(tick)”才能攒满体力
		var stamina_needed = GameConfig.STAMINA_THRESHOLD_TO_ACT - beast.current_stamina
		var current_ticks = stamina_needed / float(effective_speed)
		if current_ticks < ticks_to_act:
			ticks_to_act = current_ticks
			next_beast = beast
	if next_beast == null:
		print("错误：战场上没有可行动的单位！")
		is_battle_running = false
		return

	# 2. “快进时间”，为所有单位增加体力
	# ticks_to_act 是我们快进的时间长度
	for beast in all_beasts:
		var effective_speed = beast.get_effective_speed()
		beast.current_stamina += roundi(ticks_to_act * effective_speed)

	# 3. 将行动权交给最快的那个单位
	print("时间推进了 ", ticks_to_act, " 个单位。")
	print(next_beast.name, " 获得行动权！体力: ", next_beast.current_stamina)
	current_turn_beast = next_beast # 记录当前行动者
	is_waiting_for_action = true # 进入等待玩家操作的状态
	emit_signal("beast_turn_started", next_beast) # 发出回合开始信号
