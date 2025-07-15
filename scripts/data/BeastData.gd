# 精灵信息
extends Resource
class_name BeastData

@export var beast_name: String = "-"
@export var sprite_texture: Texture2D
@export var max_hp: int = 100
@export var speed: int = 5 # 速度决定体力恢复速度
@export var skills: Array[SkillData]
