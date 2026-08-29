extends Spell

var frame:=0

func _ready() -> void:
	frame=rng.spell.randi_range(1,2)
	frame_updated.emit()

func set_status_tooltips():
	status_tooltips = [TileStatus.FROZEN]

func _use():
	main.apply_tile_effect.rpc("res://mods/co-op/source/effects/tv_snow_effect.tscn",2)
	_post_use()
	if charge==0:
		frame=1

func add_charge(amount, instant = false, animate_sprite: = true):
	await super(amount,instant,animate_sprite)
	if charge==max_charge:
		frame=0

func get_hv_frames() -> Vector2i:
	return Vector2i(1,2)

func get_frame() -> int:
	return frame

func get_save_data():
	var save =super()
	save.frame=frame
	return save

func load_save_data(save):
	super(save)
	frame=save.frame
