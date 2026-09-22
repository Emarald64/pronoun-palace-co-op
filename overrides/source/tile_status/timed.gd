extends Status

var time_left:=60.0
var timer_label:DebossLabel

func _status_connect():
	timer_label=DebossLabel.new()
	timer_label.text="60"
	timer_label.font=preload("res://fonts/RobotoSlab-Bold.ttf")
	timer_label.font_size=5
	update_timer_color()
	
	tile.tile_sprite.add_child(timer_label)
	timer_label.position=Vector2(-11,2.125)
	tile.updated.connect(update_timer_color)

func update_timer_color():
	var set_color:=false
	for status in tile.statuses:
		if status in Globals.TILE_FACE_COLOR:
			timer_label.color=Globals.TILE_FACE_COLOR[status][tile.type]
			set_color=true
	if not set_color:
		for status in tile.statuses:
			if status in Globals.TILE_VALUE_COLOR:
				timer_label.color=Globals.TILE_VALUE_COLOR[status][tile.type]
	
	timer_label.deboss_color=tile.get_deboss_color()

func clear():
	timer_label.queue_free()

func apply(time:=3.0):
	time_left=time

func _process(delta:float):
	if time_left>0:
		time_left=maxf(time_left-delta,0.0)
		#print(time_left)
		timer_label.text=str(floori(time_left))
		if time_left<=0:
			time_out()

func time_out():
	await tile.word_builder.remove_tiles()
	var tile_board=tile.tile_board
	await tile_board.wait_for_idle_tiles()
	#if tile.has_status(TileStatus.BOMB):
		#await tile.get_status(TileStatus.BOMB).explode()
	tile_board.remove_tile(tile)
	tile_board.state_updated.connect(Game.player.recompose,ConnectFlags.CONNECT_ONE_SHOT)


func get_tooltip_context():
	return {time=int(time_left),bomb=tile.has_status(TileStatus.BOMB)}
