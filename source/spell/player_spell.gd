extends PlayerSpell

const SPELLS=Globals.SPELLS

var old_spell:Spell

const extra_hidden_spells=[
	CoOp.SPELLS.POSTAGE_STAMP,
	CoOp.SPELLS.BUG_SPRAY,
	Globals.SPELLS.DIME,
]

func get_shimmered_spell()->Spell:
	var spell_catagory=CoOp.SPELL_CATEGORY.IMAGINARY_INSTANT
	if spell is TileModifierSpell:
		spell_catagory=CoOp.SPELL_CATEGORY.IMAGINARY_PICK
	var spell_pool=SpellRegistry.get_base_spell_pool(spell_catagory)
	spell_pool.erase(spell.id)
	print(spell_pool)
	var spell_id=spell.rng.reroll.weighted_random(spell_pool)
	if spell.id==SPELLS.SOBRIETY_TEST and SpellRegistry.has_data("bug_13"):
		spell_id="bug_13"
	var new_spell=SpellRegistry.instantiate(spell_id)
	if new_spell.id==SPELLS.LIP_BALM:
		new_spell.state=1
	print(new_spell.id)
	return new_spell

func _on_spell_paper_pressed() -> void:
	#var old_spell_id:=""
	if spell.has_curse(CoOp.CURSES.SHIMMERING) and not (spell.is_active() and player.is_selecting()) and not player.is_selecting(player.Selection.SPELL):# and spell.rng.spell.randi_range(0,2)==0:
		#change spell for shimmering
		old_spell=spell
		spell=get_shimmered_spell()
		spell.player_spell_slot = self
		spell.set_meta("imaginary_shadow",true)
		spell.reseed(old_spell.rng.reroll)
		spell._first_spawn(true)
		spell.set_curse(CoOp.CURSES.SHIMMERING)
		spell.max_charge = old_spell.max_charge
		spell.charge = old_spell.charge
		spell.charge_character=old_spell.charge_character
		charge_container.link_spell(spell)
		if not spell is TileModifierSpell and spell.id not in extra_hidden_spells:
			reveal_spell()
		else:
			if spell is TileModifierSpell and old_spell is TileModifierSpell:
				spell.selectable_regions=old_spell.selectable_regions
			if not player.selection_finished.is_connected(reveal_spell):
				player.selection_finished.connect(reveal_spell,CONNECT_ONE_SHOT)

		spell.charge_updated.connect(_on_spell_charge_updated)
		spell.description_updated.connect(_on_spell_description_updated)
		spell.set_ready()
		#old_spell_id=spell.id
		
	await super()
	
	if old_spell:
		old_spell.charge=spell.charge
		if player.selection_finished.is_connected(reveal_spell):
			player.selection_finished.disconnect(reveal_spell)
		spell=old_spell
		charge_container.link_spell(spell)
		spell_sprite.link_spell(spell)
		_on_spell_charge_updated()
		_on_spell_description_updated()
		old_spell=null
		#spell.transform_spell(old_spell_id,true,true,true,true,true)

func reveal_spell():
	spell_sprite.link_spell(spell)
	_on_spell_description_updated()
	spell.shake.emit()

func _on_player_selection_started():
	if spell.is_active():
		if not main.spell_banner.is_active():
			if old_spell:
				main.spell_banner.slide_in(old_spell)
			else:
				main.spell_banner.slide_in(spell)
