extends "res://source/enemies/nobody.gd"

const PHONE_POS=Vector2(113,140)

var swap_partner:int
var partnerless_players:Array[int]=[]

var recived_board_piece:Dictionary={}

var dooming_rows:Array[int]

var last_move_tiles:Array=[]
var recived_phone_a_friend_data:Array=[]
var regular_board:=true

var tile_copies=[]

signal recived_spell_data
signal recived_swap_info

# for solo attacks
var echo_tiles:=[]
var given_word:String

func _init():
	super()
	moves={
		swap={ 
			first_damage={
				0:3,
				1:4,
				2:5,
				3:6
			}
		},
		swap_big={
			second_damage={
				0:2,
				2:3,
				3:4,
				4:6
			},
			next="phone_a_friend_recive"
		},
		swap_small={
			second_damage={
				0:5,
				1:6,
				2:8,
			},
			next="phone_a_friend_send"
		},
		phone_a_friend_recive={
			cursed_num={
				0:3,
				1:4,
				2:6,
				3:10
			},
			next="attack_big"
		},
		phone_a_friend_send={
			damage={
				0:2,
				1:3
			},
			next="attack_small"
		},
		attack_big={
			damage={
				0:5,
				1:6,
				2:7,
				4:11
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
				0:2,
				1:3,
				2:4,
				3:6
			},
			next="swap_big"
		},
		solo_a={
			next="solo_c",
			damage={
				0:4,
				1:5,
				2:6,
				3:7
			},
		},
		solo_b={
			#echo
			cursed_num={
				0:3,
				1:4,
				2:6,
				3:10
			},
			next="solo_a"
		},
		solo_c={
			# npcs like attack
			damage={
				0:6,
				1:7,
				3:8
			},
			reduce_by_per_player={
				0:3,
				2:4
			},
			next="solo_b"
		},
		fishing = {
			cursed_odds = { # copied from the fisher nobody fight
				0: 0.25, 
				1: 0.33, 
			}
		}, 
	}

func _init_rng():
	super()
	rng.spell_swap=RNG.new()

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
			next_move="solo_c"
		else:
			swap_partner=ids[player_num+1]
			next_move="swap_big"
	
	main.player_died.connect(_on_player_died_or_dc)
	Game.player_disconnected.connect(_on_player_died_or_dc)
	
	word_builder.peer_attack_updated.connect(func (_id:int,submitted:bool):
		if (main.is_player_turn or word_builder.waiting_for_peers_to_submit) and not submitted and next_move=="solo_c":
			update_intents()
		)
	
	var smoke_extention=ColorRect.new()
	var smoke=get_tree().get_first_node_in_group(&"nobody_office_chunk").get_node("SmokeViewport/SmokeMarker2D")
	smoke.add_child(smoke_extention)
	smoke_extention.size=Vector2(1000,100)
	smoke_extention.position.y=-100
	smoke_extention.z_index=2

@rpc("any_peer")
func add_partnerless_player():
	var peer_id=multiplayer.get_remote_sender_id()
	partnerless_players.append(peer_id)
	if swap_partner==-1:
		ask_set_partner.rpc_id(peer_id)

@rpc("any_peer")
func ask_set_partner():
	if swap_partner==-1:
		var peer_id=multiplayer.get_remote_sender_id()
		ask_set_partner.rpc_id(peer_id)
		swap_partner=peer_id
		#const solo_moves=["solo_c","solo_b","solo_a"]
		#var partner_moves
		#if first:
			#partner_moves=["swap_big","phone_a_friend_recive","attack_big"]
		#else:
			#partner_moves=["swap_small","phone_a_friend_send","attack_small"]
		#next_move=partner_moves[solo_moves.find(next_move)]

func _on_player_died_or_dc(peer_id:int):
	if peer_id==swap_partner:
		print("swap partner died")
		swap_partner=-1
		add_partnerless_player.rpc()
		regular_board=true
		await wait_for_idle()
		await get_tree().process_frame
		#await tile_board.set_size()
		if next_move in ["swap_big","swap_small"]:
			next_move="solo_c"
		elif next_move in ["phone_a_friend_recive","phone_a_friend_send"]:
			next_move="solo_b"
		else:
			next_move="solo_a"
		update_intents()

