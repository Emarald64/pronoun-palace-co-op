extends Spell

var letter:=""

func set_status_tooltips():
	#status_tooltips = [{status = TileStatus.ENHANCED, plastic = true}]
	status_tooltips = [{status = TileStatus.BOMB, bomb_turns = 1},{status="timed", time=120, bomb=true}]


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
	main.apply_tile_overlay.rpc("res://mods/co-op/source/effects/minute_of_hate_effect.tscn",{amount=1,effect_priority=EFFECT_PRIORITY.STATUS_ONLY},0.1,{letter=letter})
	main.coop_notifications.add_spell_notification.rpc(id,{letter=letter})
	await main.apply_tile_overlay("res://mods/co-op/source/effects/minute_of_hate_effect.tscn",{amount=1,effect_priority=EFFECT_PRIORITY.STATUS_ONLY},0.1,{letter=letter})

	_post_use()

func get_texture(spell_id: String = spell_data.get_base_id()) -> Texture2D:
	return load("res://arte/ui/achievements/missing.png")

func get_tooltip_context():
	return {letter=letter}

func post_generate_tooltip(tooltip:GameTooltip):
	var group=StringManager.get_string_group("mod/co-op/names")
	tooltip.add_subtooltip(group.strings.values().pick_random())

func do_battle_end_transformation():
	super()
	if secret_id in CoOp.GIFT_SPELLS:
		transform_spell(secret_id)

func player_turn_started(is_battle_start: bool) -> void :
	super(is_battle_start)
	if not is_battle_start and secret_id == CoOp.SPELLS.MIRACLE_CACHE_COOP:
		var spell_id=rng.spell.weighted_random(CoOp.SPELL_WEIGHTS)
		transform_spell(spell_id)
	elif is_owned():
		# change applied letter
		letter=Letters.pick_from_pool(Letters.LETTERS,rng.spell,{min_weight=3.0})
		description_updated.emit()
