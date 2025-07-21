# 技能信息
extends Resource
class_name SkillData

const Enums = preload("res://scripts/core/Enums.gd")

@export var skill_name: String = "技能名"
@export var attribute: Enums.Attribute = Enums.Attribute.NONE
@export var stamina_cost: int = 5
@export var damage: int = 25
@export var range: int = 1 # 攻击范围（格子数）
@export var applies_effect: StatusEffectData # 技能会施加的异常状态
@export var effect_chance: float = 1.0 # 施加的概率 (1.0代表100%)

@export_group("Terrain Interaction")
@export var applies_terrain_state: TerrainStateData # 会提供的地形异常
