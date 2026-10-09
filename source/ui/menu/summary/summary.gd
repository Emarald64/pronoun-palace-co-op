@tool
extends Summary

signal recieved_all_category_scores

const PLAYER_CATEGORY_SCENE=preload("res://mods/co-op/source/ui/menu/summary/coop_category.tscn")
var players_category_scores:Dictionary[int,Variant]={}

#func _process(_delta: float) -> void:
	#update_panels()
	#super()

func generate_summary(act: int = -1, victory: bool = true) -> void:
	super(act,victory)
	if act==-1:
		%Coop.show()
		var sorted_total_damage=[]
		for id in Game.word_builder.player_total_damage:
			var total_damage_stat=[Game.all_player_names.get(id,"???"),Game.word_builder.player_total_damage.get(id,0)]
			var index=sorted_total_damage.bsearch_custom(total_damage_stat,
				func (a,b)->bool:
					if a[1]==b[1]:
						return a[0]>b[0]
					return a[1]>b[1])
			sorted_total_damage.insert(index,total_damage_stat)
		var damage_stats_labels=%CoopDamageStats.get_children()
		for total_damage_stat in sorted_total_damage:
			var label=damage_stats_labels.pop_front()
			if label==null:
				label=SUMMARY_LABEL.instantiate()
				%CoopDamageStats.add_child(label)
			label.text="• %s: %s" % total_damage_stat
		
		var players_submitted_words:Dictionary[int,PackedStringArray]=Game.word_builder.others_submitted_words.duplicate()
		players_submitted_words[multiplayer.get_unique_id()]=Game.main.run_stats.get_words()
		var longest_word_stats:Array[Array]=[]
		for id in players_submitted_words:
			if not players_submitted_words[id].is_empty():
				var longest_word:String
				for word in players_submitted_words[id]:
					if longest_word.length()<word.length():
						longest_word=word
				var stats_entry=[Game.all_player_names.get(id,"???"),longest_word]
				var index=longest_word_stats.bsearch_custom(stats_entry,
				func (a,b):
					if a[1].length()==b[1].length():
						return a[0]>b[0]
					return a[1].length()>b[1].length()
				)
				longest_word_stats.insert(index,stats_entry)
		#var longest_word_labels=%CoopLongestWordStats.get_children()
		for longest_word_stat in longest_word_stats:
			#var label=longest_word_labels.pop_front()
			#if label==null:
			var label=SUMMARY_LABEL.instantiate()
			%CoopLongestWordStats.add_child(label)
			label.text="• %s: %s" % longest_word_stat
		
		if victory:
			# send out category scores
			var category_scores=get_category_scores()
			#players_category_scores[multiplayer.get_unique_id()]=category_scores
			print(category_scores)
			recieve_category_scores.rpc(category_scores)
		
		%Coop.reset_size()
		await get_tree().process_frame
		update_panels.call_deferred()
	else:
		%Coop.hide()

@rpc("any_peer","call_local")
func recieve_category_scores(category_scores:Dictionary):
	players_category_scores[multiplayer.get_remote_sender_id()]=category_scores
	if players_category_scores.size()>=Game.players.size()-Game.main.dead_players.size():
		calculate_player_categories()

func calculate_player_categories():
	var categories:=StringManager.get_string_group("mod/co-op/end_title")
	var assigned_categories:Dictionary[String,int]={}
	var unasigned_players:Array[int]=players_category_scores.keys()
	unasigned_players.sort()
	# assign players to categories
	for category in categories.groups:
		if "least" in categories.groups[category].groups:
			var lowest_player=get_best_player_in_category(
				category,
				unasigned_players,
				categories.get_string_at_path([category,"least","limit"]).to_int(),
				false
				)
			if lowest_player:
				unasigned_players.erase(lowest_player)
				assigned_categories[category+"/least"]=lowest_player
			
			var most_player=get_best_player_in_category(
				category,
				unasigned_players,
				categories.get_string_at_path([category,"most","limit"]).to_int(),
				true
				)
			if most_player:
				unasigned_players.erase(most_player)
				assigned_categories[category+"/most"]=most_player
		else:
			var best_player=get_best_player_in_category(
				category,
				unasigned_players,
				categories.get_string_at_path([category,"limit"]).to_int()
				)
			if best_player:
				unasigned_players.erase(best_player)
				assigned_categories[category]=best_player
		
		if unasigned_players.is_empty():
			break
	
	print(assigned_categories)
	
	for category in assigned_categories:
		var player_category=PLAYER_CATEGORY_SCENE.instantiate()
		var player_id=assigned_categories[category]
		player_category.setup(player_id,category,players_category_scores[player_id][category.get_slice("/",0)])
		%CoopPlayerCategories.add_child(player_category)
	
	%CategoriesStuff.show()
	%Coop.reset_size()
	await get_tree().process_frame
	await get_tree().process_frame
	update_panels.call_deferred()

func get_best_player_in_category(category:String,players:Array[int],limit,prefer_higher:bool=true)->int:
	var best_score=limit - (1 if max else -1)
	var best_player:=0
	for player in players:
		var score=players_category_scores[player][category]
		if (score>best_score)==prefer_higher and score!=best_score:
			best_player=player
			best_score=score
	return best_player

const tracked_word_categories={
	slurs=WordDictionary.WordFlags.SLUR,
	metals=WordDictionary.WordFlags.METALS,
	animals=WordDictionary.WordFlags.ANIMALS,
	fruits_and_veg=WordDictionary.WordFlags.FRUITS_AND_VEGETABLES,
	colors=WordDictionary.WordFlags.COLORS,
	body_parts=WordDictionary.WordFlags.BODY_PARTS,
}

func get_category_scores()->Dictionary:
	var scores:={
		strawman_taps=Game.main.strawman_taps,
		time_spent=run_stats.get_total_deliberation_time(),
		average_word_length=0.0,
		damage_taken=Game.player.damage_taken,
		single_attack_damage=run_stats.get_max_damage(),
		spells_used=0,
		coop_spells=0,
		modded_spells=0,
		screenshots_taken=Game.main.screenshots_taken,
		deaths=Game.main.deaths,
	}
	for word_category in tracked_word_categories:
		scores["%s_played"%word_category]=0
	var played_words=run_stats.get_words()
	for word in played_words:
		scores.average_word_length+=word.length()
		for word_category in tracked_word_categories:
			if WordUtility.dictionary.word_has_flag(word,tracked_word_categories[word_category]):
				scores["%s_played"%word_category]+=1
	scores.average_word_length/=played_words.size()
	
	for spell:String in run_stats.spell_usages:
		scores.spells_used+=run_stats.spell_usages[spell]
		if spell.begins_with("co-op:"):
			scores.coop_spells+=run_stats.spell_usages[spell]
		elif ":" in spell:
			scores.modded_spells+=run_stats.spell_usages[spell]
	
	return scores
