extends SSNSpell

var steam_id:=0

## Charge character for when the spell transforms back into the printer
var printer_charge_character:=""

func _use():
	await super()
	if charge==0:
		# transform back into the printer
		var printer=transform_spell(CoOp.SPELLS.SSN_PRINTER,true,true,true,false,true,
		func (ssn_printer:Spell):
			ssn_printer.last_ssn=steam_id
			ssn_printer.frame=frame
		)
		if not printer_charge_character.is_empty():
			printer.charge_character=printer_charge_character
			charge_container.update_charge_character(false)

func _first_spawn(is_transform: = false) -> void:
	_setup_ssn(steam_id)

	super._first_spawn(is_transform)

func get_texture(_spell_id: String = id) -> Texture2D:
	return load("res://arte/spells/ssn.png")

func get_tooltip_context():
	var context = super.get_tooltip_context()
	if (steam_id != Bridge.get_user_id()) and steam_id != null:
		var username: = Bridge.get_username(steam_id)
		if username != "":
			context.username = username

	return context

func get_save_data():
	var save = super.get_save_data()
	save.steam_id = steam_id
	save.printer_charge_character=printer_charge_character
	return save

func load_save_data(save):
	super(save)
	steam_id=save.steam_id
	printer_charge_character=save.printer_charge_character
	_setup_ssn(steam_id)


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
