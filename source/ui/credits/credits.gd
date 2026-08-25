extends Credits

func _ready() -> void:
	super()
	
	# adjust scroll animation
	var animation:=anim_player.get_animation("roll_credits")
	credits_container.reset_size()
	await get_tree().process_frame
	animation.track_set_key_value(1,1,Vector2(0,-credits_container.size.y-21))
	#print("adjusted scroll animation")
