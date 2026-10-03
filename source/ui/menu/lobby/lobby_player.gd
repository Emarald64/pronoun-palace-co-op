extends Control

func set_player_info(player_info:Dictionary):
	%Name.text=player_info.name
	%CharacterIcon.set_character(player_info.character,true)
