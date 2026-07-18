class_name SpellLoader

static var spell_pool:Dictionary
static var spell_categories:Dictionary=Globals.SPELL_CATEGORIES.duplicate(true)

static func _static_init():
	add_vanillia_spells()
	load_random_charge_spells()

## Adds a spell to the list of spells that can appear randomly
## A higher weight makes the spell appear more often
## The catagory is used to determine whether it it will appear in the jubilist's boxes 
static func add_spell(id:String,weight:float=1.0,catagories=null)->void:
	spell_pool[id]=weight
	if catagories!=null:
		if catagories is String:
			spell_categories[catagories].append(id)
		elif catagories is Array or catagories is PackedStringArray:
			for catagory in catagories:
				spell_categories[catagory].append(id)
	print("added spell "+id)
	
static func add_vanillia_spells()->void:
	if spell_pool==null:
		spell_pool={}
	spell_pool.merge(Globals.SPELL_POOL)
	

static func load_random_charge_spells()->void:
	SpellData.random_charge_spells.clear()
	for spell in spell_pool:
		var group: = StringManager.get_string_group("spell/" + spell)
		if group.has_string("charge_characters"):
			SpellData.random_charge_spells.append(spell)
		else:
			var category: = group.get_string("charge_category")
			if category not in Globals.SPECIAL_CHARGES:
				SpellData.random_charge_spells.append(spell)
	print("loaded random charge spells") 
