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
