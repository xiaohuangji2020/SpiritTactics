# 异常状态
extends Resource
class_name StatusEffectData

const Enums = preload("res://scripts/core/Enums.gd")

@export var effect_type: Enums.StatusEffect = Enums.StatusEffect.NONE
@export var duration_in_turns: int = 3 # 效果持续几回合
@export var icon: Texture2D

@export_group("回合结算效果 (End of Turn Effects)")
# 每回合固定伤害（用于烧伤、中毒）
@export var damage_per_turn: int = 0
# 每回合基于最大HP百分比的伤害（更高级的中毒/烧伤）
@export var damage_per_turn_percent: float = 0.0
# 每回合自动解除的概率 (0.0到1.0，用于沉睡)
@export var auto_remove_chance: float = 0.0

@export_group("能力值修正 (Stat Modifiers)")
# 攻击力修正倍率 (1.0为不变, 0.5为减半)
@export var attack_modifier: float = 1.0
# 防御力修正倍率 (1.0为不变, 0.7为降低30%)
@export var defense_modifier: float = 1.0
# 速度修正倍率
@export var speed_modifier: float = 1.0

@export_group("行动限制 (Action Restrictions)")
# 是否完全不能行动
@export var prevents_action: bool = false
# 每回合不能行动的概率 (0.0到1.0, 用于麻痹)
@export var action_fail_chance: float = 0.0
