extends "res://source/spells/red_letter.gd"

func get_spell_convert_from_id(spell: Spell) -> String:
	var coop_spell_upgrades=ModLoader.get_node("coop").namespace_dictionary_ids(CoOp.SPELL_UPGRADES)
	if spell.id in coop_spell_upgrades:
		return spell.id
	if spell.secret_id in coop_spell_upgrades:
		return spell.secret_id
	return super(spell)

func upgrade_spell(spell: Spell) -> void:
	var convert_from_id=get_spell_convert_from_id(spell)
	var coop_instance:CoOp=ModLoader.get_node("coop")
	if convert_from_id in coop_instance.namespace_dictionary_ids(CoOp.SPELL_UPGRADES):
		spell.transform_spell(coop_instance.namespace_id(ModLoader.get_node("coop").namespace_dictionary_ids(CoOp.SPELL_UPGRADES)[convert_from_id]), not convert_from_id in coop_instance.namespace_id(CoOp.SPELLS.GIFT_COOP))
	else:
		super(spell)
