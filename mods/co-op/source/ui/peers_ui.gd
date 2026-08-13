extends Control

var pushed_off:=false
const tiles_to_move=12

func _on_game_state_updated():
	if Game.word_builder.tiles.size()>=tiles_to_move and not pushed_off:
		pushed_off=true
		position.x=-20
	if Game.word_builder.tiles.size()<tiles_to_move and pushed_off:
		pushed_off=false
		position.x=0
