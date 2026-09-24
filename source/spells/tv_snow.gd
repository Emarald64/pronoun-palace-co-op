extends Spell

var frame:=0

func _ready() -> void:
	frame=rng.spell.randi_range(0,1)
	frame_updated.emit()

func set_status_tooltips():
	status_tooltips = [TileStatus.FROZEN]

func _use():
	main.apply_tile_overlay.rpc(
		"res://mods/co-op/source/effects/tv_snow_effect.tscn",
		{amount=2,effect_priority=Globals.EFFECT_PRIORITY.SPELL.STATUS_ONLY}
	)
	main.coop_notifications.add_spell_notification.rpc(id)
	_post_use()
	if charge==0:
		frame=1

func add_charge(amount, instant = false, animate_sprite: = true):
	await super(amount,instant,animate_sprite)
	if charge==max_charge:
		frame=0

func get_hv_frames() -> Vector2i:
	return Vector2i(1,2)

func get_frame() -> int:
	return frame

func get_save_data():
	var save =super()
	save.frame=frame
	return save

func load_save_data(save):
	super(save)
	frame=save.frame

func post_generate_tooltip(tooltip:GameTooltip):
	var name_group=StringManager.get_string_group("mod/co-op/names")
	var credit:=""
	var group=get_string_group()
	if group.has_string("credit"):
		credit=group.get_string("credit")
	tooltip.add_subtooltip(name_group.strings.values().pick_random(),credit)

func do_battle_end_transformation():
	super()
	if secret_id in CoOp.GIFT_SPELLS:
		transform_spell(secret_id)

func player_turn_started(is_battle_start: bool) -> void :
	super(is_battle_start)
	if not is_battle_start and secret_id == CoOp.SPELLS.MIRACLE_CACHE_COOP:
		var spell_id=rng.spell.weighted_random(CoOp.SPELL_WEIGHTS)
		transform_spell(spell_id)
