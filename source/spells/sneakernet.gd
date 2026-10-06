extends CoopSpell

func _use():
	var peer_id=await player.get_selection(CoOp.PEER_SELECTION_TYPE,
		func (player_id:int)->bool:
			return not word_builder.peer_attacks[player_id].submitted
	)
	if peer_id==null:
		_end_use()
		return
	print("swapping board with ",peer_id)
	var tile_state=tile_board.get_tile_state_save_data()
	tile_state.size.preview_rows=null
	coop_spell_effects.swap_board.rpc_id(peer_id,tile_state,true)
	if not await wait_for_reply_with_timeout():
		coop_notifications.add_spell_notification(id,{success=false,name=Game.get_player_name(peer_id)})
	_post_use()
