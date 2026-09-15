extends Spell


func _use():
	var target_id= await player.get_selection(3)
	if target_id==null:
		_end_use()
		return
	main.blue_box_effect.rpc_id(target_id,rng.spell.seed)
	_post_use()

func post_generate_tooltip(tooltip:GameTooltip):
	var group=StringManager.get_string_group("mod/co-op/names")
	tooltip.add_subtooltip(group.strings.values().pick_random())

func do_battle_end_transformation():
	super()
	if secret_id in ModLoader.get_node("coop").namespace_ids(CoOp.GIFT_SPELLS):
		transform_spell(secret_id)

func player_turn_started(is_battle_start: bool) -> void :
	super(is_battle_start)
	if not is_battle_start and secret_id == ModLoader.get_node("coop").namespace_id(CoOp.SPELLS.MIRACLE_CACHE_COOP):
		var pool=ModLoader.get_node("coop").namespace_dictionary_ids(CoOp.SPELL_WEIGHTS)
		var spell_id=rng.spell.weighted_random(pool)
		transform_spell(spell_id)
