# 配置
extends Node

# ==================== 战斗倍率配置 ====================
@export_group("Combat Multipliers")
# 本系加成 (Same-Type Attack Bonus)
@export var STAB_MULTIPLIER: float = 1.5
# 暴击率 (未来可能用到)
@export var CRITICAL_HIT_CHANCE: float = 0.0
# 暴击伤害倍率 (未来可能用到)
@export var CRITICAL_HIT_MULTIPLIER: float = 1.5

# ==================== 属性系统配置 ====================
@export_group("Attribute System")
# 效果拔群的倍率
@export var SUPER_EFFECTIVE_MULTIPLIER: float = 1.5
# 效果不佳的倍率
@export var NOT_VERY_EFFECTIVE_MULTIPLIER: float = 0.5
# 无效/免疫的倍率
@export var IMMUNE_MULTIPLIER: float = 0.0

# ==================== 其他游戏配置 ====================
@export_group("General")
# 比如精灵最高等级 (未来可能用到)
@export var MAX_LEVEL: int = 100
