extends WordBuilder

var peer_attacks:Dictionary[int,Dictionary]={}
var damage_indecators:Dictionary[int,Control]={}
@export var damage_indecator_holder:Control
@export var total_attack_label:Label
@export var total_attack_container:Control
var submitted_count:=0
var heighest_candy_round_value:=0
var waiting_for_peers_to_submit:=false
var log_all_damage_updates:=false

var others_queued_words:Dictionary[int,PackedStringArray]={}
var others_submitted_words:Dictionary[int,PackedStringArray]={}

signal all_peers_submitted
signal peer_attack_updated(id:int,submit:bool)

func _ready() -> void:
	super()
	print(Game.players)
	Game.player_disconnected.connect(player_disconnected)

@rpc("any_peer")
func peer_submitted_word(peer_damage:int,peer_defense:int,valid:bool,health:int,words:PackedStringArray):
	others_queued_words[multiplayer.get_remote_sender_id()]=words
	peer_stats_updated(peer_damage,peer_defense,valid,true,health)
	

@rpc("any_peer","unreliable_ordered")
func peer_stats_updated(peer_damage:int,peer_defense:int,valid:bool,submitted:bool,health:int):
	var id=multiplayer.get_remote_sender_id()
	var attack_info={
		damage=peer_damage,
		defense=peer_defense,
		valid=valid,
		submitted=submitted,
		health=health,
		}
	if submitted or log_all_damage_updates:
		print("attack: ",id,attack_info)
	else:
		print_verbose("attack: ",id,attack_info)
	peer_attacks[id]=attack_info
	var damage_indecator
	if id in damage_indecators:
		damage_indecator=damage_indecators[id]
		damage_indecator.show()
	else:
		#create new damage indecator
		damage_indecator=preload("res://mods/co-op/peer_damage_indecator.tscn").instantiate()
		damage_indecators[id]=damage_indecator
		damage_indecator_holder.add_child(damage_indecator)
		damage_indecator.setup(id)
	damage_indecator.update(attack_info)
	if submitted:
		submitted_count+=1
		if submitted_count+main.dead_players.size()>=len(Game.players)-1:
			all_peers_submitted.emit()
	update_total_damage_counter()
	peer_attack_updated.emit(id,submitted)

func update_total_damage_counter():
	var total_damage=damage
	if main.enemy.id==Enemies.HOUSEBROKEN and main.enemy.passcode in get_words().words:
		var health_scaling=main.enemy._get_health_scaling()
		total_damage+=health_scaling[clampi(Game.balance.enemy_health,0,health_scaling.size()-1)]
	
	total_damage=peer_attacks.values().reduce(
		func (accum:int,peer_attack)->int:
			return accum+peer_attack.damage
	,total_damage)
	
	if total_damage>0:
		total_attack_container.show()
	total_attack_label.text=str(total_damage)

func send_attack_and_wait(reroll:bool=false)->void:
	peer_submitted_word.rpc(get_attack_value(),defense,not reroll,player.health,words_list.words)
	var enemy=main.enemy
	if (submitted_count+main.dead_players.size())<len(Game.players)-1:
		#var verses_label=$"../VersusLabel"
		word_hint.label.text="Waiting for other players to submit"
		word_hint.appear()
		#verses_label.show()
		waiting_for_peers_to_submit=true
		print("waiting for other players to submit")
		await all_peers_submitted
		print("other players submited")
		waiting_for_peers_to_submit=false
		word_hint.disappear()
		#verses_label.hide()
	for id in peer_attacks:
		if id not in main.dead_players:
			var peer_attack=peer_attacks[id]
			damage+=peer_attack.damage
			if id in others_submitted_words:
				others_submitted_words[id].append_array(others_queued_words[id])
			else:
				others_submitted_words[id]=others_queued_words[id]

			if enemy.next_move=="bite" and enemy.moves.bite.damage>peer_attack.defense:
				enemy.heal(enemy.moves.bite.damage-peer_attack.defense)
			damage_indecators[id].hide()
	print("attacking for ",damage)
	peer_attacks.clear()
	total_attack_container.hide()
	submitted_count=0
	if main.enemy.id==Enemies.NOBODY and damage>=main.enemy.health:
		#Beat the shit out of Nobody when killing her
		for i in Game.players.size()-main.dead_players.size()-1:
			await player.attack(enemy,damage)
	if main.enemy.id==Enemies.HOUSEBROKEN and main.enemy.passcode in get_words().words:
		var health_scaling=main.enemy._get_health_scaling()
		damage+=health_scaling[clampi(Game.balance.enemy_health,0,health_scaling.size()-1)]
	if reroll:
		await player.attack(enemy,damage)

