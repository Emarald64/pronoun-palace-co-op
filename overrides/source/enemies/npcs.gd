extends "res://source/enemies/npcs.gd"

func _ready():
	super()
	
	word_builder.peer_attack_updated.connect(func (_id:int,submitted:bool):
		if not submitted:
			update_intents()
	)


func display_intent():
	var damage = get_attack_damage()
	if preparing_turn:
		damage = sprite.get_live_npcs(true).size()
		if damage == 0:
			return

	add_intent(get_intent(), {
		damage = damage, 
		original_damage = moves.pathfind.damage, 
		reduce_by = 1, 
		per_health = moves.pathfind.npc_health*(Game.players.size()-main.dead_players.size())
	})

func get_damage_taken():
	var taken = damage_taken
	if main.is_player_turn or word_builder.waiting_for_peers_to_submit:
		taken += word_builder.damage
	for attack in word_builder.peer_attacks.values():
		taken+=attack.damage
	
	return taken


func get_damage_penalty():
	return max(0, get_damage_taken() / (moves.pathfind.npc_health*maxi(1,Game.players.size()-main.dead_players.size())))
