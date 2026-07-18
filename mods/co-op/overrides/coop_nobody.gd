extends "res://source/enemies/nobody.gd"

const phone_pos=Vector2(113,140)

var swap_partner:int
var partnerless_players:Array[int]=[]

var recived_spell
var recived_board_piece:Dictionary={}
var has_recived_swap_info:=false

var last_move_tiles:Array=[]
var recived_phone_a_friend_data:Array=[]

var tile_copies=[]

signal recived_swap_info

# for solo attacks
var echo_tiles:=[]
#var damage_taken:=0


func _init():
	super()
	print("using co-op nobody")
	
	moves={
		swap_big={
			next="phone_a_friend_recive"
		},
		swap_small={
			next="phone_a_friend_send"
		},
		phone_a_friend_recive={
			cursed_num={
				0:2,
				1:3,
				2:4,
			},
			next="attack_big"
		},
		phone_a_friend_send={
			next="attack_small"
		},
		attack_big={
			damage={
				0:5,
				2:7,
				3:8,
				4:10
			},
			count={
				0:1,
				1:2,
				3:3
			},
			next="swap_small"
		},
		attack_small={
			damage={
				0:3,
				1:4,
				2:5,
				3:6
			},
			next="swap_big"
		},
		solo_a={
			next="solo_b",
			damage={
				0:4,
				1:5,
				2:6,
				3:7
			},
		},
		solo_b={
			#echo
			cursed={
				0:2,
				1:3,
				2:4,
			},
			next="solo_c"
		},
		solo_c={
			damage={
				0:6,
				1:7,
				3:8
			},
			reduce_by_per_player={
				0:1,
				1:2,
				2:3
			},
			next="solo_a"
		},
	}

func _ready():
	super()
	var ids:Array[int]= Game.players.keys()
	ids.sort()
	var player_num=ids.bsearch(multiplayer.get_unique_id())
	if player_num%2:
		swap_partner=ids[player_num-1]
		next_move="swap_small"
	else:
		if player_num==ids.size()-1:
			swap_partner=-1
			next_move="solo_a"
		else:
			swap_partner=ids[player_num+1]
			next_move="swap_big"
	
	main.player_died.connect(_on_player_died_or_dc)
	Game.player_disconnected.connect(_on_player_died_or_dc)

@rpc("any_peer")
func add_partnerless_player():
	var peer_id=multiplayer.get_remote_sender_id()
	partnerless_players.append(peer_id)
	if swap_partner==-1:
		ask_set_partner.rpc_id(peer_id,true)

@rpc("any_peer")
func ask_set_partner(first:bool):
	if swap_partner==-1:
		var peer_id=multiplayer.get_remote_sender_id()
		ask_set_partner.rpc_id(peer_id,false)
		swap_partner=peer_id
		if first:
			next_move="swap_big"
		else:
			next_move="swap_small"

func _on_player_died_or_dc(peer_id:int):
	if peer_id==swap_partner:
		print("swap partner died")
		swap_partner=-1
		add_partnerless_player.rpc()
		await wait_for_idle()
		await get_tree().process_frame
		#if next_move in ["swap_big","swap_small"]:
			#next_move="solo_a"
		#elif next_move in ["phone_a_friend_recive","phone_a_friend_send"]:
			#next_move="solo_b"
		update_intents()

func display_intent():
	match next_move:
		"swap_big":
			add_intent(Intent.EXPAND_BOARD, {size_x = 5, size_y = 4})
		"swap_small":
			add_intent(Intent.EXPAND_BOARD, {size_x = 5, size_y = 2})
		"phone_a_friend_recive":
			add_intent("phone_a_friend_recive", {partner=Game.players[swap_partner].name})
			add_intent("phone_a_friend_recive_cursed", {count=moves.phone_a_friend_recive.cursed_num,partner=Game.players[swap_partner].name})
			add_intent(Intent.PREPARING)
		"phone_a_friend_send":
			add_intent("phone_a_friend_send", {partner=Game.players[swap_partner].name})
			add_intent("phone_a_friend_send_cursed", {count=moves.phone_a_friend_recive.cursed_num, partner=Game.players[swap_partner].name})
		"attack_big":
			add_intent(Intent.ATTACK, {damage=moves.attack_big.damage, count=moves.attack_big.count})
		"attack_small":
			add_intent(Intent.ATTACK, {damage=moves.attack_small.damage})
		"solo_a":
			add_intent(Intent.ATTACK, {damage=moves.solo_a.damage})
		"solo_b":
			add_intent("echo")
			add_intent("echo_cursed", {count=moves.solo_b.cursed})
		"solo_c":
			add_intent(Intent.CONCENTRATION,{
				damage=get_multitude_attack_damage(),
				original_damage=moves.solo_c.damage,
				reduce_by = 1, 
				per_health = moves.solo_c.reduce_by_per_player*(Game.players.size()-main.dead_players.size()),
			})

