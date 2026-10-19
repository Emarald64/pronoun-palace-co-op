extends TileBoard

var include_phone_board_tiles:=false
var ripped:=false

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
	#include_phone_board_tiles=true
	await super(reroll,end_of_battle)
	#include_phone_board_tiles=false
	if not main.phone_board.is_slid_out:
		await main.phone_board.turn_end(false,end_of_battle)

func update_tiles():
	super()
	main.phone_board.update_tiles()

func _on_start_updating_stats(_words):
	include_phone_board_tiles=true

func _on_post_tile_stats(_words):
	include_phone_board_tiles=false

func _get_matching_tile_info(parameters: Dictionary, tiles_only: bool) -> Array[Dictionary]:
	var tile_info=super(parameters,tiles_only)
	if include_phone_board_tiles:
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

	#await wait_for_idle_tiles()
	await swap_board.wait_for_idle_tiles()
	await tile_b.tile_board.wait_for_idle_tiles()

	update_state()
	tiles_changed.emit()

func get_tile_box_size():
	if ripped:
		return super()+Vector2(0,7)
	else:
		return super()

func get_total_size():
	if ripped:
		return super()-Vector2(0,10)
	else:
		return super()

func get_target_global_position():
	if ripped:
		return super()+Vector2(0,-47)
	else:
		return super()

func get_save_data():
	var save=super()
	save.ripped=ripped
	return save

func get_tile_state_save_data(include_restock_depth: = false):
	var save=super(include_restock_depth)
	save.ripped=ripped
	return save

func load_tile_state_save_data(save, parent_to_mask: = false, needs_reset: = true):
	set_ripped(save.ripped)
	await super(save,parent_to_mask,needs_reset)

func reset_board():
	set_ripped(false)
	super()

func set_ripped(is_ripped:=true):
	ripped=is_ripped
	if is_ripped:
		board.texture=load("res://mods/co-op/arte/ui/ripped_board.png")
		board.region_rect=Rect2()
		board.patch_margin_left=6
		board.patch_margin_right=6
		board.patch_margin_top=2
		board.patch_margin_bottom=12
		
		tile_box.texture=load("res://mods/co-op/arte/ui/ripped_inside_board.png")
		tile_box.region_rect=Rect2()
		tile_box.patch_margin_bottom=6
		tile_box.patch_margin_left=2
		tile_box.patch_margin_right=2
		
		main.turn_timer.position.y=-47
	else:
		board.texture=load("res://arte/ui/tile_board.png")
		tile_box.texture=load("res://arte/ui/insideboard.png")
		main.turn_timer.position.y=-71
