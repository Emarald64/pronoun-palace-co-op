extends TileBoard

func _init():
	is_slid_out=true

func _ready():
	set_size(4,4,0,4,true,0)

func load_save_data(save):
	super(save)
	is_slid_out=false

func _settle_column(x, base_duration = 0.08, per_grid_duration = 0.16):
	pass

func fill_board(instant: = false, ignore_lock: = false):
	pass
