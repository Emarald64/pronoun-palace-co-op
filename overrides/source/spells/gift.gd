extends "res://source/spells/gift.gd"

var transforming:=false

func _first_spawn(is_transform:=false):
	transforming=is_transform

func _ready():
	if player_spell_slot==null:
		is_ready=false
	elif transforming:
		var alt_gift= player_spell_slot.get_meta("alt_gift","")
		if not alt_gift.is_empty():
			transform_spell(alt_gift)
	else:
		player_spell_slot.remove_meta("alt_gift")
