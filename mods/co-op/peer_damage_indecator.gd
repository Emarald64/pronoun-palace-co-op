extends Control

func setup(id:int)->void:
	set_character(Game.players[id].character)
	%Name.text=Game.players[id].name

func update(damage_info:Dictionary):
	#if damage_info.valid:
		#intent.intent=Globals.Intent.DAMAGE
		#intent_sprite.flip_h=false
	#else:
		#intent.intent=Globals.Intent.HARMLESS_ATTACK
		#intent_sprite.flip_h=true
	#
	#intent.context={damage=damage_info.damage}
	#intent.update_sprite()
	%AttackLabel.text=str(damage_info.damage)
	
	%DefendLabel.text=str(damage_info.defense)
	
	self_modulate=Color("aaff96") if damage_info.submitted else Color.WHITE

func set_character(character:String)->void:
	%CharacterIcon.set_character(character,true)

func set_dead(dead:bool):
	%Dead.visible=dead
