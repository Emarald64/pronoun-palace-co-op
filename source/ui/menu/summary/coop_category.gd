extends Control

func setup(player_id:int,category:String,value):
	var context={value=value}
	for encounter in Game.main.run_stats.encounter_history:
		if encounter.enemy_name==Enemies.HOUSEBROKEN:
			context.housebroekn=true
			break
	%Header.text="%s - %s"%[
		Game.all_player_names[player_id],
		StringManager.get_string(
			"mod/co-op/end_title/%s/title"%category,
			context
		)
	]
	
	%Description.text=StringManager.get_string(
		"mod/co-op/end_title/%s/description"%category,
		context
	)
