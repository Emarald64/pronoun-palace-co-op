extends "res://source/enemies/enemy_data/nobody_data.gd"

func instantiate_scene() -> Enemy:
	return load("res://mods/co-op/source/enemies/nobody.tscn").instantiate()
