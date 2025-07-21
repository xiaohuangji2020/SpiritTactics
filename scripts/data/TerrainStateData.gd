# 地形状态
extends Resource
class_name TerrainStateData

const Enums = preload("res://scripts/core/Enums.gd")

@export var state: Enums.TerrainState = Enums.TerrainState.NONE
@export var duration: int = 2 # 状态持续的回合数

@export_group("Effects on Units")
@export var damage_per_turn: int = 0
@export var damage_attribute: Enums.Attribute = Enums.Attribute.NONE # 伤害的属性

@export_group("Effects on Tile")
# 这个状态会赋予地块什么临时属性？比如[燃烧]状态赋予地块[火焰]临时属性
@export var grants_temporary_attribute: Enums.Attribute = Enums.Attribute.NONE
# 这个状态是否让地块变得易燃？
@export var makes_flammable: bool = false

@export_group("State Transition")
# 当这个状态持续时间结束后，会转换成什么新状态？
# 例如 [燃烧] 结束后会变成 [燃尽]
@export var successor_state_data: TerrainStateData
