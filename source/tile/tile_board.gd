extends TileBoard

var getting_tiles_for_intents:=false

func _ready():
	#await get_tree().process_frame
	word_builder.updating_stats.connect(_on_start_updating_stats)
	word_builder.post_tile_stats.connect(_on_post_tile_stats)

func _add_tile_at(column, update = true, instant = false):
	#print("using custom add tile function")
	var queued_tile=queue.queue[Vector2i(column,0)]
	if main.enemy!=null and main.enemy.id==Enemies.NOBODY:
		var tile_coord = drop_from_coords(Vector2i(column, num_rows))
		if tile_coord.y in main.enemy.dooming_rows:
			var defense_chance: = float(Game.balance.defense_in_bag) / float(Game.balance.defense_in_bag + Game.balance.damage_in_bag)
			var defense_tile=Game.random.randf()<=defense_chance
			defense_bag.insert(Game.random.randi_range(0,defense_bag.size()),queued_tile.type)
			if defense_tile!=(queued_tile.type==TileType.DEFENSE):
				queued_tile.type=TileType.DEFENSE if defense_tile else TileType.DAMAGE
			if "statuses" in queued_tile and TileStatus.CRIT in queued_tile.statuses:
				queued_tile.statuses.erase(TileStatus.CRIT)
				crit_chance*=Game.player.get_crit_chance().DIVIDE_BY
	#if "faces" in queued_tile \
	#and (queued_tile.faces.is_empty() or queued_tile.faces[0]==" ") \
	#and ("statuses" not in queued_tile or queued_tile.statuses.any(func (status_id:String)->bool:
		#var status_flags=StringManager.get_string_at_path(["status",status_id,"flags"])
		#return "faceless" not in status_flags and "shared" not in status_flags)
	#):
		#if InputSanity.data_has_status(queued_tile,TileStatus.CAPITAL):
			#Letters.get_random_capital_letter(rng.bag)
		#elif InputSanity.data_has_status(queued_tile,TileStatus.PERIOD):
			#Letters.get_random_period_letter(rng.bag)
		#Letters.get_random_letter(get_letter_census(), rng.bag)
	super(column, update, instant)

func remove_tiles(tiles, parameters = {}):
	var phone_tiles=[]
	var own_tiles=[]
	for tile in tiles:
		if tile.tile_board!=self:
			phone_tiles.append(tile)
		else:
			own_tiles.append(tile)
	if not phone_tiles.is_empty():
		main.phone_board.remove_tiles(phone_tiles,parameters)
	await super(own_tiles,parameters)

func turn_end(reroll: = false, end_of_battle: = false):
	await super(reroll,end_of_battle)
	await main.phone_board.turn_end(false,end_of_battle)
	if not main.phone_board.is_slid_out:
		prepare_to_animate()
		var tween=create_tween()
		tween.tween_interval(.2)
		tween.tween_property(self,"position:x",240,.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.finished.connect(finish_animating)
		
		main.phone_board.prepare_to_animate()
		await main.phone_board.slide_out()
		main.phone_board.finish_animating()
		main.phone_board.remove_tiles(main.phone_board.get_tiles(),{ignore_status=true})

func update_tiles():
	super()
	main.phone_board.update_tiles()

func _on_start_updating_stats(_words):
	getting_tiles_for_intents=true

func _on_post_tile_stats(_words):
	getting_tiles_for_intents=false

func _get_matching_tile_info(parameters: Dictionary, tiles_only: bool) -> Array[Dictionary]:
	var tile_info=super(parameters,tiles_only)
	if getting_tiles_for_intents:
		tile_info.append_array(main.phone_board._get_matching_tile_info(parameters,tiles_only))
	return tile_info

func swap_tiles(tile_a: Tile, tile_b: Tile, settle_duration: = 0.08, settle_grid_duration: = 0.16) -> void:
	@warning_ignore("shadowed_variable_base_class")
	var swap_coords=tile_b.get_coord()
	var swap_board=tile_b.tile_board
	
	tile_a.tile_board.tile_map[tile_a.get_coord()]=tile_b
	tile_b.tile_board=tile_a.tile_board
	
	swap_board.tile_map[swap_coords]=tile_a
	tile_a.tile_board=swap_board
	
	tile_a.tween_to_board(tile_a.get_settle_duration(settle_duration, settle_grid_duration))
	tile_b.tween_to_board(tile_b.get_settle_duration(settle_duration, settle_grid_duration))

	await wait_for_idle_tiles()

	update_state()
	tiles_changed.emit()
