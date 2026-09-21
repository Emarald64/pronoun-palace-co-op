extends Spell

var last_ssn:=0
var frame:=-1

func _use():
	var condition=func (peer_id:int)->bool:
		return Game.players[peer_id].steam_id!=last_ssn or Game.players.size()<=2
	var selected_player= await player.get_selection(3,condition)
	if selected_player==null:
		_end_use()
		return
	
	var steam_id=Game.players[selected_player].steam_id#76561198172774482
	
	transform_spell("co-op:printed_ssn",true,true,false,false,true,
		func (ssn:SSNSpell):
			ssn.steam_id=steam_id
			ssn.printer_charge_character=charge_character
			ssn._setup_ssn(steam_id)
	)
	
	_post_use()

func _first_spawn(is_transform: = false) -> void:
	super(is_transform)
	if frame==-1:
		frame=rng.spell.randi_range(0,2)

func get_hv_frames() -> Vector2i:
	return Vector2i(3, 1)

func get_frame() -> int:
	return frame

func post_generate_tooltip(tooltip:GameTooltip):
	var name_group=StringManager.get_string_group("mod/co-op/names")
	var credit:=""
	var group=get_string_group()
	if group.has_string("credit"):
		credit=group.get_string("credit")
	tooltip.add_subtooltip(name_group.strings.values().pick_random(),credit)

func do_battle_end_transformation():
	super()
	if secret_id in ModLoader.get_node("coop").namespace_ids(CoOp.GIFT_SPELLS):
		transform_spell(secret_id)

func player_turn_started(is_battle_start: bool) -> void :
	super(is_battle_start)
	if not is_battle_start and secret_id == ModLoader.get_node("coop").namespace_id(CoOp.SPELLS.MIRACLE_CACHE_COOP):
		var pool=ModLoader.get_node("coop").namespace_dictionary_ids(CoOp.SPELL_WEIGHTS)
		var spell_id=rng.spell.pick_random(pool)
		transform_spell(spell_id)
