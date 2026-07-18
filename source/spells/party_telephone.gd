extends Spell


func set_status_tooltips():
	status_tooltips = [TileStatus.DEFAULT]


func _use():
	var tiles=word_builder.tiles
	var tile_save_datas:=[]
	for tile:Tile in tiles:
		tile_save_datas.append(tile.get_save_data())
	tile_board.remove_tiles(tiles)
	var my_id=main.multiplayer.get_unique_id()
	var send_targets=Game.players.keys().filter(func (peer_id:int)->bool:return peer_id not in main.dead_players and peer_id!=my_id)
	main.recive_word.rpc_id(rng.spell.pick_random(send_targets))

func is_usable():
	return super.is_usable() and word_builder.can_submit()
