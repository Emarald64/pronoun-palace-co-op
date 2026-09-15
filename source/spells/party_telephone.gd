extends Spell


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
	main.recive_word.rpc_id(target_id,tile_save_datas)
	_post_use()
	await word_builder.word_holder.clear_tiles(Callable(),false)
	word_builder.update()
	await tile_board.settle_board()
	tile_board.fill_board()
	

func is_usable():
	return super.is_usable() and word_builder.can_submit()

func post_generate_tooltip(tooltip:GameTooltip):
	var group=StringManager.get_string_group("mod/co-op/names")
	tooltip.add_subtooltip(group.strings.values().pick_random(),"sprite by dragonslayr15001")
	

func do_battle_end_transformation():
	super()
	if secret_id in ModLoader.get_node("coop").namespace_ids(CoOp.GIFT_SPELLS):
		transform_spell(secret_id)

func player_turn_started(is_battle_start: bool) -> void :
	super(is_battle_start)
	if secret_id == ModLoader.get_node("coop").namespace_id(CoOp.SPELLS.MIRACLE_CACHE_COOP):
		var pool=ModLoader.get_node("coop").namespace_dictionary_ids(CoOp.SPELL_WEIGHTS)
		var spell_id=rng.spell.pick_random(pool)
		transform_spell(spell_id)
