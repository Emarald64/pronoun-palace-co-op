extends AtlasTexture

func set_character(character:String,trans:=true):
	region.position.x=Globals.CHARACTER_ORDER.find(character)*34+1
	region.position.y=35 if trans else 1