func display_intent():
	match next_move:
		"swap_big":
			add_intent(Intent.EXPAND_BOARD, {size_x = 4, size_y = 5})
			add_intent(Intent.ATTACK, {damage=(moves.swap.first_damage if regular_board else moves.swap_big.second_damage)})
			add_intent("spell_swap")
		"swap_small":
			add_intent(Intent.EXPAND_BOARD, {size_x = 2, size_y = 5})
			add_intent(Intent.ATTACK, {damage=(moves.swap.first_damage if regular_board else moves.swap_small.second_damage)})
			add_intent("spell_swap")
		"phone_a_friend_recive":
			add_intent("phone_a_friend_recive", {partner=Game.players[swap_partner].name})
			add_intent(Intent.APPLY_STATUS, {name_override="phone_a_friend_recive_cursed",description_override="phone_a_friend_recive_cursed",count=moves.phone_a_friend_recive.cursed_num,status=TileStatus.CURSED})
			add_intent(Intent.PREPARING)
		"phone_a_friend_send":
			add_intent("phone_a_friend_send", {partner=Game.players[swap_partner].name})
			add_intent(Intent.APPLY_STATUS, {name_override="phone_a_friend_send_cursed",description_override="phone_a_friend_send_cursed",count=moves.phone_a_friend_recive.cursed_num,status=TileStatus.CURSED})
			add_intent(Intent.ATTACK, {damage=moves.phone_a_friend_send.damage})
		"attack_big":
			add_intent(Intent.ATTACK, {damage=moves.attack_big.damage, count=moves.attack_big.count})
		"attack_small":
			add_intent(Intent.ATTACK, {damage=moves.attack_small.damage})
		"solo_a":
			add_intent(Intent.ATTACK, {damage=moves.solo_a.damage})
			if tile_board.num_columns!=4:
				add_intent(Intent.SHRINK_BOARD, {size_x = 4, size_y = 4})
		"solo_b":
			add_intent("echo",{first_time=echo_tiles.is_empty()})
			#add_intent("echo_cursed", {count=moves.solo_b.cursed,status=TileStatus.CURSED})
			add_intent(Intent.APPLY_STATUS, {name_override="echo_cursed",description_override="echo_cursed",count=moves.solo_b.cursed_num,status=TileStatus.CURSED})
			if tile_board.num_columns!=4:
				add_intent(Intent.SHRINK_BOARD, {size_x = 4, size_y = 4})
		"solo_c":
			add_intent(Intent.CONCENTRATION,{
				damage=get_multitude_attack_damage(),
				original_damage=moves.solo_c.damage,
				reduce_by = 1, 
				per_health = moves.solo_c.reduce_by_per_player*(Game.players.size()-main.dead_players.size()),
			})
			if Game.players.size()>main.dead_players.size()+1:
				add_intent("spell_swap")
			if tile_board.num_columns!=4:
				add_intent(Intent.SHRINK_BOARD, {size_x = 4, size_y = 4})

func _get_health_scaling():
	return [65, 75, 85, 100]

@rpc("any_peer")
func recive_board(swapped_board_piece:Dictionary={}):
	recived_board_piece=swapped_board_piece
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
	await send_spell()
	var swapping_board:bool=tile_board.num_columns==5
	if regular_board:
		hit_player(moves.swap.first_damage)
	else:
		hit_player(moves.swap_big.second_damage)
	if recived_board_piece.is_empty() and swapping_board:
		get_tree().create_timer(10).timeout.connect(recived_swap_info.emit)
		await recived_swap_info
	
	if not recived_board_piece.is_empty():
		await tile_board.set_size(5, 4,null,0)
		AudioManager.play_sound(Sounds.PROLE_SERVICE.RING)
		await Game.timeout(1.2)
		num_projectiles=recived_board_piece.size()
		for cord in recived_board_piece:
			var tile=tile_board.create_tile()
			main.add_child(tile)
			tile.load_save_data(recived_board_piece[cord])
			tile.launch(PHONE_POS,tile_board.get_coord_position(cord),randf_range(80,100))
			tile.impacted.connect(tile_board.insert_tile.bind(tile,cord,false))
			tile.impacted.connect(_on_projectile_impacted)
			tile.impacted.connect(AudioManager.play_sound.bind(Sounds.PROLE_SERVICE.TONE))

			await Game.timeout(0.16)
		recived_board_piece.clear()
		await all_projectiles_impacted
		await tile_board.settle_board()
	await tile_board.set_size(5, 4)
	var smoke=get_tree().get_first_node_in_group(&"nobody_office_chunk").get_node("SmokeViewport/SmokeMarker2D")
	smoke.create_tween().set_ease(Tween.EASE_IN_OUT).tween_property(smoke,"position",Vector2(-128,0),5)
	regular_board=false
	await wait_for_idle()

