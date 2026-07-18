extends "res://source/autoload/game.gd"

var players:Dictionary[int,Dictionary]={}
var player_info = {
	name="Client",
	character="lexicographer",
	#damage=0,
}
signal player_connected(peer_id:int,player_info)
signal player_disconnected(peer_id:int)

func _init()->void:
	multiplayer.peer_connected.connect(_on_other_connected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
@rpc("call_local")
func start_game(run_seed:int, _difficulty:int):
	difficulty=_difficulty
	DailyManager.set_process(false)
	AudioManager.fade_music()
	AudioManager.fade_sounds()
	debug_run = false
	new_run_character = player_info.character
	new_run_seed = run_seed
	active_daily = null
	is_seeded = true
	loading_run_save = null
	get_tree().change_scene_to_file("res://mods/co-op/overrides/main.tscn")
	#start_run(player_info.character,run_seed)

func _on_connected()->void:
	var peer_id=multiplayer.get_unique_id()
	players[peer_id]=player_info
	player_connected.emit(peer_id,player_info)

func _on_other_connected(id:int)->void:
	if main==null:
		register_player.rpc_id(id,player_info)

func _on_peer_disconnected(id:int)->void:
	if id in players:
		players.erase(id)
		player_disconnected.emit(id)

@rpc("any_peer")
func register_player(other_player_info)->void:
	var id=multiplayer.get_remote_sender_id()
	players[id]=other_player_info
	player_connected.emit(id,other_player_info)
	
