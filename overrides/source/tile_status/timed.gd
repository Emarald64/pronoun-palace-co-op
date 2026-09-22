extends Status

var time_left:=60000
var timer_label:DebossLabel
var timer:=GameTimer.new()

func _init(_id:String):
	super(_id)
	timer.stopped.connect(_on_timer_stopped)

func _status_connect():
	timer_label=DebossLabel.new()
	timer_label.text="60"
	timer_label.font=preload("res://fonts/RobotoSlab-Bold.ttf")
	timer_label.font_size=5
	update_timer_color()
	
	tile.tile_sprite.add_child(timer_label)
	timer_label.position=Vector2(-11,2.125)
	tile.updated.connect(update_timer_color)
	#timer.stopped.connect(_on_timer_stopped)

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

func apply(time:=60000):
	time_left=time
	if Game.main.is_player_turn:
		timer.start()
	update_label()

func _process(_delta:float):
	if timer.is_running():
		update_label()
		#print(timer.get_elapsed_time()," ", time_left)
		if time_left>0 and timer.get_remaining_time(time_left)<=0:
			time_left=0
			time_out()

func update_label():
	timer_label.text=str(timer.get_remaining_time(time_left)/1000)

func time_out():
	if tile.is_preview or tile.is_projectile:
		return
	await tile.word_builder.remove_tiles()
	var tile_board=tile.tile_board
	await tile_board.wait_for_idle_tiles()
	#if tile.has_status(TileStatus.BOMB):
		#await tile.get_status(TileStatus.BOMB).explode()
	tile_board.remove_tile(tile)
	tile_board.state_updated.connect(Game.player.recompose,ConnectFlags.CONNECT_ONE_SHOT)

func _on_timer_stopped(elapsed_time:int):
	time_left-=elapsed_time

func get_tooltip_context():
	return {time=time_left/1000,bomb=tile.has_status(TileStatus.BOMB)}

func get_save_data() -> Variant:
	return timer.get_remaining_time(time_left)

func load_save_data(save: Variant) -> void:
	time_left=save
	if Game.main.is_player_turn:
		timer.start()
	update_label()
