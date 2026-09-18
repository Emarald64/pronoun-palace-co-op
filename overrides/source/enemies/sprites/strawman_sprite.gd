@tool
extends "res://source/enemies/sprites/strawman_sprite.gd"

func _touch():
	touch.rpc()

@rpc("any_peer","call_local","unreliable")
func touch():
	if multiplayer.get_remote_sender_id() in Game.main.strawman_taps:
		Game.main.strawman_taps[multiplayer.get_remote_sender_id()]+=1
	else:
		Game.main.strawman_taps[multiplayer.get_remote_sender_id()]=1
	super._touch()
