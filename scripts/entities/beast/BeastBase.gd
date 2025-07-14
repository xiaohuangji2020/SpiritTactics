extends Node2D

@export var data: BeastData
var current_hp: int
var current_stamina: int = 0
var can_act: bool = false

func _ready():
	# 当精灵被创建时，如果数据存在，就用数据来初始化自己
	if data:
		current_hp = data.max_hp
		# 我们可以顺便把节点名字也改了，方便调试
		#self.name = data.beast_name
		print("初始化精灵 ", self.name)
	else:
		print("警告：精灵 ", self.name, " 没有分配BeastData！")

func take_damage(amount: int):
	current_hp -= amount
	print(self.name, " 受到了 ", amount, " 点伤害，剩余HP: ", current_hp)
	if current_hp <= 0:
		print(self.name, " 已被击败！")
		queue_free() # 暂时先直接从场景移除
		
func on_new_turn_starts():
	if data:
		current_stamina += data.speed
	# 检查体力是否足够行动
	if current_stamina >= 10:
		can_act = true
		print(self.name, " 体力恢复至 ", current_stamina, "，可以行动！")
	else:
		can_act = false
		print(self.name, " 体力恢复至 ", current_stamina, "，尚不能行动。")
