extends "res://source/spells/gift.gd"

#func get_gift_reroll_pool(exclude_spells = [], allow_player_repeats: = false) -> Dictionary:
	#var base_pool =  CoOp.spell_weights.duplicate_deep()
	#var pool={}
	#for id in base_pool:
		#pool["co-op:"+id]=base_pool[id]
	#
	#if not allow_player_repeats:
		#for spell in player.get_spells():
			#pool.erase(spell.id)
#
	#return pool

func do_battle_start_transformation(exclude_spells):
	transform_spell(rng.reroll.weighted_random(get_gift_reroll_pool()))

func do_battle_end_transformation():
	transform_spell(secret_id)
