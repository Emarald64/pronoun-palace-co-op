extends "res://source/spells/gift.gd"

func _spell_init():
	secret_id=SPELLS.GIFT_ENHANCING

func _ready():
	if player_spell_slot==null:
		is_ready=false
	else:
		player_spell_slot.set_meta("alt_gift",id)

func get_gift_reroll_pool(_exclude_spells = [], allow_player_repeats: = false) -> Dictionary:
	var base_pool =  load("res://mods/co-op/mod.gd").spell_weights.duplicate_deep()
	var pool={}
	for spell_id in base_pool:
		pool["co-op:"+spell_id]=base_pool[spell_id]
	
	if not allow_player_repeats:
		for spell in player.get_spells():
			pool.erase(spell.id)

	return pool

func do_battle_start_transformation(exclude_spells):
	transform_spell(rng.reroll.weighted_random(get_gift_reroll_pool(exclude_spells)))

func post_generate_tooltip(tooltip:GameTooltip):
	var group=StringManager.get_string_group("mod/co-op/names")
	tooltip.add_subtooltip(group.strings.values().pick_random())
