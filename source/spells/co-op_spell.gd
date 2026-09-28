class_name CoopSpell
extends Spell

var coop_notifications:CoopNotifications=main.coop_notifications
var coop_spell_effects:CoopSpellEffects=main.coop_spell_effects


func wait_for_reply_with_timeout(timeout:=10.0)->bool:
	main.get_tree().create_timer(timeout).timeout.connect(coop_spell_effects.request_replied.emit.bind(false))
	return await coop_spell_effects.request_replied

func post_generate_tooltip(tooltip:GameTooltip):
	var name_group=StringManager.get_string_group("mod/co-op/names")
	var credit:=""
	var group=get_string_group()
	if group.has_string("credit"):
		credit=group.get_string("credit")
	tooltip.add_subtooltip(name_group.strings.values().pick_random(),credit)

func do_battle_end_transformation():
	super()
	if secret_id in CoOp.GIFT_SPELLS:
		transform_spell(secret_id)

func player_turn_started(is_battle_start: bool) -> void :
	super(is_battle_start)
	if not is_battle_start and secret_id == CoOp.SPELLS.MIRACLE_CACHE_COOP:
		var spell_id=rng.spell.weighted_random(CoOp.SPELL_WEIGHTS)
		transform_spell(spell_id)
