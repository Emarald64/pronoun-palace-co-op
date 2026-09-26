class_name GiftCoop
extends "res://source/spells/gift.gd"

func _use():
	do_battle_start_transformation([])

func get_gift_reroll_pool(_exclude_spells = [], allow_player_repeats: = false) -> Dictionary:
	var pool=CoOp.SPELL_WEIGHTS
	#for spell_id in base_pool:
		#pool["co-op:"+spell_id]=base_pool[spell_id]
	
	if not allow_player_repeats:
		for spell in player.get_spells():
			pool.erase(spell.id)

	return pool

func get_tooltip_context() -> Dictionary:
	return {alt_title=rng.spell.randf()<0.01}

func do_battle_start_transformation(exclude_spells):
	transform_spell(rng.reroll.weighted_random(get_gift_reroll_pool(exclude_spells)))

func post_generate_tooltip(tooltip:GameTooltip):
	var group=StringManager.get_string_group("mod/co-op/names")
	tooltip.add_subtooltip(group.strings.values().pick_random())
