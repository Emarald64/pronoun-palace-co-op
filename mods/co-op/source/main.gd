extends Main

var dead_players:Array[int]=[]
var players_compleated_floor:Array[int]=[]
var allow_set_spells:=false
#var waiting_to_be_revived:=false
signal all_players_compleated_floor
signal stop_dieing
signal player_died(id:int)
signal peer_set_spells

var reviving:=false
var candy_round:=false

func _init():
	super()
	print_debug("set main scene on game")

func _ready():
	super()
	Game.player_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.is_server():
		%FixDesync.forced_hidden=true

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		reviving=true
		stop_dieing.emit()
	
	if Input.is_key_pressed(KEY_P):
		all_players_compleated_floor.emit()

func start_battle(skipping_transition = false):
	super(skipping_transition)
	enemy.max_health*=Game.players.size()
	enemy.health=enemy.max_health

func _on_peer_disconnected(id:int):
	print(id," disconnected")
	if id==1:
		save_and_exit()
	else:
		if id in dead_players:
			dead_players.erase(id)
		elif id in players_compleated_floor:
			players_compleated_floor.erase(id)
		else:
			if dead_players.size()+1>=Game.players.size():
				stop_dieing.emit()
			elif dead_players.size()+players_compleated_floor.size()+1>=Game.players.size():
				reviving=true
				stop_dieing.emit()
			if players_compleated_floor.size()>=Game.players.size()-1:
				all_players_compleated_floor.emit()

@rpc
func save_and_exit():
	if multiplayer.is_server():
		print_debug("asking other players to quit")
		save_and_exit.rpc()
		await get_tree().create_timer(1).timeout
	if multiplayer.get_remote_sender_id()!=0:
		print_debug("asked by server to quit")
	kill_peer()
	await super()

func player_death():
	#await stop_dieing
	#if dead_players.size()==Game.players.size()-1:
		#await super()
	#else:
	#player.is_dead=false
	#player.hide_sprite_on_death=false
	peer_died.rpc()
	word_builder.submitted_count=0
	print("I died")
	tile_board.clear_targets()
	if dead_players.size()+players_compleated_floor.size()>=Game.players.size()-1:
		reviving=true
	elif dead_players.size()<=Game.players.size()-1 and enemy.id!=Enemies.NOBODY:
		for tile in tile_board.get_tiles():
			tile.add_status(Globals.TileStatus.CANDY)
			await Game.timeout(0.1)
		candy_round=true
		is_player_turn=true
		await stop_dieing
	if reviving:
		is_player_turn=false
		candy_round=false
		reviving=false
		player.is_defeated=false
		player.is_flinching=false
		player.is_dying=false
		tile_board.unlock_restock(true)
		await word_builder.remove_tiles()
		word_builder.submitted_count=0
		word_builder.update()
		player.heal(maxi(word_builder.heighest_candy_round_value,1))
		word_builder.heighest_candy_round_value=0
		tile_board.reroll_board()
		player.sprite.show()
		is_player_turn=true
		player.anim_player.clear_queue()
		player.anim_player.play("idle")
		player.health_bar.appear()
		end_battle()
	else:
		super()

func start_enemy_turn():
	if not candy_round:
		await super()

@rpc("any_peer")
func peer_died():
	var id=multiplayer.get_remote_sender_id()
	print(id, "died")
	dead_players.append(id)
	player_died.emit(id)
	if dead_players.size()==Game.players.size()-1:
		stop_dieing.emit()
	word_builder.damage_indecators[id].set_dead(true)

@rpc("any_peer")
func log_compleated_floor():
	print(multiplayer.get_remote_sender_id()," compleated floor: ",act_events[0])
	players_compleated_floor.append(multiplayer.get_remote_sender_id())
	if players_compleated_floor.size()+dead_players.size()>=Game.players.size()-1:
		print("reviving")
		reviving=true
		stop_dieing.emit()
	if players_compleated_floor.size()>=Game.players.size()-1:
		print("all players compleated floor")
		all_players_compleated_floor.emit()

func increment_floor():
	## wait for all players to finish floor before continuing
	log_compleated_floor.rpc()
	if players_compleated_floor.size()<Game.players.size()-1:
		print("waiting for other players to compleate floor")
		await all_players_compleated_floor
	for id in dead_players:
		word_builder.damage_indecators[id].set_dead(false)
		word_builder.damage_indecators[id].hide()
	player.sprite.show()
	dead_players.clear()
	players_compleated_floor.clear()
	print("incrementing floor")
	await super()

