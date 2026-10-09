@tool
extends "res://source/enemies/sprites/strawman_sprite.gd"

func _touch():
	Game.main.strawman_taps+=1
	touch.rpc()

@rpc("any_peer","call_local","unreliable")
func touch():
	super._touch()
