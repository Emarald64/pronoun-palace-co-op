extends Spell


func _use():
	var target_id= await player.get_selection(3)
	if target_id==null:
		_end_use()
		return
	main.blue_box_effect.rpc_id(target_id,rng.spell.seed)
	_post_use()
