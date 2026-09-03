extends "res://source/enemies/bottom_feeder.gd"


func suck_tile(tile: Tile):
	tile.disable_shadow()
	await tile.tween_position(tile_marker.global_position, 0.35)

	uneaten_tiles -= 1
	tile.hide()

	if uneaten_tiles == 0:
		anim_player.play("swallow_final")
	elif anim_player.current_animation == "swallow":
		anim_player.seek(0)
	else:
		anim_player.play("swallow")

	await anim_player.animation_finished

	if uneaten_tiles == 0:
		finished_eating.emit()
	else:
		anim_player.play("suck")
