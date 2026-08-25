extends Control

var pushed_off:=false
const tiles_to_move=12
var tween:Tween

func _on_game_state_updated():
	if Game.word_builder.tiles.size()>=tiles_to_move and not pushed_off:
		if tween:
			tween.kill()
		tween=get_tree().create_tween()
		tween.tween_property(self,"position",Vector2(-20,0),.2)
		pushed_off=true
		#position.x=-20
	if Game.word_builder.tiles.size()<tiles_to_move and pushed_off:
		if tween:
			tween.kill()
		tween=get_tree().create_tween()
		pushed_off=false
		tween.tween_property(self,"position",Vector2.ZERO,.2)
		#position.x=0
