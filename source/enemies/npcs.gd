extends Enemy


var preparing_turn: = false


func _init():
	id = Enemies.NPCS
	next_move = "pathfind"

	moves = {
		pathfind = {
			damage = {
				0: 3, 
				1: 4, 
				2: 5, 
			}, 
			npc_health = {
				0: 3, 
				3: 4, 
			}, 
			next = "pathfind", 
		}, 
	}


func _ready():
	super._ready()

	if not launching_from_enemy_scene:
		Game.player.pre_turn_ended.connect(_on_pre_player_turn_end)
	word_builder.peer_attack_updated.connect(update_intents.unbind(1))


func _difficulty_changed() -> void :
	_scale_moves()
	pre_start_battle()
	var attack_damage = get_attack_damage()
	sprite.spawn_npcs(moves.pathfind.damage, false, moves.pathfind.damage - attack_damage)
	start_battle()


func appear():
	preparing_turn = true
	await sprite.spawn_npcs(moves.pathfind.damage, true)
	preparing_turn = false


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


func get_intent():
	return Intent.MULTITUDE


func animate_flinch(_damage):
	var num_live_npcs = sprite.get_live_npcs().size()
	var attack_damage = get_attack_damage()
	await sprite.kill_npcs(num_live_npcs - attack_damage)


func animate_flinch_lethal():
	delayed_hide_health()
	await sprite.kill_npcs(sprite.get_live_npcs().size())


func delayed_hide_health() -> void :
	await Game.timeout(0.5)
	health_bar.disappear()


func prepare_next_turn():
	preparing_turn = true
	super.prepare_next_turn()
	if times_performed_move[next_move] != 0:
		await respawn()
	preparing_turn = false


func respawn() -> void :
	await sprite.respawn_npcs()


func pathfind():
	if get_attack_damage() == 0:
		await Game.timeout(0.5)
		return

	sprite.animate_attack()
	await sprite.hit
	hit_player(get_attack_damage())
	await sprite.attack_finished


func get_damage_taken():
	var taken = damage_taken
	if not word_builder.is_submitting and main.is_player_turn:
		taken += word_builder.damage
		for attack in word_builder.peer_attacks.values():
			taken+=attack.damage
	
	return taken


func get_damage_penalty():
	return max(0, get_damage_taken() / (moves.pathfind.npc_health*(Game.players.size()-main.dead_players.size())))


func get_attack_damage():
	return max(0, moves.pathfind.damage - get_damage_penalty())


func _on_finished_updating_stats(_words):
	if main.is_player_turn:
		update_intents()


func _on_pre_player_turn_end() -> void :
	if not word_builder.is_submitting:
		update_intents()


func _on_sprite_npc_respawning() -> void :
	if preparing_turn:
		update_intents()


func load_save_data(save):
	super.load_save_data(save)
	var attack_damage = get_attack_damage()
	sprite.spawn_npcs(moves.pathfind.damage, false, moves.pathfind.damage - attack_damage)
