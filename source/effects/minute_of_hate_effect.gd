extends Node

var letter:=""

func set_parameters(parameters:Dictionary):
	letter=parameters.letter

func _ready():
	var tile:Tile=get_parent()
	
	if not letter.is_empty():
		tile.set_face(letter)
	tile.add_status(Globals.TileStatus.BOMB,1 if Game.main.is_player_turn else 2)
	var time= 120000 if ModLoader.get_node("coop").extra_hate_time else 60000
	tile.add_status("timed",time)
	tile.add_poofcloud(tile.get_poof_color())
	
	queue_free()
