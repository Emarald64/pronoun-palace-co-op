extends "res://source/enemies/bammon.gd"

func animate_flinch_lethal():
	await super()
	tile_board.remove_tiles(tile_board.tile_map.values())
