extends "res://source/enemies/nobody.gd"

var swap_parter:int

var recived_spell
var recived_board_piece:Dictionary={}
var has_recived_swap_info:=false

var last_move_tiles:Array=[]
var recived_phone_a_friend_data:Array=[]

signal recived_swap_info

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
				0:6,
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
				0:5,
				1:6,
				3:7
			},
			next="swap_big"
		},
	}

func _ready():
	super()
	var ids:Array[int]= Game.players.keys()
	ids.sort()
	var player_num=ids.bsearch(multiplayer.get_unique_id())
	if player_num%2:
		swap_parter=ids[player_num-1]
		next_move="swap_small"
	else:
		if player_num==ids.size()-1:
			swap_parter=-1
		else:
			swap_parter=ids[player_num+1]
		next_move="swap_big"

func display_intent():
	match next_move:
		"swap_big":
			add_intent(Intent.EXPAND_BOARD, {size_x = 5, size_y = 5})
		"swap_small":
			add_intent(Intent.EXPAND_BOARD, {size_x = 5, size_y = 3})
		"attack_big":
			add_intent(Intent.ATTACK, {damage=moves.attack_big.damage, count=moves.attack_big.count})
		"attack_small":
			add_intent(Intent.ATTACK, {damage=moves.attack_small.damage})

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
		rows=[0,1]
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
	#swap spells
	var spell_to_swap=main.spell_container.player_spells.pick_random()
	recive_swap.rpc_id(swap_parter,spell_to_swap.spell.get_save_data(), get_board_part_to_swap() if tile_board.num_columns==5 else {})
	if not has_recived_swap_info:
		await recived_swap_info
	spell_to_swap.set_spell(Spell.create_from_save(recived_spell))
	recived_spell=null
	has_recived_swap_info=false
	
	#set board_size
	await tile_board.set_size(5, 5 if big_board else 3)
	if not recived_board_piece.is_empty():
		for cord in recived_board_piece:
			tile_board.get_tile_at(cord).load_save_data(recived_board_piece[cord])
		recived_board_piece.clear()
	
func _on_word_submitted(_words: WordList, _damage: int, _ending_turn: bool) -> void:
	last_move_tiles=word_builder.tiles.map(func (tile:Tile):return tile.get_save_data())

@rpc("any_peer")
func recive_phone_a_friend_data(tiles:Array):
	print("phone a friend data: ",tiles)
	recived_phone_a_friend_data=tiles
	recived_swap_info.emit()

func phone_a_friend_send():
	recive_phone_a_friend_data.rpc_id(swap_parter,last_move_tiles)

func phone_a_friend_recive():
	if recived_phone_a_friend_data.is_empty():
		await recived_swap_info
	var recived_data_dupe=recived_phone_a_friend_data.duplicate()
	rng.move.shuffle(recived_data_dupe)
	for cursed_tile_data in recived_data_dupe.slice(0,moves.phone_a_friend_recive.cursed_num):
		cursed_tile_data.statuses=[Globals.TileStatus.CURSED]
	for i in recived_phone_a_friend_data.size():
		tile_board.get_tile_at(Vector2i(i%5,4-(i/5))).load_save_data(recived_phone_a_friend_data[i])
	recived_phone_a_friend_data.clear()

func attack_big():
	await animate_attack()
	for i in moves.attack_big.count:
		hit_player(moves.attack_big.damage)
		await Game.timeout(0.24)
	await wait_for_idle()

func attack_small():
	await animate_attack()
	hit_player(moves.attack_small.damage)
	await wait_for_idle()
