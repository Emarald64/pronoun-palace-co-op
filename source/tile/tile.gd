extends Tile

func _on_generate_tooltip(tooltip) -> void:
	var using_spell = player.get_using_spell()
	if using_spell==null or not using_spell.has_curse(CoOp.CURSES.SHIMMERING):
		super(tooltip)
	else:
		tooltip.hide()

func update_modulate():
	if (Game.player and Game.player.active_spell and Game.player.active_spell.has_curse(CoOp.CURSES.SHIMMERING)):
		modulate = Color.WHITE
	else:
		super()
