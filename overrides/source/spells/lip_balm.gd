extends "res://source/spells/lip_balm.gd"

func get_selection(exclude_tiles = []) -> Tile:
	return await super(exclude_tiles+main.phone_board.tile_map.values())
