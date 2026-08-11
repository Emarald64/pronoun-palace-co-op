extends "res://source/autoload/game.gd"

var players:Dictionary[int,Dictionary]={}
var player_info = {
	name="Client",
	character="lexicographer",
	#damage=0,
}
var upnp:UPNP
signal player_connected(peer_id:int,player_info)
signal player_disconnected(peer_id:int)

func _ready() -> void:
	super()
	multiplayer.peer_connected.connect(_on_other_connected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	
@rpc("call_local")
func start_game(run_seed:int, _difficulty:int):
	print("starting game")
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
	get_tree().change_scene_to_file("res://mods/co-op/source/main.tscn")
	#start_run(player_info.character,run_seed)

@rpc
func load_joining_game(save_metadata:Dictionary,enemy_save,act_events)->void:
	save_metadata.character=player_info.character
	var save=SaveManager.get_save().get_saved_run()
	save.metadata=save_metadata
	save.data.act_events=act_events
	save.data.enemy=enemy_save
	DailyManager.set_process(false)
	AudioManager.fade_music()
	AudioManager.fade_sounds()
	loading_run_save = save
	get_tree().change_scene_to_file("res://mods/co-op/source/main.tscn")

func _on_connected()->void:
	var peer_id=multiplayer.get_unique_id()
	players[peer_id]=player_info
	player_connected.emit(peer_id,player_info)

func _on_other_connected(id:int)->void:
	print(id, " connected")
	register_player.rpc_id(id,player_info)
	if main!=null and multiplayer.is_server():
		if enemy.id=="nobody":
			multiplayer.disconnect_peer(id)
		var current_enemy_data
		if enemy!=null:
			current_enemy_data={id=enemy.id,save=enemy.get_save_data()}
		load_joining_game.rpc_id(id,main.get_save_metadata(),current_enemy_data,main.act_events)

func _on_peer_disconnected(id:int)->void:
	print(id, " disconnected")
	if id in players:
		players.erase(id)
		player_disconnected.emit(id)

@rpc("any_peer")
func register_player(other_player_info)->void:
	var id=multiplayer.get_remote_sender_id()
	players[id]=other_player_info
	player_connected.emit(id,other_player_info)
	
