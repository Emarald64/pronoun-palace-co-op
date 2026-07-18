extends Control

func _ready() -> void:
	%AttackSprite.texture=%AttackSprite.texture.duplicate()

func setup(id:int)->void:
	set_character(Game.players[id].character)
	%Name.text=Game.players[id].name

func update(damage_info:Dictionary):
	%AttackSprite.texture.region.position=Vector2(73,91) if damage_info.valid else Vector2(90,145)
	#if damage_info.valid:
		#intent.intent=Globals.Intent.DAMAGE
	#else:
		#intent.intent=Globals.Intent.HARMLESS_ATTACK
	
	#intent.context={damage=damage_info.damage}
	#intent.update_sprite()
	%AttackLabel.text=str(damage_info.damage)
	
	%DefendLabel.text=str(damage_info.defense)
	
	self_modulate=Color("aaff96") if damage_info.submitted else Color.WHITE

func set_character(character:String)->void:
	%CharacterIcon.set_character(character,true)

func set_dead(dead:bool):
	%Dead.visible=dead
