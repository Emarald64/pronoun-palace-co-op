extends Control

@onready var button:Button=$Button
var peer_id:=0

func _ready() -> void:
	%AttackSprite.texture=%AttackSprite.texture.duplicate()

func setup(id:int)->void:
	set_character(Game.players[id].character)
	%Name.text=Game.players[id].name
	peer_id=id

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
	
	%HealthLabel.text=str(damage_info.health)
	
	self_modulate=Color("aaff96") if damage_info.submitted else Color.WHITE

func set_character(character:String)->void:
	%CharacterIcon.set_character(character,true)

func set_dead(dead:bool):
	%Dead.visible=dead

func _on_button_pressed() -> void:
	if Game.main.player.is_selecting(3):
		Game.main.player.selected.emit(peer_id)
