extends MenuPanel

@export var lobby_player_scene:PackedScene
var player_blocks:Dictionary[int,Control]={}
#var character:="lexicographer"

func _ready() -> void:
	start_appearing.connect(_on_start_appearing)
	await get_tree().create_timer(.8).timeout
	Game.player_connected.connect(add_player)
	Game.player_disconnected.connect(remove_player)
	multiplayer.server_disconnected.connect(leave)
#func _on_start_appearing()->void:

func _on_start_appearing()->void:
	%Start.disabled=not multiplayer.is_server()

func add_player(id:int,player_info:Dictionary)->void:
	var block=lobby_player_scene.instantiate()
	block.set_player_info(player_info)
	%Players.add_child(block)
	player_blocks[id]=block

func remove_player(id:int)->void:
	var block=player_blocks[id]
	player_blocks.erase(id)
	block.queue_free()

func start_game():
	var run_seed=randi()
	Game.start_game.rpc(run_seed,Game.difficulty)

func disappear(instant: bool = false)->void:
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	for player_block in %Players.get_children():
		player_block.queue_free()
	player_blocks.clear()
	Game.players.clear()
	super(instant)

func leave()->void:
	menu_controller.back()
