class_name InputSanity

const REPLACEMENT_SPELLS=[
	"proverbpalace:datamosh",
	"fun_spells:H",
	Globals.SPELLS.REPLACEMENT_CHARACTER,
]

const ALL_CHARACTERS=Letters.ALPHABET+Letters.WILDCARD_CHARACTERS+[" "]


static func is_valid_face(face:String)->bool:
	for letter in face:
		if letter not in ALL_CHARACTERS:
			return false
	return true


#static func add_status_to_tile_data(tile_data:Dictionary,status:String):
	#tile_data.get_or_add("statuses",[]).append(status)


static func preprocess_tile_data(tile_data:Dictionary):
	if "statuses" in tile_data:
		# remove non-existant statuses
		for status in tile_data.statuses.keys():
			if not StatusRegistry.has_data(status):
				tile_data.statuses.erase(status)

static func process_tile_info(tile_data:TileInfo):
	if tile_data.face_info.slashed_faces.is_empty():
		if not tile_data.faces.all(is_valid_face):
			tile_data.add_status(Globals.TileStatus.ASH)
	else:
		if not Array(tile_data.face_info.slashed_faces).any(is_valid_face):
			tile_data.add_status(Globals.TileStatus.ASH)
	#else:
		#add_status_to_tile_data(tile_data,Globals.TileStatus.COAL)


static func process_spell_data(spell_data:Dictionary):
	if "id" not in spell_data or not SpellRegistry.has_data(spell_data.id):
		if "id" in spell_data:
			push_warning("recived spell ",spell_data.id," but no spell exists in this game")
		else:
			push_error("recived a spell without an id")
		for replacement_spell_id in REPLACEMENT_SPELLS:
			if SpellRegistry.has_data(replacement_spell_id):
				spell_data.id=replacement_spell_id
				if replacement_spell_id=="proverbpalace:datamosh":
					spell_data.faking_out=true
					spell_data.post_fakeout_charge=spell_data.max_charge
					spell_data.max_charge=0
				break


static func data_has_status(tile_data:Dictionary,status:String)->bool:
	return "statuses" in tile_data and status in tile_data.statuses