func submit_word() -> void :
	if not main.candy_round:
		is_submitting = true
		await main.start_ending_player_turn(true)
		await send_attack_and_wait(false)
		await confirm_word()
	
func end_turn(reroll = false):
	if reroll:
		await send_attack_and_wait(true)
	await super(reroll)

func player_disconnected(id:int)->void:
	if id in peer_attacks:
		var attack=peer_attacks[id]
		if attack.submitted:
			submitted_count-=1
		peer_attacks.erase(id)
		damage_indecators[id].queue_free()
		damage_indecators.erase(id)
	if submitted_count+main.dead_players.size()>=len(Game.players)-1:
		all_peers_submitted.emit()

func get_attack_value()->int:
	if main.enemy.id==Enemies.HOUSEBROKEN and main.enemy.passcode in get_words().words:
		#print("housebroken word spelled")
		var health_scaling=main.enemy._get_health_scaling()
		return damage+health_scaling[clampi(Game.balance.enemy_health,0,health_scaling.size()-1)]
	return damage

@rpc("any_peer")
func resend_submitted():
	if waiting_for_peers_to_submit:
		peer_submitted_word.rpc_id(multiplayer.get_remote_sender_id(),get_attack_value(),defense,true,player.health)

func get_repeat_word(word_list: WordList) -> String:
	var own_repeat_word=super(word_list)
	if not own_repeat_word.is_empty():
		return own_repeat_word
	for word in word_list.words:
		for id in others_submitted_words:
			if word in others_submitted_words[id]:
				return word
	
	return ""

func resolve_tile_words(use_tiles) -> WordList:
	var priority_words: = PackedStringArray()
	var depriority_words: = PackedStringArray()
	var priority_flag: WordDictionary.WordFlags = WordDictionary.WordFlags.NONE

	if Game.balance.no_repeat_words:
		depriority_words.append_array(main.run_stats.get_words())
		for id in others_submitted_words:
			depriority_words.append_array(others_submitted_words[id])
		

	if Game.enemy != null:
		if Game.enemy.id == Enemies.HOUSEBROKEN:
			priority_words.append(Game.enemy.passcode)
		elif Game.enemy.id == Enemies.LUMP:
			if not Game.enemy.category_queue.is_empty():
				priority_flag = Globals.WORD_CATEGORY_FLAGS[Game.enemy.category_queue[0]]

	return WordUtility.resolve_tile_words(use_tiles, priority_words, depriority_words, priority_flag)

func add_warning(warnings: Dictionary, warning_id: String, context: Dictionary = {}) -> void:
	if warning_id==WARNINGS.REPEAT_WORD and "word" in context:
		for id in others_submitted_words:
			if context.word in others_submitted_words[id]:
				super(warnings,"other_repeated_word",context.merged({name=Game.players[id].name}))
	else:
		super(warnings,warning_id,context)

