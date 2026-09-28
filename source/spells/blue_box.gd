extends CoopSpell

func _use():
	var target_id= await player.get_selection(CoOp.PEER_SELECTION_TYPE)
	if target_id==null:
		_end_use()
		return
	main.coop_spell_effects.blue_box_effect.rpc_id(target_id,rng.spell.seed)
	_post_use()
