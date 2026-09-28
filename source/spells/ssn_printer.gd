extends CoopSpell

var last_ssn:=0
var frame:=-1

func _use():
	var condition=func (peer_id:int)->bool:
		return Game.players[peer_id].steam_id!=last_ssn or Game.players.size()<=2
	var selected_player= await player.get_selection(CoOp.PEER_SELECTION_TYPE,condition)
	if selected_player==null:
		_end_use()
		return
	
	var steam_id=Game.players[selected_player].steam_id#76561198172774482
	
	transform_spell(CoOp.SPELLS.PRINTED_SSN,true,true,false,false,true,
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

func get_save_data():
	var save=super()
	save.last_ssn=last_ssn
	save.frame=frame
	return save

func load_save_data(save):
	super(save)
	last_ssn=save.last_ssn
	frame=save.frame
