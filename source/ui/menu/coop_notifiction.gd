extends Control

func set_peer_id(id:int):
	var player_info=Game.players[id]
	%PlayerName.text=player_info.name
	if player_info.steam_id>0:
		#set steam avatar
		%PlayerIcon.texture=await Bridge.get_avatar(player_info.steam_id)
	else:
		#set character icon
		var character_icon_texture=load("res://mods/co-op/source/ui/character_icon_texture.tres").new()
		character_icon_texture.set_character(player_info.character)
		%PlayerIcon.texture=character_icon_texture

func appear():
	show()

func disappear():
	hide()
	queue_free()

func set_spell(spell_id:String, description_context:Dictionary):
	var spell=Spell._instantiate_spell(spell_id)
	%SpellIcon.texture=spell.get_texture()
	%Description.text=spell.get_string_group().get_string("effect_notification",description_context)
