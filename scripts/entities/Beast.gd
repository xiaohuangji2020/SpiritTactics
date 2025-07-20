extends Node2D

const Enums = preload("res://scripts/core/Enums.gd")
# 在脚本顶部定义一个信号，它会传递一个参数，就是节点自己
#signal ready_and_initialized(beast_node)
signal died(beast_node) # 定义一个信号，参数是死亡的节点自己

@export var data: BeastData
@onready var sprite_2d: Sprite2D = $Sprite2D

var current_name: String
var current_hp: int
var current_stamina: int = 0
# 字典的键是状态类型(int)，值是剩余持续时间(int)
var active_status_effects: Dictionary = {}

func _ready():
	# 当精灵被创建时，如果数据存在，就用数据来初始化自己
	if data:
		current_hp = data.max_hp
		# 我们可以顺便把节点名字也改了，方便调试
		self.name = data.beast_name
		current_name = data.beast_name
		Log.debug("初始化精灵 ", current_name)
		sprite_2d.texture =data.sprite_texture
		#emit_signal("ready_and_initialized", self)
	else:
		Log.debug("警告：精灵 ", current_name, " 没有分配BeastData！")

# 使用技能前
func before_use_skill(skill: SkillData):
	pass

# 使用技能后
func after_use_skill(skill: SkillData):
	current_stamina -= skill.stamina_cost
	Log.debug(current_name, " 使用了技能：", skill.skill_name, " 消耗了", skill.stamina_cost, " 体力, 剩余", current_stamina, " 体力")

# 受伤
func take_damage(amount: int):
	current_hp -= amount
	Log.debug(current_name, " 受到了 ", amount, " 点伤害，剩余HP: ", current_hp)
	# 在这里可以触发受伤动画、显示伤害数字等
	if current_hp <= 0:
		Log.debug(current_name, " 已被击败！")
		emit_signal("died", self)
		queue_free() # 暂时先直接从场景移除

# 是否可行动
func can_perform_action() -> bool:
	if current_stamina >= GameConfig.STAMINA_THRESHOLD_TO_ACT: # 首先检查基础的体力是否足够
		for effect_data in get_all_active_effect_data():
			if (effect_data.prevents_action):
				Log.debug(current_name, " 因", effect_data.effect_type, "无法行动！")
				return false
			if effect_data.action_fail_chance > 0.0 and randf() < effect_data.action_fail_chance:
				Log.debug(current_name, " 因", effect_data.effect_type, "行动失败！")
				return false
		return true
	return false

# 添加状态
func apply_status_effect(effect_data: StatusEffectData):
	if not active_status_effects.has(effect_data.effect_type):
		active_status_effects[effect_data.effect_type] = effect_data.duration_in_turns
		Log.debug(current_name, " 陷入了 ", Enums.StatusEffect.keys()[effect_data.effect_type], " 状态！")

# 移除一个状态
func remove_status_effect(effect_type: Enums.StatusEffect):
	if active_status_effects.has(effect_type):
		active_status_effects.erase(effect_type)
		Log.debug(current_name, " 的 ", Enums.StatusEffect.keys()[effect_type], " 状态解除了。")

# 获取实时所有异常
func get_all_active_effect_data() -> Array[StatusEffectData]:
	var effect_data_array: Array[StatusEffectData] = []
	for effect_type in active_status_effects.keys():
		# 调用GameConfig的全局函数来获取数据
		var effect_data = GameConfig.get_status_effect_data(effect_type)
		if effect_data:
			effect_data_array.append(effect_data)
	return effect_data_array

# 获取实时速度
func get_effective_speed() -> float:
	# 如果没有数据，速度为0
	if not data:
		return 0.0
	# 从数据中获取基础速度
	var base_speed = float(data.speed)
	var speed_modifier = 1.0

	# 遍历所有激活的状态效果，累积速度修正值
	for effect_data in get_all_active_effect_data():
		speed_modifier *= effect_data.speed_modifier

	# 返回最终计算结果
	return base_speed * speed_modifier

# 获取实时攻击
func get_effective_attack_modifier() -> float:
	var modifier = 1.0
	for effect_data in get_all_active_effect_data():
		modifier *= effect_data.attack_modifier
	return modifier

# 获取实时防御
func get_effective_defense_modifier() -> float:
	var modifier = 1.0
	for effect_data in get_all_active_effect_data():
		modifier *= effect_data.defense_modifier
	return modifier

# 回合开始hook
func on_turn_started(beast_node):
	# 确保是自己的回合
	if beast_node != self:
		return
	Log.debug(current_name, " 的回合开始了！")
	# 这里是未来处理“回合开始时”触发的buff或特性的地方
	# 比如“每回合开始时，防御力提升”

# 回合结束hook
func on_turn_ended(beast_node):
	if beast_node != self:
		return
	Log.debug(current_name, " 的回合结束了。")
	# 这里是处理“回合结束时”效果的最佳位置
	# 我们把之前的扣血逻辑搬到这里，这就修复了Bug
	var effects_to_remove = []
	for effect_data in get_all_active_effect_data():
		if effect_data.damage_per_turn > 0:
			Log.debug(current_name, " 因", effect_data.effect_type, "在回合结束时受到了伤害！")
			take_damage(effect_data.damage_per_turn)
		if effect_data.damage_per_turn_percent > 0.0:
			var percent_damage = roundi(data.max_hp * effect_data.damage_per_turn_percent)
			Log.debug(current_name, " 因", effect_data.effect_type, "受到了百分比伤害！")
			take_damage(percent_damage)
		# 2. 处理自动解除
		if effect_data.auto_remove_chance > 0.0 and randf() < effect_data.auto_remove_chance:
			effects_to_remove.append(effect_data.effect_type)
		# ... 其他回合末结算逻辑 ...

		active_status_effects[effect_data.effect_type] -= 1
		if active_status_effects[effect_data.effect_type] <= 0:
			effects_to_remove.append(effect_data.effect_type)

	for effect_type in effects_to_remove:
		remove_status_effect(effect_type)

# 关于“麻痹”，我们之前的can_perform_action()已经完美处理了“行动前”的判断
# 它在玩家尝试行动(_input触发)时被调用，这本身就是一个隐式的“行动前钩子”
