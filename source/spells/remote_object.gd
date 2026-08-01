extends Spell

var selecting_spell:=false

func _use():
	# display other player's spells
	var my_index:=spell_container.player_spells.find(player_spell_slot)
	var old_spells_save_data=spell_container.get_save_data()
	selecting_spell=false
	var peer_id = await player.get_selection(3)
	if peer_id==null:
		_end_use()
		return

	main.request_set_spells.rpc_id(peer_id)
	await main.peer_set_spells
	
	
	selecting_spell=true
	update_banner_label()
	main.spell_container.player_spells[0].set_spell(self)
	var condition = func(spell): return not spell.spell_data.character_specific and spell.is_owned()
	var new_spell:Spell = await player.get_selection(Player.Selection.SPELL,condition)
	selecting_spell=false
	if new_spell == null:
		remove_all_player_spells()
		spell_container.load_save_data(old_spells_save_data)
		_end_use()
		return
		
	var new_spell_index:=main.spell_container.player_spells.find(new_spell.player_spell_slot)
	#var new_spell_save_data=new_spell.get_save_data()
	#player_spell_slot.set_spell(new_spell)
	remove_all_player_spells()
	
	var my_save_data=get_save_data()
	my_save_data.charge-=1
	main.set_spell_and_send_data.rpc_id(peer_id,my_save_data,new_spell_index,my_index)
	
	remove_all_player_spells()
	spell_container.load_save_data(old_spells_save_data)
	_end_use()


func get_tooltip_context():
	return {selecting_spell=selecting_spell}

func remove_all_player_spells():
	for player_spell in spell_container.player_spells:
		player_spell.queue_free()
	spell_container.player_spells.clear()