func swap_small():
	var swapping_board:bool=tile_board.num_columns==5
	if swapping_board:
		recive_board.rpc_id(swap_partner, get_board_part_to_swap())
	await send_spell()
	if regular_board:
		hit_player(moves.swap.first_damage)
	else:
		hit_player(moves.swap_small.second_damage)
	await tile_board.set_size(5,2)
	dooming_rows.clear()
	regular_board=false
	var smoke=get_tree().get_first_node_in_group(&"nobody_office_chunk").get_node("SmokeViewport/SmokeMarker2D")
	smoke.create_tween().set_ease(Tween.EASE_IN_OUT).tween_property(smoke,"position",Vector2(-128,50),5)
	await wait_for_idle()

var sending_spell_data:Dictionary
signal sending_spell_data_set
var recived_spell_save:Dictionary

@rpc("any_peer")
func recive_spell(swapped_spell:Dictionary):
	#await Game.timeout(randf_range(1,5))
	print("recived ",swapped_spell.id," from ",multiplayer.get_remote_sender_id())
	recived_spell_save=swapped_spell
	recived_spell_data.emit()

@rpc("any_peer")
func ask_send_spell():
	print("asked to send spell to ",multiplayer.get_remote_sender_id())
	if sending_spell_data.is_empty():
		print("waiting to determine which spell to send")
		await sending_spell_data_set
	recive_spell.rpc_id(multiplayer.get_remote_sender_id(),sending_spell_data)


func send_spell():
	var spells=main.spell_container.player_spells
	var spell_to_swap
	if spells.size()>1:
		if player.id==Globals.CHARACTERS.CHILD:
			
			var defense_spell=null
			var direct_defense_spells=SpellData.get_spell_pool(Globals.SPELL_CATEGORY.DIRECT_DEFENSE).keys()
			for spell:PlayerSpell in spells:
				if spell.spell.id in direct_defense_spells:
					if defense_spell==null:
						defense_spell=spell
					else:
						# more than 1 direct deffense spell, dont protect
						defense_spell=null
						break
			if defense_spell!=null:
				spells.erase(defense_spell)

		spell_to_swap=rng.move.pick_random(spells.filter(func (player_spell:PlayerSpell)->bool:return not player_spell.spell.spell_data.character_specific))
	else:
		spell_to_swap=spells[0]
	sending_spell_data=spell_to_swap.spell.get_save_data()
	sending_spell_data_set.emit()
	var potential_spell_recivers:Array=Game.players.keys().filter(func (player_id)->bool:return player_id not in main.dead_players)
	potential_spell_recivers.sort()
	rng.spell_swap.shuffle(potential_spell_recivers)
	var my_pos_in_recivers=potential_spell_recivers.find(multiplayer.get_unique_id())
	#var spell_reciver=potential_spell_recivers[(my_pos_in_recivers+1)%potential_spell_recivers.size()]
	var spell_sender=potential_spell_recivers[posmod((my_pos_in_recivers-1),potential_spell_recivers.size())]
	print("sending:",sending_spell_data.id,". requesting from ",spell_sender)
	ask_send_spell.rpc_id(spell_sender)
	#recive_spell.rpc_id(spell_reciver,sent_spell)
	if recived_spell_save.is_empty():
		get_tree().create_timer(10).timeout.connect(recived_spell_data.emit)
		await recived_spell_data
	#var new_spell_data=
	await animate_attack()
	if not recived_spell_save.is_empty():
		spell_to_swap.set_spell(Spell.create_from_save(recived_spell_save))
	else:
		push_error("did not recive a spell from ",spell_sender," name:",Game.players[spell_sender].name)
	get_tree().create_timer(10).timeout.connect(func ():sending_spell_data.clear())
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
			tile_copy.create_tween().set_ease(Tween.EASE_IN_OUT).tween_property(tile_copy,"position",tile_copy.position+Vector2(0,30),.5)
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
	hit_player(moves.phone_a_friend_send.damage)
	for tile_copy in tile_copies:
		tile_copy.launch(tile_copy.global_position,PHONE_POS,randf_range(20,30))
		tile_copy.impacted.connect(_on_projectile_impacted)
		tile_copy.impacted.connect(AudioManager.play_sound.bind(Sounds.PROLE_SERVICE.TONE))
		await Game.timeout(.16)
	await all_projectiles_impacted
	if last_move_tiles.size()<moves.phone_a_friend_recive.cursed_num:
		var cursed_tiles=get_tiles({
			amount = moves.phone_a_friend_recive.cursed_num-last_move_tiles.size(), 
			effect_priority = EFFECT_PRIORITY.STATUS_ONLY, 
		})
		for tile in cursed_tiles:
			tile.add_status(TileStatus.CURSED)
			tile.add_poofcloud(tile.get_color())
			await Game.timeout(.1)
	await wait_for_idle()

