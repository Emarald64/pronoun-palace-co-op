extends Control

var pushed_off:=false
const TILES_TO_MOVE=12
var tween:Tween

func _on_game_state_updated():
	if Game.word_builder.tiles.size()>=TILES_TO_MOVE and not pushed_off:
		if tween:
			tween.kill()
		tween=get_tree().create_tween()
		tween.tween_property(self,"position",Vector2(-20,0),.2)
		pushed_off=true
		#position.x=-20
	elif Game.word_builder.tiles.size()<TILES_TO_MOVE and pushed_off:
		if tween:
			tween.kill()
		tween=get_tree().create_tween()
		pushed_off=false
		tween.tween_property(self,"position",Vector2.ZERO,.2)
		#position.x=0
