extends Main

var dead_players:Array[int]=[]
var players_compleated_floor:Array[int]=[]
#var waiting_to_be_revived:=false
signal all_players_compleated_floor
signal stop_dieing
signal player_died(id:int)
var reviving:=false
var candy_round:=false

func _ready():
	super()
	Game.player_disconnected.connect(_on_peer_disconnected)

func start_battle(skipping_transition = false):
	super(skipping_transition)
	enemy.max_health*=Game.players.size()
	enemy.health=enemy.max_health

func _on_peer_disconnected(id:int):
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

func save_and_exit():
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	super()

func player_death():
	#await stop_dieing
	#if dead_players.size()==Game.players.size()-1:
		#await super()
	#else:
	#player.is_dead=false
	#player.hide_sprite_on_death=false
	peer_died.rpc()
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
		await word_builder.remove_tiles()
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
	dead_players.append(id)
	player_died.emit(id)
	if dead_players.size()==Game.players.size()-1:
		stop_dieing.emit()
	word_builder.damage_indecators[id].set_dead(true)

@rpc("any_peer")
func log_compleated_floor():
	print("player compleated floor")
	players_compleated_floor.append(multiplayer.get_remote_sender_id())
	if players_compleated_floor.size()+dead_players.size()>=Game.players.size()-1:
		reviving=true
		stop_dieing.emit()
	if players_compleated_floor.size()>=Game.players.size()-1:
		all_players_compleated_floor.emit()

func increment_floor():
	## wait for all players to finish floor before continuing
	log_compleated_floor.rpc()
	if players_compleated_floor.size()<Game.players.size()-1:
		await all_players_compleated_floor
	for id in dead_players:
		word_builder.damage_indecators[id].set_dead(false)
	player.sprite.show()
	dead_players.clear()
	players_compleated_floor.clear()
	await super()

func spawn_enemy(enemy_name):
	if enemy_name==Enemies.NOBODY:
		super("res://mods/co-op/overrides/coop_nobody.tscn")
	else:
		super(enemy_name)

@rpc("any_peer")
func recive_word(tiles:Array)->void:
	var width=tile_board.num_columns
	var height=tile_board.num_rows
	for i in height*width:
		var tile=tile_board.get_tile_at(Vector2i(i%width,height-(i/width)-1))
		if not tile.in_word():
			tile.load_save_data(tiles.pop_front())
