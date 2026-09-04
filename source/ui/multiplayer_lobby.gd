extends MenuPanel

@export var lobby_player_scene:PackedScene
@export var character_select:Control
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
	%LobbyID.visible=Game.steam_lobby_id!=0
	if Game.steam_lobby_id:
		var lobby_id_array=PackedByteArray()
		lobby_id_array.resize(8)
		lobby_id_array.encode_u64(0,Game.steam_lobby_id)
		%LobbyID.text="Lobby ID: "+Marshalls.raw_to_base64(lobby_id_array)

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
	#if Game.steam_lobby_id and Steam.getLobbyOwner(Game.steam_lobby_id)==Bridge.own_user_id:
		#Steam.setLobbyData(Game.steam_lobby_id,"in_game","true")
	var run_seed=character_select.seed_button.get_seed()
	if run_seed==null:
		run_seed=randi()
	Game.start_game.rpc(run_seed,Game.difficulty)

func disappear(instant: bool = false)->void:
	for player_block in %Players.get_children():
		player_block.queue_free()
	player_blocks.clear()
	Game.players.clear()
	if Game.steam_lobby_id and multiplayer.is_server():
		Game.steam_lobby_id=0
		Steam.leaveLobby(Game.steam_lobby_id)
	if Game.upnp!=null:
		Game.upnp.delete_port_mapping(multiplayer.multiplayer_peer.host.get_local_port())
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	super(instant)

func leave()->void:
	menu_controller.back()
