extends Main

var dead_players:Array[int]=[]
var players_compleated_floor:Array[int]=[]
var original_id:=0
var strawman_taps:Dictionary[int,int]
#var waiting_to_be_revived:=false
signal all_players_compleated_floor
#signal stop_dieing
signal player_died(id:int)
#signal peer_set_spells(success:bool)

var reviving:=false
var candy_round:=false

@onready var coop_notifications:CoopNotifications=%CoopNotifications
@onready var coop_spell_effects:CoopSpellEffects=$CoopSpellEffects

func _ready():
	super()
	Game.player_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.is_server():
		%FixDesync.forced_hidden=true
	coop_spell_effects.coop_notifications=coop_notifications

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		stop_waiting_for_death(true)
	
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
				stop_waiting_for_death()
			elif dead_players.size()+players_compleated_floor.size()+1>=Game.players.size():
				stop_waiting_for_death(true)
			if players_compleated_floor.size()>=Game.players.size()-1:
				all_players_compleated_floor.emit()

@rpc
func save_and_exit():
	if multiplayer.is_server():
		print_debug("asking other players to quit")
		save_and_exit.rpc()
		#await get_tree().create_timer(1).timeout
	if multiplayer.get_remote_sender_id()!=0:
		print_debug("asked by server to quit")
	#kill_peer()
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
	if dead_players.size()+players_compleated_floor.size()+1>=Game.players.size():
		if players_compleated_floor.is_empty():
			await super()
		else:
			stop_waiting_for_death(true)
		return
	elif enemy.id==Enemies.NOBODY:
		await super()
	elif dead_players.size()+1<Game.players.size():
		candy_round=true
		for tile in tile_board.get_tiles():
			tile.add_status(Globals.TileStatus.CANDY)
			await Game.timeout(0.1)
		start_player_action()

func stop_waiting_for_death(revive=false):
	if candy_round:
		if revive:
			is_player_turn=false
			candy_round=false
			#reviving=false
			player.is_defeated=false
			player.is_flinching=false
			player.is_dying=false
			tile_board.unlock_restock(true)
			await word_builder.remove_tiles()
			await word_builder.intent_container.clear_intents()
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
			super.player_death()

func start_enemy_turn():
	if not candy_round:
		await super()

@rpc("any_peer")
func peer_died():
	var id=multiplayer.get_remote_sender_id()
	print(id, "died")
	if id not in dead_players:
		dead_players.append(id)
		player_died.emit(id)
		if dead_players.size()==Game.players.size()-1:
			stop_waiting_for_death()
		word_builder.damage_indecators[id].set_dead(true)

@rpc("any_peer")
func log_compleated_floor():
	print(multiplayer.get_remote_sender_id()," compleated floor: ",act_events[0])
	players_compleated_floor.append(multiplayer.get_remote_sender_id())
	if players_compleated_floor.size()+dead_players.size()>=Game.players.size()-1:
		print("reviving")
		stop_waiting_for_death(true)
		await get_tree().process_frame
		reviving=false
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


func is_game_actionable(include_spell_select: = false, include_summary_continue: = false, include_tutorial: = false):
	return (not coop_spell_effects.in_coop_spell_animation or not include_spell_select) and super(include_spell_select,include_summary_continue,include_tutorial)

func load_save_data(run_save):
	super(run_save)
	#for mod in ModLoader.get_active_mods():
		#if mod.mod_data.id in mod_save_data:
			#mod.load_run_save_data(mod_save_data[mod.mod_data.id])
	if Game.sync_start:
		screen_wipe.uncover()
		Game.sync_start=false
	word_builder.resend_submitted.rpc()
	tile_board.settle_board(true)
	tile_board.fill_board(true)

func start_run():
	await super()
	var non_sync_rng=RNG.new()
	non_sync_rng.seed=rng.game.seed^(multiplayer.get_unique_id()-1)
	spell_select.rng.clown=load("res://mods/co-op/source/f#ed_up_clown_rng.gd").new()
	spell_select.reseed(non_sync_rng)
	rng.spell.reseed(non_sync_rng)
	tile_board.reseed(non_sync_rng)
	tile_board.pregenerate()
	for spell in spell_container.get_spells():
		spell.reseed(non_sync_rng)
	if original_id==0:
		original_id=multiplayer.get_unique_id()
	
	# add coop to the steam rich presence
	Bridge.set_rich_presence_key("character", "(co-op) - "+StringManager.get_string("character/" + player.id + "/title"))


func start_ending_player_turn(ignore_spell_use: bool = false, submit_word_builder_if_possible: = true) -> void:
	if not candy_round:
		await super(ignore_spell_use,submit_word_builder_if_possible)

func fix_desyncs():
	if enemy==null or enemy.id!=Enemies.NOBODY:
		merge_and_load_save.rpc({metadata=get_save_metadata(),data=get_save_data()})
		#dead_players.clear()
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
	