func _get_health_scaling():
	return Enemies.NOBODY_HEALTH_SCALING[Globals.CHARACTERS.LEXICOGRAPHER]

@rpc("any_peer")
func recive_swap(swapped_spell:Dictionary,swapped_board_piece:Dictionary={}):
	recived_spell=swapped_spell
	recived_board_piece=swapped_board_piece
	has_recived_swap_info=true
	recived_swap_info.emit()

func get_board_part_to_swap()->Dictionary[Vector2i,Dictionary]:
	var tiles=get_tiles({
		rows=[2,3]
	})
	var save_data:Dictionary[Vector2i,Dictionary]={}
	for tile:Tile in tiles:
		save_data[tile.get_coord()]=tile.get_save_data()
	return save_data

func swap_big():
	await swap(true)

func swap_small():
	await swap(false)

func swap(big_board:bool):
	# revaluate partners
	
	#swap spells
	var spell_to_swap=main.spell_container.player_spells.pick_random()
	var swapping_board:bool=tile_board.num_columns==5
	recive_swap.rpc_id(swap_partner,spell_to_swap.spell.get_save_data(), get_board_part_to_swap() if swapping_board else {})
	if not has_recived_swap_info:
		await recived_swap_info
	await animate_attack()
	spell_to_swap.set_spell(Spell.create_from_save(recived_spell))
	recived_spell=null
	has_recived_swap_info=false
	
	@warning_ignore("incompatible_ternary")
	await tile_board.set_size(5, 4 if big_board else 2,null,null if recived_board_piece.is_empty() else 2)
	if not recived_board_piece.is_empty():
		AudioManager.play_sound(Sounds.PROLE_SERVICE.RING)
		await Game.timeout(1.2)
		num_projectiles=recived_board_piece.size()
		for cord in recived_board_piece:
			var tile=tile_board.create_tile()
			main.add_child(tile)
			tile.load_save_data(recived_board_piece[cord])
			tile.launch(phone_pos,tile_board.get_coord_position(cord),randf_range(80,100),cord)
			#projectile.impacted.disconnect(projectile.impacted.get_connections()[0].callable)
			tile.impacted.connect(_on_projectile_impacted)
			tile.impacted.connect(AudioManager.play_sound.bind(Sounds.PROLE_SERVICE.TONE))
			#projectile.impacted.connect(func ():
				#tile.is_projectile=false
				#tile_board.insert_tile(tile, cord,false)
			#)
			await Game.timeout(0.16)
		recived_board_piece.clear()
		await all_projectiles_impacted
		await tile_board.settle_board()
		await tile_board.set_size(5, 4 if big_board else 2,null,4)
	await wait_for_idle()
	
func _on_word_submitted(words: WordList, _damage: int, _ending_turn: bool) -> void:
	super(words,_damage,_ending_turn)
	if next_move=="phone_a_friend_send":
		echo_tiles=last_move_tiles
		last_move_tiles=[]
		tile_copies=[]
		for tile in word_builder.tiles:
			var save_data=tile.get_save_data()
			last_move_tiles.append(save_data)
			var tile_copy=tile_board.create_tile()
			main.add_child(tile_copy)
			tile_copy.global_position=tile.global_position
			tile_copy.load_save_data(save_data)
			tile_copies.append(tile_copy)
		
		await Game.timeout(.2)
		for tile_copy in tile_copies:
			var tween =get_tree().create_tween()
			tween.tween_property(tile_copy,"position",tile_copy.position+Vector2(0,30),.5)
	elif next_move == "solo_b":
		echo_tiles=last_move_tiles
		last_move_tiles=word_builder.tiles.map(func (tile:Tile):return tile.get_save_data())
@rpc("any_peer")
func recive_phone_a_friend_data(tiles:Array):
	print("phone a friend data: ",tiles)
	recived_phone_a_friend_data=tiles
	recived_swap_info.emit()

