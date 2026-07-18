extends WordBuilder

var peer_attacks:Dictionary[int,Dictionary]={}
var damage_indecators:Dictionary[int,Control]={}
@export var damage_indecator_holder:Control
var submitted_count:=0
var heighest_candy_round_value:=0

signal all_peers_submitted

func _ready() -> void:
	super()
	print(Game.players)
	Game.player_disconnected.connect(player_disconnected)

func update_stats() -> void:
	if main.candy_round and can_submit():
		heighest_candy_round_value=maxi(heighest_candy_round_value,self_heal)
	super()
	peer_stats_updated.rpc(get_attack_value(),defense,can_submit(),false)

@rpc("any_peer","call_remote")
func peer_stats_updated(peer_damage:int,peer_defense:int,valid:bool,submitted:bool):
	var id=multiplayer.get_remote_sender_id()
	var attack_info={
		damage=peer_damage,
		defense=peer_defense,
		valid=valid,
		submitted=submitted,
		}
	#print("attack: ",id,attack_info)
	peer_attacks[id]=attack_info
	var damage_indecator
	if id in damage_indecators:
		damage_indecator=damage_indecators[id]
		damage_indecator.show()
	else:
		damage_indecator=preload("res://mods/co-op/peer_damage_indecator.tscn").instantiate()
		damage_indecators[id]=damage_indecator
		damage_indecator.setup(id)
		damage_indecator_holder.add_child(damage_indecator)
	damage_indecator.update(attack_info)
	if submitted:
		submitted_count+=1
		if submitted_count==len(Game.players)-1:
			all_peers_submitted.emit()

func send_attack_and_wait(reroll:bool=false)->void:
	peer_stats_updated.rpc(get_attack_value(),defense,not reroll,true)
	var enemy=main.enemy
	if (submitted_count+main.dead_players.size())<len(Game.players)-1:
		var verses_label=$"../VersusLabel"
		verses_label.text="Waiting for other players"
		verses_label.show()
		await all_peers_submitted
		verses_label.hide()
	for id in peer_attacks:
		var peer_attack=peer_attacks[id]
		damage+=peer_attack.damage
		if enemy.next_move=="bite" and enemy.moves.bite.damage>peer_attack.defense:
			enemy.heal(enemy.moves.bite.damage-peer_attack.defense)
		damage_indecators[id].hide()
	peer_attacks.clear()
	submitted_count=0
	if reroll:
		player.attack(enemy,damage)

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
	if submitted_count>=len(Game.players)-1:
		all_peers_submitted.emit()

func get_attack_value()->int:
	if main.enemy.id==Enemies.HOUSEBROKEN and main.enemy.passcode in get_words():
		return 999
	return damage

#func can_submit() -> bool:
	#return not main.candy_round and super()
