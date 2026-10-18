extends "res://source/spells/ctrl.gd"

func get_tiles(parameters: Dictionary = {}) -> Array[Tile]:
	return super(parameters)+main.phone_board.get_tiles(parameters.merged({rng=rng.tile}))