# I realy hate having to copy this whole function to change anything about the word scoring
func update_stats() -> void :
	var words: = get_words()
	intent_container.reset_intents()

	reset_stats()

	updating_stats.emit(words)

	intent_tiles = {}
	intent_value = {}

	invalidating_tiles = []

	var warnings: Dictionary = {}

	var shimmering_tiles = []
	var link_color_tiles = {}
	for tile: Tile in tiles:
		var value: = tile.get_value()
		var frozen: = tile.has_status(TileStatus.FROZEN)

		if tile.has_value():
			if tile.type == TileType.DAMAGE or frozen:
				add_intent_tile(Intent.DAMAGE, tile)
				damage += value

			if tile.type == TileType.DEFENSE or frozen:
				add_intent_tile(Intent.DEFENSE, tile)
				defense += value

			if tile.has_status(TileStatus.CANDY):
				add_intent_tile(Intent.HEAL, tile)
				self_heal += value

			var slot_data: Variant = get_tile_slot_data(tile)
			if slot_data == -99:
				add_intent_tile(Intent.SPIKED_SLOTS, tile)
				slot_damage += value

		var is_crit: = tile.has_status(TileStatus.CRIT)
		var bomb_status = tile.get_status(TileStatus.BOMB)
		if bomb_status:
			is_crit = bomb_status.turns == 1

		if is_crit:
			var crit_addition: float = Game.balance.crit_value - 1
			if tile.type == TileType.DAMAGE:
				add_intent_tile(Intent.DAMAGE_MULTIPLIER, tile)
				damage_multiplier += crit_addition
			else:
				add_intent_tile(Intent.DEFENSE_MULTIPLIER, tile)
				defense_multiplier += crit_addition

		if tile.is_shimmering():
			shimmering_tiles.append(tile)

		var bruise_status: = tile.get_status(TileStatus.BRUISE)
		if bruise_status:
			add_intent_tile(Intent.BRUISE, tile)
			var status_value = max(value, 1) + Game.balance.status_added_value
			bruise += status_value

		var period: = tile.get_status(TileStatus.PERIOD)
		if period and period.invalidates_word():
			add_warning_tile(warnings, WARNINGS.PERIOD, tile)

		var capital: = tile.get_status(TileStatus.CAPITAL)
		if capital and capital.invalidates_word():
			add_warning_tile(warnings, WARNINGS.CAPITAL, tile)

		var linked: = tile.get_status(TileStatus.LINKED)
		if linked:
			link_color_tiles.get_or_add(linked.link_id, []).append(tile)

		var gay: = tile.get_status(TileStatus.GAY)
		if gay and gay.invalidates_word():
			add_warning_tile(warnings, WARNINGS.STRAIGHT, tile)

	var invalidated_linked_count: int = 0
	var invalidated_linked_colors = {}
	var board_tiles = tile_board.get_tiles({sorted = true, in_word = false})
	for tile: Tile in board_tiles:
		var linked: = tile.get_status(TileStatus.LINKED)
		if linked and linked.link_id in link_color_tiles:
			invalidated_linked_count += 1
			invalidated_linked_colors[linked.link_id] = true
			link_color_tiles[linked.link_id].append(tile)

		if tile.has_status(TileStatus.DEFAULT):
			continue

		var poison: = tile.get_status(TileStatus.POISON)
		if poison:
			add_intent_tile(Intent.POISON, tile, poison.get_status_value())

		var bleed: = tile.get_status(TileStatus.BLEED)
		if bleed:
			add_intent_tile(Intent.BLEED, tile, Game.balance.bleed_damage)

		var cursed: = tile.get_status(TileStatus.CURSED)
		if cursed:
			add_intent_tile(Intent.CURSED, tile, cursed.get_status_value())

		var eternal: = tile.get_status(TileStatus.ETERNAL)
		if eternal and not eternal.played_this_turn:
			add_intent_tile(Intent.ETERNAL, tile, eternal.get_status_value())

		var acid: = tile.get_status(TileStatus.ACID)
		if acid and acid.will_fall_on_turn_end():
			add_intent_tile(Intent.ACID, tile, acid.get_status_value())

		var bomb: = tile.get_status(TileStatus.BOMB)
		if bomb and bomb.will_explode_on_turn_end():
			add_intent_tile(Intent.BOMB, tile, bomb.get_status_value())

		var haze: = tile.get_status(TileStatus.HAZE)
		if haze:
			add_intent_tile(Intent.HAZE, tile, Game.balance.bleed_damage)

	tile_defense = int(ceil(defense * defense_multiplier))

	post_tile_stats.emit(words)

	damage = int(ceil(damage * damage_multiplier))
	defense = int(ceil(defense * defense_multiplier))

	is_damaging = damage != 0 or Intent.DAMAGE in intent_tiles
	is_healing = self_heal != 0 or Intent.HEAL in intent_tiles

	if is_damaging:
		add_intent(Intent.DAMAGE, {damage = damage})

	if defense != 0 or Intent.DEFENSE in intent_tiles:
		add_intent(Intent.DEFENSE, {defense = defense})

	if is_healing:
		add_intent(Intent.HEAL, {heal = self_heal})

	if bruise > 0:
		add_intent(Intent.BRUISE, {damage = bruise})

	if slot_damage > 0:
		add_intent(Intent.SPIKED_SLOTS, {damage = slot_damage})

	if damage_multiplier > 1:
		add_intent(Intent.DAMAGE_MULTIPLIER, {multiplier = damage_multiplier})

	if defense_multiplier > 1:
		add_intent(Intent.DEFENSE_MULTIPLIER, {multiplier = defense_multiplier})

	for spell in player.get_spells():
		var spell_damage: int = spell.get_laced_damage()
		if spell_damage > 0:
			laced_damage += spell_damage

	if laced_damage > 0:
		add_intent(Intent.LACED, {damage = laced_damage})

	for intent in SIMPLE_DAMAGE_INTENTS:
		if intent in intent_tiles:
			add_intent(intent, {damage = intent_value[intent]})

	var invalid_link_tiles = []
	var invalid_link_colors = []
	for color in invalidated_linked_colors:
		invalid_link_colors.append(StringManager.get_string("misc/linked_color/" + color))
		for tile in link_color_tiles[color]:
			invalid_link_tiles.append(tile)

	if invalid_link_tiles.size() > 0:
		add_warning(warnings, WARNINGS.LINKED, {invalid_linked = invalidated_linked_count})
		invalidating_tiles.append_array(invalid_link_tiles)

	if repeat_word != "":
		if repeat_word_is_mystery:
			add_warning(warnings, WARNINGS.REPEAT_WORD)
		else:
			add_warning(warnings, WARNINGS.REPEAT_WORD, {word = repeat_word})

	if not words.all_valid and tiles.size() > 0:
		for sub_list in words.sub_lists:
			var has_invalid_mystery: = false
			if not sub_list.all_valid:
				for tile in sub_list.tiles:
					if tile.has_status(TileStatus.MYSTERY):
						has_invalid_mystery = true
						break

			if has_invalid_mystery:
				add_warning(warnings, WARNINGS.MYSTERY)
				break


	var has_warning: = false
	for warning_id in WARNING_PRIORITY+["other_repeated_word"]:
		if warning_id in warnings:
			has_warning = true
			word_hint.set_warning("misc/word_warnings/" + warning_id, warnings[warning_id])
			break

	if not has_warning:
		word_hint.reset_warning()

	if words.maximum_length > 0 and SaveManager.get_show_crit_chance_enabled():
		if tile_board.crit_chance > 0 and tile_board.restock_depth > 0:
			var player_crit_chance = player.get_crit_chance()
			var crit_bonus = tile_board.calculate_crit_bonus(words.sub_lists)
			var next_chance = tile_board.calculate_added_crit_chance(crit_bonus)
			var is_wildcard: bool = player.crits_are_wildcards()
			var context = {
				chance = "%.1f" % [next_chance * 100.0], 
				bonus = "%.1f" % [player_crit_chance.BONUS_PER_LETTER * 100.0], 
				truncated_chance = "%.0f" % [next_chance * 100.0], 
				natural = player.has_natural_crit_chance(), 
				wildcard = is_wildcard, 
			}
			if is_wildcard:
				context.name_override = "wildcard_chance"

			add_intent(Intent.CRIT_CHANCE, context)

	finished_updating_stats.emit(words)
	intent_container.update_intents(false, true)
	
	if main.candy_round:
		if can_submit():
			heighest_candy_round_value=maxi(heighest_candy_round_value,self_heal)
	else:
		peer_stats_updated.rpc(get_attack_value(),defense,can_submit(),false,player.health)
		update_total_damage_counter()
