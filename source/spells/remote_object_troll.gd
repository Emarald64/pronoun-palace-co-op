extends CoopSpell

var selecting_spell:=false

func _use():
	# display other player's spells
	var spell_to_send:Spell=await player.get_selection(Player.Selection.SPELL)
	if spell_to_send==null:
		_end_use()
		return
	var sending_spell_index:=spell_container.player_spells.find(spell_to_send.player_spell_slot)
	
	var old_spells:=spell_container.get_spells()
	selecting_spell=false
	var peer_id:int
	#if get_meta("imaginary_shadow",false):
		#peer_id=rng.spell.pick_random(Game.players.keys())
	#else:
	peer_id = await player.get_selection(CoOp.PEER_SELECTION_TYPE)
	if peer_id==null:
		_end_use()
		return
	
	var new_spell_index:=0
	
	if not Input.is_key_pressed(KEY_SHIFT):
		
		coop_spell_effects.using_remote_object=true
		
		#make spell charge decays not cause errors
		for spell in old_spells:
			var charge_decay:SpellChargeDecay=spell.get("spell_charge_decay")
			if charge_decay:
				charge_decay.timer.stopped.disconnect(charge_decay._on_timer_stopped)
		
		coop_spell_effects.request_set_spells.rpc_id(peer_id)
		#player_spell_slot.get_tree().create_timer(10).timeout.connect(main.peer_set_spells.emit.bind(false))
		@warning_ignore("confusable_local_declaration")
		var timeout_result=await wait_for_reply_with_timeout()
		#main.allow_set_spells=false
		if not timeout_result:
			coop_notifications.add_spell_notification(id,{failed=true},peer_id)
			restore_spells(old_spells)
			push_warning("remote object request set spells failed")
			coop_spell_effects.using_remote_object=false
			_end_use()
			return
		
		
		selecting_spell=true
		update_banner_label()
		main.spell_container.player_spells[0].set_spell(self)
		var condition = func(spell): return not spell.spell_data.character_specific and spell.is_owned()
		var new_spell:Spell = await player.get_selection(Player.Selection.SPELL,condition)
		selecting_spell=false
		if new_spell == null:
			remove_all_player_spells()
			restore_spells(old_spells)
			coop_spell_effects.using_remote_object=false
			_end_use()
			return
			
		new_spell_index=spell_container.player_spells.find(new_spell.player_spell_slot)

	var sending_save_data=spell_to_send.get_save_data()
	if spell_to_send==self:
		sending_save_data.charge-=1
		sending_save_data.laced_deactivated=true
		if has_curse(CURSE.FRAGILE) and rng.fragile.randf() <= FRAGILE_BREAK_CHANCE:
			sending_save_data.max_charge=maxi(0,max_charge)
	remove_all_player_spells()
	coop_spell_effects.set_spell_and_send_data.rpc_id(peer_id,sending_save_data,new_spell_index,sending_spell_index)
	restore_spells(old_spells)
	var timeout_result= await wait_for_reply_with_timeout()
	coop_spell_effects.using_remote_object=false
	if timeout_result:
		_trigger_use_completed(false)
	else:
		coop_notifications.add_spell_notification(id,{failed=true},peer_id)
	if spell_to_send==self:
		_end_use()
	else:
		_post_use()


func restore_spells(spells:Array[Spell]):
	for spell in spells:
		spell_container.add_spell(spell)
		var charge_decay:SpellChargeDecay=spell.get("spell_charge_decay")
		if charge_decay:
			charge_decay.timer.stopped.connect(charge_decay._on_timer_stopped)

func get_tooltip_context():
	return {selecting_spell=selecting_spell}

func remove_all_player_spells():
	for player_spell in spell_container.player_spells:
		player_spell.queue_free()
	spell_container.player_spells.clear()

func get_texture(_spell_id: String = spell_data.get_base_id()) -> Texture2D:
	return load("res://mods/co-op/arte/spells/remote_object.png")
