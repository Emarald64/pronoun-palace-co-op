class_name InputSanity
extends Object

const REPLACEMENT_SPELLS=[
	"proverbpalace:datamosh",
	"fun_spells:H",
	Globals.SPELLS.REPLACEMENT_CHARACTER,
]

const ALL_CHARACTERS=Letters.ALPHABET+Letters.WILDCARD_CHARACTERS

static func is_valid_face(face:String)->bool:
	for letter in face:
		if letter not in ALL_CHARACTERS:
			return false
	return true

static func add_status_to_tile_data(tile_data:Dictionary,status:String):
	tile_data.get_or_add("statuses",[]).append(status)

static func process_tile_data(tile_data:Dictionary):
	if "faces" in tile_data:
		if tile_data.faces.is_empty():
			add_status_to_tile_data(tile_data,Globals.TileStatus.COAL)
		elif tile_data.faces.any(func (face:String)->bool:return face.is_empty()):
			add_status_to_tile_data(tile_data,Globals.TileStatus.COAL)
		elif not tile_data.faces.all(is_valid_face):
			add_status_to_tile_data(tile_data,Globals.TileStatus.ASH)
	elif "slashed_faces" in tile_data:
		if tile_data.slashed_faces.is_empty():
			add_status_to_tile_data(tile_data,Globals.TileStatus.COAL)
		if not tile_data.slashed_faces.any(is_valid_face):
			add_status_to_tile_data(tile_data,Globals.TileStatus.ASH)
	else:
		add_status_to_tile_data(tile_data,Globals.TileStatus.COAL)

static func process_spell_data(spell_data:Dictionary):
	if "id" not in spell_data or spell_data.id not in SpellData.spell_data:
		if "id" in spell_data:
			push_warning("recived spell ",spell_data.id," but no spell exists in this game")
		else:
			push_error("recived a spell without an id")
		for replacement_spell_id in REPLACEMENT_SPELLS:
			if replacement_spell_id in SpellData.spell_data:
				spell_data.id=replacement_spell_id
				break

static func get_mod_or_null(mod_id:String)->Mod:
	for mod:Mod in ModLoader.mod_scenes:
		if mod.mod_data.id==mod_id:
			return mod
	return null
