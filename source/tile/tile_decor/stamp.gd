extends TileDecor

func get_layer() -> Layer:
	return Layer.TOP


func get_priority() -> int:
	return Callbacks.BASE_GAME_PRIORITY.THIRD
