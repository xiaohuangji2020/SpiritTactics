# 伤害管理器
extends Node

# 计算伤害的唯一入口
# 它需要所有相关方的信息：防御者、攻击者和使用的技能
func calculate_skill_damage(defender: Node2D, attacker: Node2D, skill: SkillData) -> int:
	# 检查输入是否有效
	if not (defender and attacker and skill and defender.data and attacker.data):
		return 0
	var base_damage = skill.damage
	var final_damage = float(base_damage)
	# 1. 计算本系加成 (STAB)
	if skill.attribute in attacker.data.attributes:
		final_damage *= GameConfig.STAB_MULTIPLIER
		print("触发本系加成！")
	# 2. 计算属性克制倍率 (调用我们已有的管理器)
	var effectiveness = AttributeManager.get_effectiveness(skill.attribute, defender.data.attributes)
	if effectiveness == GameConfig.SUPER_EFFECTIVE_MULTIPLIER:
		print("效果拔群!")
	if effectiveness == GameConfig.NOT_VERY_EFFECTIVE_MULTIPLIER:
		print("效果一般")
	final_damage *= effectiveness
	# 3. 未来可以在这里加入攻击/防御力计算、暴击计算等
	
	# 返回最终的整数伤害值
	return roundi(final_damage)
	
func calculate_environment_damage(defender: Node2D, effect_type) -> int:
	# 以后可以根据 effect_type (比如是火焰地面还是毒雾) 和防御者属性来计算伤害
	# 目前先返回一个固定值
	print(defender.name, " 受到了环境伤害！")
	return 10
