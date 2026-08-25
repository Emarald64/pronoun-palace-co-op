@tool
extends Summary

func generate_summary(act: int = -1, victory: bool = true) -> void:
	super(act,victory)
	if act==-1:
		%Coop.show()
		var sorted_total_damage=[]
		for id in Game.word_builder.player_total_damage:
			var total_damage_stat=[Game.players[id].name,Game.word_builder.player_total_damage[id]]
			var index=sorted_total_damage.bsearch_custom(total_damage_stat,
				func (a,b):
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
				var longest_word:String=Array(players_submitted_words[id]).max()
				var stats_entry=[Game.players[id].name,longest_word]
				var index=longest_word_stats.bsearch_custom(stats_entry,
				func (a,b):
					if a[1].length()==b[1].length():
						return a[0]>b[0]
					return a[1].length()>b[1].length()
				)
				longest_word_stats.insert(index,stats_entry)
		var longest_word_labels=%CoopLongestWordStats.get_children()
		for longest_word_stat in longest_word_stats:
			var label=longest_word_labels.pop_front()
			if label==null:
				label=SUMMARY_LABEL.instantiate()
				%CoopLongestWordStats.add_child(label)
			label.text="• %s: %s" % longest_word_stat
	else:
		%Coop.hide()
