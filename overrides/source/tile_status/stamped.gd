extends "res://source/tile_status/default.gd"

var sprite_scene:PackedScene=load("res://mods/co-op/source/effects/mini_stamp_sprite.tscn")

var sprite:Sprite2D
var name:String

func _status_connect():
	sprite=sprite_scene.instantiate()
	tile.tile_sprite.add_child(sprite)

func clear():
	sprite.queue_free()

func get_save_data() -> Variant:
	return {
		frame=sprite.frame,
		pos=sprite.position,
		rotation=sprite.rotation,
		name=name
		}

func load_save_data(save: Variant) -> void:
	sprite.frame=save.frame
	sprite.position=Vector2(save.pos)
	sprite.rotation=save.rotation
	name=save.name

func get_tooltip_context():
	return {name=name}
