extends Control

func set_player_info(player_info:Dictionary,id:int):
	%Name.text=player_info.name
	if Game.is_playtester(id):
		%CharacterIcon.texture=load("res://mods/co-op/arte/ui/bug.png")
		%CharacterIcon.hframes=1
		%CharacterIcon.vframes=1
	else:
		%CharacterIcon.set_character(player_info.character,true)
