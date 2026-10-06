extends BugSpray

func _use():
	main.force_allow_select_player=true
	var selection = await player.get_selection(Player.Selection.TILE,
		func (current_selection)->bool:
			if current_selection is Tile:
				return true
			elif current_selection is int:
				return Game.is_playtester(current_selection)
			return false
	)
	main.force_allow_select_player=false

	if selection == null:
		_end_use()
		return

	if selection is Tile:
		await spray_tile(selection)
	elif selection is int:
		main.coop_spell_effects.damage_player.rpc_id(selection)

	_post_use()

func get_texture(_spell_id: String = spell_data.get_base_id()) -> Texture2D:
	return load("res://arte/spells/bug_spray.png")