func spawn_enemy(enemy_name):
	if enemy_name==Enemies.NOBODY:
		var enemy_scene=load("res://mods/co-op/source/enemies/nobody_coop.tscn")
		enemy = enemy_scene.instantiate()

		Game.enemy = enemy
		last_enemy_id = enemy.id

		enemy.action_finished.connect(_on_enemy_action_finished)
		enemy_marker.add_child(enemy)
		enemy_info_bar.set_battle_unit(enemy)
		enemy.set_intent_container( %EnemyIntentContainer)
	else:
		super(enemy_name)

		
@rpc("any_peer")
func recive_word(tiles:Array)->void:
	print(tiles)
	var width=tile_board.num_columns
	var height=tile_board.num_rows
	for i in height*width:
		var cord:=Vector2i(i%width,height-(i/width)-1)
		var tile=tile_board.get_tile_at(cord)
		if tile==null:
			var tile_data =tiles.pop_front()
			if tile_data==null:
				break
			tile=tile_board.create_tile()
			
			tile_board.insert_tile(tile,cord)
			tile.load_save_data(tile_data)
			tile.add_poofcloud(tile.get_poof_color())
			await get_tree().create_timer(0.16).timeout
		elif not tile.in_word():
			var tile_data =tiles.pop_front()
			if tile_data==null:
				break
			tile.load_save_data(tile_data)
			tile.add_poofcloud(tile.get_poof_color())
			await get_tree().create_timer(0.16).timeout

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
	

func kill_peer():
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	if Game.upnp!=null:
		Game.upnp.delete_port_mapping(multiplayer.multiplayer_peer.host.get_local_port())
	Game.players.clear()

func finish_run(is_victory: = false):
	await super(is_victory)
	kill_peer()

@rpc("any_peer")
func request_set_spells():
	set_spells.rpc_id(multiplayer.get_remote_sender_id(),spell_container.get_save_data())

@rpc("any_peer")
func set_spells(spells:Array):
	if allow_set_spells:
		for player_spell in spell_container.player_spells:
			player_spell.queue_free()
		spell_container.player_spells.clear()
		spell_container.position_spells()
		spell_container.load_save_data(spells)
		for player_spell in spell_container.player_spells:
			player_spell.spell_paper.gain()
		peer_set_spells.emit()

@rpc("any_peer")
func set_spell_and_send_data(spell:Dictionary,recive_index:int,reply_index=null):
	if reply_index!=null:
		set_spell_and_send_data.rpc_id(multiplayer.get_remote_sender_id(),spell_container.player_spells[recive_index].spell.get_save_data(),reply_index)
	spell_container.player_spells[recive_index].set_spell(Spell.create_from_save(spell))
	spell_container.player_spells[recive_index].spell_paper.gain()

@rpc("any_peer")
func queue_tile(tile_data:Dictionary):
	var queued_tile:Dictionary=rng.mod.pick_random(tile_board.get_preview_tiles())
	queued_tile.assign(tile_data)
	tile_board.update_previews()

@rpc("any_peer")
func apply_status(status,count:=1):
	var parameters={amount=count,exclude_effects=[Status.TileStatus.CRIT]}
	if word_builder.is_submitting:
		parameters["exlcude_tiles"]=word_builder.tiles
	var tiles:=tile_board.get_tiles(parameters)
	for tile in tiles:
		tile.add_status(status)
		tile.add_poofcloud(tile.get_poof_color())
		await Game.timeout(0.1)

func load_save_data(run_save):
	super(run_save)
	if Game.sync_start:
		screen_wipe.uncover()
		Game.sync_start=false
	word_builder.resend_submitted.rpc()

func start_run():
	await super()
	var non_sync_rng=RNG.new()
	non_sync_rng.seed=rng.game.seed^multiplayer.get_unique_id()
	spell_select.reseed(non_sync_rng)
	rng.spell.seed^=multiplayer.get_unique_id()

func start_ending_player_turn(ignore_spell_use: bool = false, submit_word_builder_if_possible: = true) -> void:
	if not candy_round:
		await super(ignore_spell_use,submit_word_builder_if_possible)

func fix_desyncs():
	merge_and_load_save.rpc({metadata=get_save_metadata(),data=get_save_data()})
	dead_players.clear()
	players_compleated_floor.clear()
	candy_round=false
	word_builder.peer_attacks.clear()
	word_builder.submitted_count=0

@rpc
func merge_and_load_save(host_save:Dictionary):
	Game.loading_run_save=Game.merge_saves(host_save,{metadata=get_save_metadata(),data=get_save_data()})
	#screen_wipe.wipe_in()
	#await screen_wipe.screen_covered
	Game.sync_start=true
	get_tree().change_scene_to_file("res://mods/co-op/source/Purgatory.tscn")
	
