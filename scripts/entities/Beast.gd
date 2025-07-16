extends Node2D

const Enums = preload("res://scripts/core/Enums.gd")
# 在脚本顶部定义一个信号，它会传递一个参数，就是节点自己
#signal ready_and_initialized(beast_node)

@export var data: BeastData
@onready var sprite_2d: Sprite2D = $Sprite2D

var current_name: String
var current_hp: int
var current_stamina: int = 0
var can_act: bool = false
# 字典的键是状态类型(int)，值是剩余持续时间(int)
var active_status_effects: Dictionary = {}

func _ready():
	# 当精灵被创建时，如果数据存在，就用数据来初始化自己
	if data:
		current_hp = data.max_hp
		# 我们可以顺便把节点名字也改了，方便调试
		self.name = data.beast_name
		current_name = data.beast_name
		print("初始化精灵 ", current_name)
		sprite_2d.texture =data.sprite_texture
		#emit_signal("ready_and_initialized", self)
	else:
		print("警告：精灵 ", current_name, " 没有分配BeastData！")

# 受伤
func take_damage(amount: int):
	current_hp -= amount
	print(current_name, " 受到了 ", amount, " 点伤害，剩余HP: ", current_hp)
	# 在这里可以触发受伤动画、显示伤害数字等
	if current_hp <= 0:
		print(current_name, " 已被击败！")
		queue_free() # 暂时先直接从场景移除
		
# 这是一个新的辅助函数，它会返回该精灵当前所有激活状态的完整数据列表
func get_all_active_effect_data() -> Array[StatusEffectData]:
	var effect_data_array: Array[StatusEffectData] = []
	for effect_type in active_status_effects.keys():
		# 调用GameConfig的全局函数来获取数据
		var effect_data = GameConfig.get_status_effect_data(effect_type)
		if effect_data:
			effect_data_array.append(effect_data)
	return effect_data_array
	
# 临时的轮次流转
func on_new_turn_starts():
	if data:
		current_stamina += data.speed
	# 检查体力是否足够行动
	if current_stamina >= 10:
		can_act = true
		print(current_name, " 体力恢复至 ", current_stamina, "，可以行动！")
	else:
		can_act = false
		print(current_name, " 体力恢复至 ", current_stamina, "，尚不能行动。")
	
	# --- 处理异常状态效果 ---
	var effects_to_remove = []
	for effect_data in get_all_active_effect_data():
		# 获取当前状态的数据资源 (我们需要一个新的辅助函数来做这件事)
		if not effect_data: continue
		# 1. 处理回合末伤害
		if effect_data.damage_per_turn > 0:
			print(current_name, " 因", effect_data.effect_type, "受到了伤害！")
			take_damage(effect_data.damage_per_turn)
		if effect_data.damage_per_turn_percent > 0.0:
			var percent_damage = roundi(data.max_hp * effect_data.damage_per_turn_percent)
			print(current_name, " 因", effect_data.effect_type, "受到了百分比伤害！")
			take_damage(percent_damage)
		# 2. 处理自动解除
		if effect_data.auto_remove_chance > 0.0 and randf() < effect_data.auto_remove_chance:
			effects_to_remove.append(effect_data.effect_type)
		active_status_effects[effect_data.effect_type] -= 1
		if active_status_effects[effect_data.effect_type] <= 0:
			effects_to_remove.append(effect_data.effect_type)
	for effect_type in effects_to_remove:
		remove_status_effect(effect_type)

# 是否可行动
func can_perform_action() -> bool:
	if not can_act: # 首先检查基础的体力是否足够
		return false
	for effect_data in get_all_active_effect_data():
		if (effect_data.prevents_action):
			print(current_name, " 因", effect_data.effect_type, "无法行动！")
			return false
		if effect_data.action_fail_chance > 0.0 and randf() < effect_data.action_fail_chance:
			print(current_name, " 因", effect_data.effect_type, "行动失败！")
			return false
	return true

# 添加状态
func apply_status_effect(effect_data: StatusEffectData):
	if not active_status_effects.has(effect_data.effect_type):
		active_status_effects[effect_data.effect_type] = effect_data.duration_in_turns
		print(current_name, " 陷入了 ", Enums.StatusEffect.keys()[effect_data.effect_type], " 状态！")

# 移除一个状态
func remove_status_effect(effect_type: Enums.StatusEffect):
	if active_status_effects.has(effect_type):
		active_status_effects.erase(effect_type)
		print(current_name, " 的 ", Enums.StatusEffect.keys()[effect_type], " 状态解除了。")
