# 关卡信息
extends Resource
class_name LevelData

# 导出一个数组，数组的每个元素都是一个单位的配置
@export var play_units: Array[UnitData]
@export var enemy_units: Array[UnitData]

# 未来还可以添加：
# @export var initial_weather: WeatherTypeEnum
# @export var map_template: MapTemplate
