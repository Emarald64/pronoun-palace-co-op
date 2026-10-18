extends "res://source/spells/backspace.gd"

func get_selection(exclude_tiles = []) -> Tile:
	return await super(exclude_tiles+main.phone_board.tile_map.values())
