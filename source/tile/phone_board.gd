extends TileBoard

func _init():
	is_slid_out=true

func _ready():
	set_size(4,4,0,4,true,0)

func load_save_data(save):
	super(save)
	is_slid_out=false

func _settle_column(_x, _base_duration = 0.08, _per_grid_duration = 0.16):
	pass

func fill_board(_instant: = false, _ignore_lock: = false):
	pass

func create_tile() -> Tile:
	var tile=super()
	tile.tile_board=self
	return tile

func turn_end(reroll: = false, end_of_battle: = false):
	await super(reroll,end_of_battle)

	main.tile_board.prepare_to_animate()
	var tween=main.tile_board.create_tween()
	tween.tween_interval(.2)
	tween.tween_property(main.tile_board,"position:x",240,.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.finished.connect(main.tile_board.finish_animating)
	
	prepare_to_animate()
	await slide_out()
	finish_animating()
	remove_tiles(get_tiles(),{ignore_status=true,settle=false,fill=false})
