extends Spell

var selecting_tile:=false

func _use():
	var player_id= await player.get_selection(3)
	if player_id==null:
		_end_use()
		return
	
	selecting_tile=true
	var tile: = await get_selection()
	selecting_tile=false
	
	if tile == null:
		_end_use()
		return

	AudioManager.play_sound(Sounds.SPELLS.STAMP_BIG)
	
	const stamp_poses=[
		#Vector2i(7,7),
		Vector2i(7,-7),
		Vector2i(-7,7),
		Vector2i(-7,-7),
	]
	var legal_tile=not tile.has_harmful_status() and not tile.has_any_status([TileStatus.HOLE,TileStatus.SCREW])
	var stamped_save={
		frame=4 if legal_tile else rng.spell.randi_range(0,2),
		rotation=maxi(rng.spell.randi_range(-4,3),0)*PI/2,
		pos=rng.spell.pick_random(stamp_poses)+Vector2i(rng.spell.randi_range(-1,1),rng.spell.randi_range(-1,1)),
		name=Game.player_info.name
	}
	#var tile_coord=tile.get_coord()
	#var mailing_tile=legal_tile or tile.has_effect("stamped")
	#if mailing_tile:
	var tile_save=tile.get_save_data()
	tile_save.get_or_add("statuses",[]).append("stamped")
	tile_save.get_or_add("status_data",{}).stamped=stamped_save
	tile_save.as_save=true
	main.queue_tile.rpc_id(player_id,tile_save)
	
	tile_board.remove_tile(tile,{delete_tiles = false,ignore_status=true})
	const target_offset=Vector2(15,-25)
	var projectile_target=player_spell_slot.global_position+target_offset
	var projectile=tile.launch(tile.global_position,projectile_target,48, Vector2i.MIN, 1200, true, false, false)
	tile.rotation+=PI/2
	projectile.look_at_direction = false
	projectile.angular_velocity = PI 
	projectile.angular_deceleration = PI * 18
	projectile.decelerate_to = PI/4
	
	await projectile.impacted
	
	projectile.remove_child(tile)
	player_spell_slot.add_child(tile)
	tile.position=target_offset
	
	#var had_stamp=tile.has_status("stamped")
	#if not had_stamp:
	AudioManager.play_sound(Sounds.SPELLS.STAMP)
	tile.bounce()
	tile.load_status("stamped",stamped_save)
	_post_use()
	#if not had_stamp:
	await Game.timeout(1)
	#else:
		#await Game.timeout(.5)
	var tween=tile.create_tween()
	AudioManager.play_sound(Sounds.GENERIC.BOARD_OUT,1.0,.75)
	tween.tween_property(tile,"position",target_offset+Vector2(0,41),0.2)
	await tween.finished
	tile.queue_free()
	#else:
		#await Game.timeout(1)
		#tile.launch(tile.global_position,tile_board.get_coord_position(tile_coord),180,tile_coord)
		#_post_use()
	

#func is_tile_selectable(tile: Tile) -> bool:
	#return not tile.has_harmful_status()


func get_tooltip_context():
	return {selecting_tile=selecting_tile}

func post_generate_tooltip(tooltip:GameTooltip):
	var group=StringManager.get_string_group("mod/co-op/names")
	tooltip.add_subtooltip(group.strings.values().pick_random())
