# 伤害管理器
extends Node

# 技能计算伤害的唯一入口
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
	
	# 4. 异常相关
	var attack_mod: float = 1.0
	var defense_mod: float = 1.0
	# 4.1. 累积攻击方的所有攻击修正
	for effect_data in attacker.get_all_active_effect_data(): # 假设Beast有这个新函数
		attack_mod *= effect_data.attack_modifier
	# 4.2. 累积防御方的所有防御修正
	for effect_data in defender.get_all_active_effect_data():
		defense_mod *= effect_data.defense_modifier
	final_damage *= attack_mod / defense_mod # 伤害 = 基础伤害 * 攻击修正 / 防御修正
	
	# 返回最终的整数伤害值
	return roundi(final_damage)

# 处理技能异常
func process_skill_effects(defender: Node2D, attacker: Node2D, skill: SkillData):
	# 检查技能是否会施加状态，以及是否触发了概率
	if skill.applies_effect and randf() < skill.effect_chance:
		defender.apply_status_effect(skill.applies_effect)

# 环境伤害
func calculate_environment_damage(defender: Node2D, effect_type) -> int:
	# 以后可以根据 effect_type (比如是火焰地面还是毒雾) 和防御者属性来计算伤害
	# 目前先返回一个固定值
	print(defender.name, " 受到了环境伤害！")
	return 10
