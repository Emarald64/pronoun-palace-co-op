extends Control

var player_id:int

func _ready():
	Game.difficulty_changed.connect(update_player_icon)

func set_player_info(player_info:Dictionary,id:int):
	player_id=id
	%Name.text=player_info.name
	update_player_icon()
	#if Game.is_playtester(id):
		#%CharacterIcon.texture=load("res://mods/co-op/arte/ui/bug.png")
		#%CharacterIcon.hframes=1
		#%CharacterIcon.vframes=1
	#else:
		#%CharacterIcon.set_character(player_info.character,true)

func update_player_icon():
	%CharacterIcon.texture=await CoOp.get_character_icon(player_id)
