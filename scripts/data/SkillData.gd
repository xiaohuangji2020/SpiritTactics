# 技能信息
extends Resource
class_name SkillData

const Enums = preload("res://scripts/core/Enums.gd")

@export var skill_name: String = "技能名"
@export var attribute: Enums.Attribute = Enums.Attribute.NONE
@export var stamina_cost: int = 5
@export var damage: int = 25
@export var range: int = 1 # 攻击范围（格子数）
