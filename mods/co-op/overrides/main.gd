extends Main

var dead_players:Array[int]=[]
var players_compleated_floor:Array[int]=[]
signal all_players_compleated_floor
signal stop_dieing

func start_battle(skipping_transition = false):
	super(skipping_transition)
	enemy.max_health*=Game.players.size()
	enemy.health=enemy.max_health

func save_and_exit():
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	super()

func player_death():
	#await stop_dieing
	#if dead_players.size()==Game.players.size()-1:
		#await super()
	#else:
	#player.is_dead=false
	player.is_defeated=false
	player.is_flinching=false
	player.is_dying=false
	player.health=10
	player.anim_player.clear_queue()
	player.anim_player.stop()
	player.health_bar.appear()

@rpc("any_peer")
func player_died():
	dead_players.append(multiplayer.get_remote_sender_id())
	if dead_players.size()==Game.players.size()-1:
		stop_dieing.emit(true)

@rpc("any_peer")
func log_compleated_floor():
	players_compleated_floor.append(multiplayer.get_remote_sender_id())
	if players_compleated_floor.size()>=Game.players.size()-1:
		all_players_compleated_floor.emit()

func increment_floor():
	## wait for all players to finish floor before continuing
	log_compleated_floor.rpc()
	if players_compleated_floor.size()<Game.players.size()-1:
		await all_players_compleated_floor
	players_compleated_floor.clear()
	await super()

func spawn_enemy(enemy_name):
	if enemy_name==Enemies.NOBODY:
		super("res://mods/co-op/overrides/coop_nobody.tscn")
	else:
		super(enemy_name)
