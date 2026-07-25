extends "res://source/enemies/sprites/housebroken_sprite.gd"

func _touch():
	touch.rpc()

@rpc("any_peer","call_local","unreliable")
func touch():
	super._touch()
