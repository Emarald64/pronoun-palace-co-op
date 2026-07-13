extends VBoxContainer

@onready var intent=%Intent
@onready var intent_sprite=%Intent.get_node("Sprite")

func update(damage_info:Dictionary):
	if damage_info.valid:
		intent.intent=Globals.Intent.DAMAGE
		intent_sprite.flip_h=false
	else:
		intent.intent=Globals.Intent.HARMLESS_ATTACK
		intent_sprite.flip_h=true
	
	intent.context={damage=damage_info.damage}
	intent.update_sprite()
	intent.update_label()
	
	$Submitted.visible=damage_info.submitted

func set_character(character:String)->void:
	%CharacterIcon.set_character(character,true)
