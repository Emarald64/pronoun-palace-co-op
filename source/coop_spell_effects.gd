class_name CoopSpellEffects
extends Node

signal request_replied(sucess:bool)
signal all_projectiles_impacted

var using_remote_object:=false
var in_coop_spell_animation:=false
#var projectile_count:=0

var tile_board:TileBoard=Game.tile_board
var main:Main=Game.main
var word_builder = Game.word_builder 
var spell_container: SpellContainer
var coop_notifications:CoopNotifications

func _ready():
	await Game.main_scene_loaded
	spell_container = Game.spell_container

#func projectile_impacted():
	#projectile_count-=1
	#if projectile_count<=0:
		#all_projectiles_impacted.emit()

@rpc("any_peer")
func recive_word(tiles:Array)->void:
	#print(tiles)
	in_coop_spell_animation=true
	var phone_board:TileBoard=main.phone_board
	var need_to_move_main_board=phone_board.is_slid_out
	if not phone_board.is_slid_out:
		await word_builder.remove_tiles()
		phone_board.prepare_to_animate()
		await phone_board.slide_out()
		phone_board.finish_animating()
	var width=phone_board.num_columns
	var height=phone_board.num_rows
	#var offset=((tiles.size()-1)/4)+1
	for i in mini(height*width,tiles.size()):
		var coord=Vector2i(i%width,height-(i/width)-1)
		var existing_tile=phone_board.get_tile_at(coord)
		var tile_data =tiles[i]
		if existing_tile==null or not existing_tile.in_word():
			InputSanity.process_tile_data(tile_data)
			var new_tile=phone_board.create_tile()
			main.add_child(new_tile)
			new_tile.load_save_data(tile_data)
			var tile=phone_board.insert_tile(new_tile,coord,false)
			tile.tile_board=phone_board
	
	if need_to_move_main_board:
		# move main tile board to the left
		main.tile_board.prepare_to_animate()
		var tween=create_tween()
		tween.tween_property(main.tile_board,"position:x",180,.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.finished.connect(main.tile_board.finish_animating)
		await get_tree().create_timer(.1).timeout
	phone_board.prepare_to_animate()
	await phone_board.slide_in()
	await phone_board.wait_for_idle()
	phone_board.finish_animating()
	in_coop_spell_animation=false

@rpc("any_peer")
func blue_box_effect(rng_seed:int):
	var random=RNG.new()
	random.seed=rng_seed
	var valid_spells=spell_container.player_spells.filter(
		func (player_spell:PlayerSpell)->bool:
			return player_spell.spell.charge<player_spell.spell.max_charge)
	if not valid_spells.is_empty():
		var spell:Spell=random.pick_random(valid_spells).spell
		spell.add_charge(1)
		coop_notifications.add_spell_notification(CoOp.SPELLS.BLUE_BOX,{spell=spell.get_spell_name()})
	else:
		coop_notifications.add_spell_notification(CoOp.SPELLS.BLUE_BOX)

@rpc("any_peer")
func request_set_spells():
	if using_remote_object:
		push_warning(Game.players[multiplayer.get_remote_sender_id()]," tried to use remote object on me while I was already using it")
		failed_request.rpc_id(multiplayer.get_remote_sender_id(),"tried to use remote object while the other player was using remote object")
	else:
		set_spells.rpc_id(multiplayer.get_remote_sender_id(),main.spell_container.get_save_data())

@rpc("any_peer")
func set_spells(spells:Array):
	#if not success:
		#request_replied.emit(false)
		#push_warning("tried to use remote object while the ",Game.players[multiplayer.get_remote_sender_id()]," was using remote object")
		#return
	if using_remote_object:
		for player_spell in spell_container.player_spells:
			player_spell.queue_free()
		spell_container.player_spells.clear()
		spell_container.position_spells()
		for spell in spells:
			InputSanity.process_spell_data(spell)
		spell_container.load_save_data(spells)
		for player_spell in spell_container.player_spells:
			player_spell.spell_paper.gain()
		request_replied.emit(true)

@rpc("any_peer")
func set_spell_and_send_data(spell:Dictionary,recive_index:int,reply_index=null):
	if reply_index!=null:
		set_spell_and_send_data.rpc_id(multiplayer.get_remote_sender_id(),spell_container.player_spells[recive_index].spell.get_save_data(),reply_index)
	InputSanity.process_spell_data(spell)
	spell_container.player_spells[recive_index].set_spell(Spell.create_from_save(spell))
	spell_container.player_spells[recive_index].spell_paper.gain()

@rpc("any_peer")
func queue_tile(tile_data:Dictionary):
	var queued_tile:Dictionary=main.rng.mod.pick_random(tile_board.get_preview_tiles())
	InputSanity.process_tile_data(tile_data)
	queued_tile.assign(tile_data)
	tile_board.update_previews()

const default_tile_parameters={amount=1,effect_priority=Globals.EFFECT_PRIORITY.SPELL.STATUS_ONLY}

@rpc("any_peer")
func apply_status(status,search_parameters:Dictionary={},delay:=0.1):
	in_coop_spell_animation=true
	search_parameters.merge(default_tile_parameters)
	if word_builder.is_submitting:
		search_parameters["in_word"]=false
	var tiles:=tile_board.get_tiles(search_parameters)
	for tile in tiles:
		tile.add_status(status)
		tile.add_poofcloud(tile.get_poof_color())
		await Game.timeout(delay)
	in_coop_spell_animation=false

var allowed_overlays=[
	"res://mods/co-op/source/effects/tv_snow_effect.tscn",
	"res://mods/co-op/source/effects/minute_of_hate_effect.tscn",
]

@rpc("any_peer")
func apply_tile_overlay(path:String,search_parameters:Dictionary={},delay:=0.1,overlay_parameters=null):
	if path not in allowed_overlays:
		push_error(Game.all_player_names[multiplayer.get_remote_sender_id()],"tried to apply an invalid effect: ",path)
		return
	in_coop_spell_animation=true
	await tile_board.wait_for_idle()
	search_parameters.merge(default_tile_parameters)
	#var parameters={amount=count,effect_priority=Globals.EFFECT_PRIORITY.SPELL.STATUS_ONLY}
	if word_builder.is_submitting:
		search_parameters["in_word"]=false
	var tiles:=tile_board.get_tiles(search_parameters)
	var effect_scene:PackedScene=load(path)
	for tile in tiles:
		var effect=effect_scene.instantiate()
		if effect.has_method("set_parameters"):
			effect.set_parameters(overlay_parameters)
		tile.add_child(effect)
		await Game.timeout(delay)
	in_coop_spell_animation=false

@rpc("any_peer")
func swap_board(board_data:Dictionary,reply:bool):
	if main.is_player_turn:
		in_coop_spell_animation=true
		var sender_id=multiplayer.get_remote_sender_id()
		if reply:
			var tile_state=tile_board.get_tile_state_save_data()
			tile_state.size.preview_rows=null
			swap_board.rpc_id(sender_id,tile_state,false)
		else:
			request_replied.emit(true)
		await word_builder.remove_tiles()
		await tile_board.wait_for_idle_tiles()
		if reply:
			coop_notifications.add_spell_notification("co-op:sneakernet",{success=true},sender_id)
		await tile_board.slide_out()
		if randf()<.1:
			tile_board.load_tile_state_save_data(board_data)
			await tile_board.slide_in()
			get_tree().create_timer(0.3).timeout.connect(AudioManager.play_sound.bind(Sounds.BRUTALIST.RETREAT))
			await tile_board.settle_board()
		else:
			tile_board.load_tile_state_save_data(board_data,true)
			await tile_board.slide_in()
		in_coop_spell_animation=false
	else:
		failed_request.rpc_id(multiplayer.get_remote_sender_id(),"tried to swap board when it wasn't the other player's turn")

@rpc("any_peer")
func damage_player(amount:=1):
	in_coop_spell_animation=true
	main.player.hurt(amount)
	await main.player.recompose()
	in_coop_spell_animation=false

@rpc("any_peer")
func failed_request(reason:String):
	push_warning(reason)
	request_replied.emit(false)