func phone_a_friend_recive():
	if recived_phone_a_friend_data.is_empty():
		get_tree().create_timer(10).timeout.connect(recived_swap_info.emit)
		await recived_swap_info
	if recived_phone_a_friend_data.is_empty():
		var word=WordUtility.dictionary.pick_random_flag_word(WordDictionary.WordFlags.COMMON, 6, rng.move)
		for letter in word:
			recived_phone_a_friend_data.append({
				faces=[letter],
				type=tile_board.pop_from_bag()
			})
	var cursed_tiles=recived_phone_a_friend_data.duplicate()
	rng.move.shuffle(cursed_tiles)
	cursed_tiles.sort_custom(func (a:Dictionary,b:Dictionary)->bool:
		return get_effect_priority(a.get("statuses",[]))>get_effect_priority(b.get("statuses",[]))
	)
	for tile_data in cursed_tiles.slice(0,moves.phone_a_friend_recive.cursed_num):
		if "statuses" in tile_data:
			tile_data.statuses.append(TileStatus.CURSED)
		else:
			tile_data.statuses=[TileStatus.CURSED]
	
	#hit_player(moves.phone_a_friend_recive.damage)
	AudioManager.play_sound(Sounds.PROLE_SERVICE.RING)
	await Game.timeout(1.2)
	await animate_attack()
	for i in recived_phone_a_friend_data.size():
		var cord=Vector2i(i%5,3-(i/5))
		var tile=tile_board.create_tile()
		main.add_child(tile)
		tile.load_save_data(recived_phone_a_friend_data[i])
		#if tile in cursed_tiles:
			#tile.add_status(Globals.TileStatus.CURSED)
		tile.launch(PHONE_POS,tile_board.get_coord_position(cord),randf_range(80,100),cord)
		tile.impacted.connect(_on_projectile_impacted)
		tile.impacted.connect(AudioManager.play_sound.bind(Sounds.PROLE_SERVICE.TONE))
		await Game.timeout(0.16)
	recived_phone_a_friend_data.clear()
	await all_projectiles_impacted
	await wait_for_idle()

static func get_effect_priority(tile_effects,priority_list: Array=Globals.EFFECT_PRIORITY.ENEMY.STATUS_ONLY) -> int:
	if tile_effects==null:
		return 999
	for priority in range(priority_list.size() - 1, -1, -1):
		var effect = priority_list[priority]
		if effect is Array:
			if effect.any(func (x:String)->bool:return x in tile_effects):
				return priority + 1
		elif effect in tile_effects:
			return priority + 1
	return 999

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
	if tile_board.num_columns!=4:
		await tile_board.set_size()
		regular_board=true
	await wait_for_idle()

