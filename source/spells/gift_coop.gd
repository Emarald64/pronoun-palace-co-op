extends "res://source/spells/gift.gd"

func get_gift_reroll_pool(exclude_spells = [], allow_player_repeats: = false) -> Dictionary:
	var pool = SpellData.get_spell_pool("coop")
	
	if not allow_player_repeats:
		for spell in player.get_spells():
			pool.erase(spell.id)
	
	for spell_id in exclude_spells:
		pool.erase(spell_id)

	return pool

func do_battle_start_transformation(exclude_spells):
	reroll()
