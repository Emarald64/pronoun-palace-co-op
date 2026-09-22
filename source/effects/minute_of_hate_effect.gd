extends Node

var letter:=""

func set_parameters(parameters:Dictionary):
	letter=parameters.letter

func _ready():
	var tile:Tile=get_parent()
	
	if not letter.is_empty():
		tile.set_face(letter)
	tile.add_status(Globals.TileStatus.BOMB,1)
	tile.add_status("timed",60000)
	tile.add_poofcloud(tile.get_poof_color())
	
	queue_free()