func solo_b():
	#echo
	if echo_tiles.is_empty():
		given_word=WordUtility.dictionary.pick_random_flag_word(WordDictionary.WordFlags.COMMON, 6, rng.move)
		for letter in given_word:
			echo_tiles.append({
				faces=[letter],
				type=tile_board.pop_from_bag()
			})
	var cursed_tiles=echo_tiles.duplicate()
	rng.move.shuffle(cursed_tiles)
	cursed_tiles.sort_custom(func (a,b)->bool:
		return get_effect_priority(a.get("statuses",[]))>get_effect_priority(b.get("statuses",[]))
	)
	for tile_data in cursed_tiles.slice(0,moves.solo_b.cursed_num):
		if "statuses" in tile_data:
			tile_data.statuses.append(TileStatus.CURSED)
		else:
			tile_data.statuses=[TileStatus.CURSED]
	
	AudioManager.play_sound(Sounds.PROLE_SERVICE.RING)
	await Game.timeout(1.2)
	await animate_attack()
	if tile_board.num_columns!=4:
		await tile_board.set_size()
		regular_board=true
	for i in echo_tiles.size():
		var cord=Vector2i(i%4,3-(i/4))
		var tile=tile_board.create_tile()
		main.add_child(tile)
		tile.load_save_data(echo_tiles[i])
		tile.launch(PHONE_POS,tile_board.get_coord_position(cord),randf_range(80,100),cord)
		tile.impacted.connect(_on_projectile_impacted)
		tile.impacted.connect(AudioManager.play_sound.bind(Sounds.PROLE_SERVICE.TONE))
		await Game.timeout(0.16)
	#recived_phone_a_friend_data.clear()
	damage_taken=0
	await all_projectiles_impacted
	await wait_for_idle()

func get_multitude_damage_taken():
	var taken = damage_taken
	if main.is_player_turn or word_builder.waiting_for_peers_to_submit:
		taken += word_builder.damage
	for peer_id:int in word_builder.peer_attacks:
		taken+=word_builder.peer_attacks[peer_id].damage

	return taken

func get_multitude_attack_damage():
	return max(0, moves.solo_c.damage - get_multitude_damage_taken()/(moves.solo_c.reduce_by_per_player*(Game.players.size()-main.dead_players.size())))

func solo_c():
	if Game.players.size()<=main.dead_players.size()+1:
		await animate_attack()
	else:
		await send_spell()
	if get_multitude_attack_damage()>0:
		#await animate_attack()
		hit_player(get_multitude_attack_damage())
		await wait_for_idle()
		if swap_partner!=-1:
			if swap_partner>multiplayer.get_unique_id():
				next_move_override="swap_big"
			else:
				next_move_override="swap_small"
	else:
		if tile_board.num_columns!=4:
			#await animate_attack()
			await tile_board.set_size()
			regular_board=true
		await wait_for_idle()
		await Game.timeout(0.5)

func attack_check_for_missing_partner():
	if swap_partner==-1:
		next_move_override="solo_a"

func flinch_lethal(amount: int):
	var player_id=player.id
	player.id=Globals.CHARACTERS.LEXICOGRAPHER
	super(amount)
	player.id=player_id

func _on_finished_updating_stats(_words):
	if (main.is_player_turn or word_builder.waiting_for_peers_to_submit) and next_move=="solo_c":
		update_intents()

func apply_fish(tile: Tile, fish: Fish) -> void:
	if fish.rng.randf() <= moves.fishing.cursed_odds:
		tile.add_status(TileStatus.CURSED)
		if Game.balance.evil_fish_chance > 0.0:
			fish.is_evil = true
			fish.tile.tile_sprite.is_evil = true

func _on_sprite_event(event:String)->void:
	if event=="smoke_recede":
		var smoke=get_tree().get_first_node_in_group(&"nobody_office_chunk").get_node("SmokeViewport/SmokeMarker2D")
		if smoke.position.y>0:
			smoke.create_tween().set_ease(Tween.EASE_IN_OUT).tween_property(smoke,"position",Vector2(-128,-50),5)
			return
	super(event)

func unique_end_player_action() -> void :
	if next_move=="swap_small":
		dooming_rows = [2,3,4]
