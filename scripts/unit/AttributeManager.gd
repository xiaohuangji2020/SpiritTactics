# 属性和克制关系管理
extends Node
const Enums = preload("res://scripts/core/Enums.gd")
const Attribute = Enums.Attribute

# 使用嵌套字典来存储完整的克制关系图
var type_chart = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 克制关系图
	# 格式：{ 攻击方属性: { 防守方属性: 倍率 } }
	type_chart[Attribute.FIRE] = {
		Attribute.WOOD: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.ICE: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.FIRE: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.WATER: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
	}
	type_chart[Attribute.WATER] = {
		Attribute.FIRE: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.GROUND: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.WATER: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.WOOD: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
	}
	type_chart[Attribute.WOOD] = {
		Attribute.FIRE: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.GROUND: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.WATER: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.WOOD: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.POISON: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.FLYING: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
	}
	type_chart[Attribute.ELECTRIC] = {
		Attribute.WATER: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.FLYING: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.ELECTRIC: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.WOOD: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.GROUND: GameConfig.IMMUNE_MULTIPLIER,
	}
	type_chart[Attribute.ICE] = {
		Attribute.FLYING: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.WOOD: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.GROUND: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.WATER: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.FIRE: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.ICE: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
	}
	type_chart[Attribute.GROUND] = {
		Attribute.FIRE: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.POISON: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.ELECTRIC: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.WOOD: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.FLYING: GameConfig.IMMUNE_MULTIPLIER,
	}
	type_chart[Attribute.POISON] = {
		Attribute.WOOD: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.POISON: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
		Attribute.GROUND: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
	}
	type_chart[Attribute.POISON] = {
		Attribute.WOOD: GameConfig.SUPER_EFFECTIVE_MULTIPLIER,
		Attribute.ELECTRIC: GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER,
	}


func get_effectiveness(attack_type: Attribute, defense_types: Array[Attribute]) -> float:
	if defense_types.is_empty() or attack_type == Attribute.NONE:
		return 1.0
	var total_multiplier: float = 1.0
	for def_type in defense_types:
		if type_chart.has(attack_type) and type_chart[attack_type].has(def_type):
			total_multiplier *= type_chart[attack_type][def_type]
	return total_multiplier