func phone_a_friend_send():
	recive_phone_a_friend_data.rpc_id(swap_partner,last_move_tiles)
	await animate_attack()
	for tile_copy in tile_copies:
		tile_copy.launch(tile_copy.global_position,phone_pos,randf_range(20,30))
		tile_copy.impacted.connect(_on_projectile_impacted)
		tile_copy.impacted.connect(AudioManager.play_sound.bind(Sounds.PROLE_SERVICE.TONE))
		await Game.timeout(.16)
	await all_projectiles_impacted
	await wait_for_idle()

func phone_a_friend_recive():
	if recived_phone_a_friend_data.is_empty():
		await recived_swap_info
	var recived_data_dupe=recived_phone_a_friend_data.duplicate()
	rng.move.shuffle(recived_data_dupe)
	for cursed_tile_data in recived_data_dupe.slice(0,moves.phone_a_friend_recive.cursed_num):
		cursed_tile_data.statuses=[Globals.TileStatus.CURSED]
	
	AudioManager.play_sound(Sounds.PROLE_SERVICE.RING)
	await Game.timeout(1.2)
	await animate_attack()
	for i in recived_phone_a_friend_data.size():
		var cord=Vector2i(i%5,3-(i/5))
		var tile=tile_board.create_tile()
		main.add_child(tile)
		tile.load_save_data(recived_phone_a_friend_data[i])
		tile.launch(phone_pos,tile_board.get_coord_position(cord),randf_range(80,100),cord)
		tile.impacted.connect(_on_projectile_impacted)
		tile.impacted.connect(AudioManager.play_sound.bind(Sounds.PROLE_SERVICE.TONE))
		await Game.timeout(0.16)
	recived_phone_a_friend_data.clear()
	await all_projectiles_impacted
	await wait_for_idle()

func attack_big():
	await animate_attack()
	for i in moves.attack_big.count:
		hit_player(moves.attack_big.damage, i==moves.attack_big.count-1)
		await Game.timeout(0.24)
	attack_check_for_missing_partner()
	await wait_for_idle()

func attack_small():
	await animate_attack()
	hit_player(moves.attack_small.damage)
	attack_check_for_missing_partner()
	await wait_for_idle()

func solo_a():
	await animate_attack()
	hit_player(moves.solo_a.damage)
	await wait_for_idle()

func solo_b():
	if echo_tiles.is_empty():
		var word=WordUtility.dictionary.pick_random_flag_word(WordDictionary.WordFlags.COMMON, 6, rng.move)
		for letter in word:
			echo_tiles.append({
				faces=[letter],
				type=randi_range(0,1)
			})
	var recived_data_dupe=echo_tiles.duplicate()
	rng.move.shuffle(recived_data_dupe)
	for cursed_tile_data in recived_data_dupe.slice(0,moves.solo_b.cursed):
		cursed_tile_data.statuses=[Globals.TileStatus.CURSED]
	
	AudioManager.play_sound(Sounds.PROLE_SERVICE.RING)
	await Game.timeout(1.2)
	await animate_attack()
	for i in echo_tiles.size():
		var cord=Vector2i(i%4,3-(i/4))
		var tile=tile_board.create_tile()
		main.add_child(tile)
		tile.load_save_data(echo_tiles[i])
		tile.launch(phone_pos,tile_board.get_coord_position(cord),randf_range(80,100),cord)
		tile.impacted.connect(_on_projectile_impacted)
		tile.impacted.connect(AudioManager.play_sound.bind(Sounds.PROLE_SERVICE.TONE))
		await Game.timeout(0.16)
	recived_phone_a_friend_data.clear()
	damage_taken=0
	await all_projectiles_impacted
	await wait_for_idle()

func get_multitude_damage_taken():
	var taken = damage_taken
	if not word_builder.is_submitting and main.is_player_turn:
		taken += word_builder.damage
	for peer_attack in word_builder.peer_attacks:
		taken+=peer_attack.damage

	return taken

func get_multitude_attack_damage():
	return max(0, moves.solo_c.damage - get_multitude_damage_taken()/(moves.solo_c.reduce_by_per_player*(Game.players.size()-main.dead_players.size())))

func solo_c():
	await animate_attack()
	hit_player(get_multitude_attack_damage())
	await wait_for_idle()
	if swap_partner!=-1:
		if swap_partner>multiplayer.get_remote_sender_id():
			next_move_override="swap_big"
		else:
			next_move_override="swap_small"

func attack_check_for_missing_partner():
	if swap_partner==-1:
		next_move_override="solo_a"

func flinch_lethal(amount: int):
	var player_id=player.id
	player.id=Globals.CHARACTERS.LEXICOGRAPHER
	super(amount)
	player.id=player_id
