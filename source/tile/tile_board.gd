extends TileBoard

func _add_tile_at(column, update = true, instant = false):
	#print("using custom add tile function")
	if main.enemy!=null and main.enemy.id==Enemies.NOBODY:
		var tile_coord = drop_from_coords(Vector2i(column, num_rows))
		if tile_coord.y in main.enemy.dooming_rows:
			var queued_tile=queue.queue[Vector2i(column,0)]
			var defense_chance: = float(Game.balance.defense_in_bag) / float(Game.balance.defense_in_bag + Game.balance.damage_in_bag)
			var defense_tile=Game.random.randf()<=defense_chance
			defense_bag.push_front(queued_tile.type)
			if defense_tile!=(queued_tile.type==TileType.DEFENSE):
				queued_tile.type=TileType.DEFENSE if defense_tile else TileType.DAMAGE
			if "statuses" in queued_tile and TileStatus.CRIT in queued_tile.statuses:
				queued_tile.statuses.erase(TileStatus.CRIT)
				crit_chance*=Game.player.get_crit_chance().DIVIDE_BY
	super(column, update, instant)
