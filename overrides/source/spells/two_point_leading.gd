extends "res://source/spells/two_point_leading.gd"

func get_selection(exclude_tiles = []) -> Tile:
	return await super(exclude_tiles+main.phone_board.tile_map.values())
