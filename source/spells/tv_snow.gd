extends Spell


func set_status_tooltips():
	status_tooltips = [TileStatus.FROZEN]

func _use():
	main.apply_status.rpc(TileStatus.FROZEN,2)
	_post_use()
