extends WordBuilder

var peer_attacks:Dictionary[int,Dictionary]={}
var damage_indecators:Dictionary[int,Control]={}
var player_total_damage:Dictionary[int,int]={}
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
		print_verbose("attack: ",attack_info)
	peer_attacks[id]=attack_info
	var damage_indecator:Control
	if id in damage_indecators:
		damage_indecator=damage_indecators[id]
		damage_indecator.show()
	else:
		#create new damage indecator
		damage_indecator=preload("res://mods/co-op/source/ui/peer_damage_indecator.tscn").instantiate()
		damage_indecators[id]=damage_indecator
		damage_indecator_holder.add_child(damage_indecator)
		damage_indecator.setup(id)
	damage_indecator.update(attack_info)
	
	# move damage indecator to match attack
	@warning_ignore("confusable_local_declaration")
	var index=damage_indecator_holder.get_children().bsearch_custom(damage_indecator,
		func (a,b)->bool:
			if a.hidden or b.hidden:
				return false
			return peer_attacks[a.peer_id].damage>peer_attacks[b.peer_id].damage
	)
	damage_indecator_holder.move_child(damage_indecator,index)
	
	update_total_damage_counter()
	
	if submitted:
		submitted_count+=1
		if submitted_count+main.dead_players.size()>=len(Game.players)-1:
			all_peers_submitted.emit()
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
	var my_id=multiplayer.get_unique_id()
	if my_id in player_total_damage:
		player_total_damage[my_id]+=damage
	else:
		player_total_damage[my_id]=damage
		
	for id in peer_attacks:
		if id not in main.dead_players:
			var peer_attack=peer_attacks[id]
			damage+=peer_attack.damage
			if id in player_total_damage:
				player_total_damage[id]+=peer_attack.damage
			else:
				player_total_damage[id]=peer_attack.damage
				
			if id in others_submitted_words:
				others_submitted_words[id].append_array(others_queued_words[id])
			else:
				others_submitted_words[id]=others_queued_words[id]

			if enemy.next_move=="bite" and enemy.moves.bite.damage>peer_attack.defense:
				enemy.heal(enemy.moves.bite.damage-peer_attack.defense)
			damage_indecators[id].hide()
	print("attacking for ",damage," id: ",multiplayer.get_unique_id())
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
				context.name=Game.players[id].name
				break
	super(warnings,warning_id,context)

func update_stats() -> void :
	super()
	if main.candy_round:
		if self_heal>heighest_candy_round_value and can_submit():
			heighest_candy_round_value=self_heal
	else:
		peer_stats_updated.rpc(get_attack_value(),defense,can_submit(),false,player.health)
		update_total_damage_counter()
