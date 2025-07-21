# 定义属性枚举
enum Attribute {
	NONE,
	WATER,
	FIRE,
	WOOD,
	ELECTRIC,
	ICE,
	GROUND,
	POISON,
	FLYING,
}

# 定义异常状态枚举
enum StatusEffect {
	NONE,
	CONFUSED,
	BURNED,
	POISONED,
	PARALYZED,
	FROZEN,
	ASLEEP,
}

# 地块的固有属性
enum TerrainAttribute {
	NONE,
	GRASS,      # 草地
	DIRT,       # 土地
	WATER,      # 水洼
	ROCK,       # 岩地
	ASH         # 焦土
}

# 地块的临时状态
enum TerrainState {
	NONE,
	BURNING,    # 燃烧
	BURNT_OUT,  # 燃尽
	ELECTRIFIED,# 带电
	VINE_COVERED,# 藤蔓覆盖
	POISONED    # 毒液覆盖
}
