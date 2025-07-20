extends Node

# 玩家当前的关卡，暂时写死
var currentLevelInfo: Dictionary = {
	"level": 1,
	"tres": preload("res://resources/levels/Level01.tres")
}

func on_start():
	# 判断玩家当前进度，获取当前关卡
	get_tree().change_scene_to_file("res://scenes/battle/Battle.tscn")
