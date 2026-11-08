extends "res://source/tile_status/default.gd"

var sprite_scene:PackedScene=load("res://mods/co-op/source/effects/mini_stamp_sprite.tscn")

var stamp:TileDecor
var name:String
var stamp_frame:int
var stamp_position:Vector2
var stamp_rotation:float

func setup_tile() -> void:
	stamp = tile_sprite.add_decoration(CoOp.TILE_DECOR.STAMP)


func update_decor() -> void:
	stamp.sprite.frame = stamp_frame
	stamp.sprite.position = stamp_position
	stamp.sprite.rotation = stamp_rotation


func cleanup_tile():
	stamp.remove()

func get_save_data() -> Variant:
	return {
		frame=stamp_frame,
		pos=stamp_position,
		rotation=stamp_rotation,
		name=name
		}

func load_save_data(save: Variant) -> void:
	stamp_frame=save.frame
	stamp_position=Vector2(save.pos)
	stamp_rotation=save.rotation
	name=save.name

func get_tooltip_context():
	return {name=name,illegal=stamp_frame==4}
