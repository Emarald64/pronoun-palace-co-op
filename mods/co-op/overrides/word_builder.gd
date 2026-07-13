extends WordBuilder

var peer_attacks:Dictionary[int,Dictionary]={}
var damage_indecators:Dictionary[int,Control]={}
@export var damage_indecator_holder:HBoxContainer
var submitted_count:=0

signal all_peers_submitted

func _ready() -> void:
	super()
	print(Game.players)
	Game.player_disconnected.connect(player_disconnected)

func update_stats() -> void:
	super()
	if main.enemy.id==Enemies.HOUSEBROKEN && main.enemy.passcode in get_words():
		peer_attack_updated.rpc(99,can_submit(),false)
	else:
		peer_attack_updated.rpc(damage,can_submit(),false)

@rpc("any_peer","call_remote")
func peer_attack_updated(peer_damage:int,valid:bool,submitted:bool):
	var id=multiplayer.get_remote_sender_id()
	var attack_info={
		damage=peer_damage,
		valid=valid,
		submitted=submitted,
		}
	print("attack: ",id,attack_info)
	peer_attacks[id]=attack_info
	var damage_indecator
	if id in damage_indecators:
		damage_indecator=damage_indecators[id]
		damage_indecator.show()
	else:
		damage_indecator=preload("res://mods/co-op/peer_damage_indecator.tscn").instantiate()
		damage_indecators[id]=damage_indecator
		damage_indecator.set_character(Game.players[id].character)
		damage_indecator_holder.add_child(damage_indecator)
	damage_indecator.update(attack_info)
	if submitted:
		submitted_count+=1
		if submitted_count==len(Game.players)-1:
			all_peers_submitted.emit()

func submit_word() -> void :
	is_submitting = true
	await main.start_ending_player_turn(true)
	peer_attack_updated.rpc(damage,true,true)
	if submitted_count<len(Game.players)-1:
		var verses_label=$"../VersusLabel"
		verses_label.text="Waiting for other players"
		verses_label.show()
		await all_peers_submitted
		verses_label.hide()
	for id in peer_attacks:
		await player.deal_damage(main.enemy,peer_attacks[id].damage,true,true)
		damage_indecators[id].hide()
	peer_attacks.clear()
	submitted_count=0
	await confirm_word()

func player_disconnected(id:int)->void:
	var attack=peer_attacks[id]
	if attack.submitted:
		submitted_count-=1
	elif submitted_count>=len(Game.players)-1:
		all_peers_submitted.emit()
	peer_attacks.erase(id)
	damage_indecators[id].queue_free()
	damage_indecators.erase(id)
