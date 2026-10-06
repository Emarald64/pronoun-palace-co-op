extends CoopSpell

var letter:=""
#var coop:CoOp=ModLoader.get_node("coop")

func set_status_tooltips():
	#status_tooltips = [{status = TileStatus.ENHANCED, plastic = true}]
	status_tooltips = [
		{status = TileStatus.CRIT},
		{status="timed", time=60, bomb=false}]

#func _init(_id: String):
	#super(_id)
	#coop.updated_extra_time.connect(set_status_tooltips.unbind(1))
	#coop.updated_extra_time.connect(frame_updated.emit.unbind(1))

func _use_old():
	const PARAMETERS={
		amount = 1, 
		type = TileType.DEFENSE, 
		effect_priority = [
			TileStatus.CRIT,
			[TileStatus.CANDY,TileStatus.FROZEN],
			[TileStatus.CAPITAL,TileStatus.PERIOD],
			TileEffect.SHIMMERING,
			TileEffect.TRIGRAM,
			TileEffect.BIGRAM,
			TileEffect.NEUTRAL,
			TileEffect.UNSPECIFIED,
			TileEffect.POSITIVE_FACE,
			[TileEffect.HARMFUL,TileEffect.FACE_UNMODIFIABLE,TileStatus.ENHANCED]
		], 
		has_face = true, 
	}
	main.apply_status.rpc(TileStatus.ENHANCED,PARAMETERS)
	main.coop_notifications.add_spell_notification.rpc(id)
	main.apply_status(TileStatus.ENHANCED,PARAMETERS.duplicate())
	
	_post_use()

func _use():
	main.coop_spell_effects.apply_tile_overlay.rpc("res://mods/co-op/source/effects/minute_of_hate_effect.tscn",{amount=1,effect_priority=EFFECT_PRIORITY.STATUS_ONLY},0.1,{letter=letter})
	main.coop_notifications.add_spell_notification.rpc(id,{letter=letter})
	await main.coop_spell_effects.apply_tile_overlay("res://mods/co-op/source/effects/minute_of_hate_effect.tscn",{amount=1,effect_priority=EFFECT_PRIORITY.STATUS_ONLY},0.1,{letter=letter})

	_post_use()

func get_tooltip_context():
	var context={}
	if not letter.is_empty():
		context.letter=letter
	return context

func get_frame() -> int:
	return 0

func get_hv_frames() -> Vector2i:
	return Vector2i(2,1)

func get_save_data():
	var save=super()
	save.letter=letter
	return save

func load_save_data(save):
	super(save)
	letter=save.letter

func player_turn_started(is_battle_start: bool) -> void :
	super(is_battle_start)
	if is_owned():
		# change applied letter
		letter=Letters.pick_from_pool(Letters.LETTERS,rng.spell)
		description_updated.emit()
