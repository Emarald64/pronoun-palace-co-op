extends Spell

var selecting_tile:=false

func _use():
	var player_id= await player.get_selection(3)
	if player_id==null:
		_end_use()
		return
	
	var tile: = await get_selection()

	if tile == null:
		_end_use()
		return

	AudioManager.play_sound(Sounds.SPELLS.STAMP_BIG)
	
	main.queue_tile.rpc_id(player_id,tile.get_save_data())
	tile_board.remove_tile(tile,{delete_tiles = false})
	var projectile=tile.launch(tile.global_position,player_spell_slot.global_position,48, Vector2i.MIN, 1200, true, false, false)
	projectile.look_at_direction = false
	projectile.angular_velocity = PI * 10
	projectile.angular_deceleration = PI * 18
	projectile.decelerate_to = PI * 2
	
	_post_use()

func is_tile_selectable(tile: Tile) -> bool:
	return not tile.has_harmful_status()


func get_tooltip_context():
	return {selecting_tile=selecting_tile}
