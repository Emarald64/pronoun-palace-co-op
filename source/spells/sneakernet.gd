extends CoopSpell

func _use():
	var peer_id:int
	if get_meta("imaginary_shadow",false):
		var players=Game.players.keys()
		peer_id=rng.spell.pick_random(players.filter(can_select_player))
	else:
		peer_id=await player.get_selection(CoOp.PEER_SELECTION_TYPE,can_select_player)
	if peer_id==null:
		_end_use()
		return
	print("swapping board with ",peer_id)
	var tile_state=tile_board.get_tile_state_save_data()
	tile_state.size.preview_rows=null
	coop_spell_effects.swap_board.rpc_id(peer_id,tile_state,true)
	if not await wait_for_reply_with_timeout():
		coop_notifications.add_spell_notification(id,{success=false,name=Game.get_player_name(peer_id)})
	await coop_spell_effects.animation_finished
	_post_use()

func can_select_player(player_id:int)->bool:
	return player_id!=Game.multiplayer.get_unique_id() and not player_id in main.dead_players and not word_builder.peer_attacks[player_id].submitted


func is_usable():
	return super() and not main.candy_round
