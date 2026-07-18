extends "res://source/autoload/globals.gd"

func get_spell_pool(category = null):
	var weighted_spells = SpellLoader.spell_pool
	var spell_pool = {}

	if category != null:
		weighted_spells = SpellLoader.spell_categories[category]

	for spell in weighted_spells:
		if is_spell_unlocked(spell):
			spell_pool[spell] = SpellLoader.spell_pool[spell]
	print("spell pool "+str(spell_pool))
	return spell_pool
