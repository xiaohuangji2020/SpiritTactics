# 配置
extends Node

const Enums = preload("res://scripts/core/Enums.gd")

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

@export_group("Combat Rules")
# 行动所需体力阈值
@export var STAMINA_THRESHOLD_TO_ACT: int = 100


# 一个私有字典，用于在游戏运行时进行快速查询
# Key是状态的Enum，Value是完整的StatusEffectData资源
var _status_effects_dict: Dictionary = {}

func _ready():
	# 在游戏启动时，调用我们的新函数来加载所有状态效果
	_load_status_effects()

# 这个函数专门负责扫描文件夹并加载资源
func _load_status_effects():
	Log.info("开始加载状态效果资源...")
	# 定义我们要扫描的文件夹路径
	var directory_path = "res://resources/status_effects/"
	var dir = DirAccess.open(directory_path)
	if dir:
		# 开始遍历目录中的所有文件
		for file_name in dir.get_files():
			if file_name.ends_with(".tres"):
				# 加载资源文件
				var effect_data = load(directory_path + file_name)
				# 检查加载的资源是否是我们想要的类型
				if effect_data is StatusEffectData:
					_status_effects_dict[effect_data.effect_type] = effect_data
					Log.info("  - 已加载: ", file_name)
				else:
					Log.warning("1003: 文件 ", file_name, " 不是一个有效的StatusEffectData资源。")
	else:
		Log.error("1004: 无法找到状态效果资源目录: ", directory_path)

# 全局查询函数
func get_status_effect_data(effect_type: Enums.StatusEffect) -> StatusEffectData:
	# 从字典中查找并返回数据，如果找不到则返回null
	return _status_effects_dict.get(effect_type, null)
