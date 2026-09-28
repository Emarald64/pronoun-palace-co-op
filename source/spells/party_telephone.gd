extends CoopSpell


#func set_status_tooltips():
	#status_tooltips = [TileStatus.DEFAULT]


func _use():
	var tiles=word_builder.tiles
	var tile_save_datas:=[]
	for tile:Tile in tiles:
		tile_save_datas.append(tile.get_save_data())
	#var my_id=main.multiplayer.get_unique_id()
	var target_id=-1
	while target_id<0 or target_id in main.dead_players:
		target_id= await player.get_selection(3)
		if target_id==null:
			_end_use()
			return
	#var send_targets=Game.players.keys().filter(func (peer_id:int)->bool:return peer_id not in main.dead_players and peer_id!=my_id)
	main.coop_notifications.add_spell_notification.rpc_id(target_id,id,{word=word_builder.get_words().words[0]})
	main.recive_word.rpc_id(target_id,tile_save_datas)
	await word_builder.word_holder.clear_tiles(Callable(),false)
	word_builder.update()
	await tile_board.settle_board()
	await tile_board.fill_board()
	_post_use()
	

func is_usable():
	return super.is_usable() and word_builder.can_submit() and word_builder.get_words().sub_lists.size()==1
