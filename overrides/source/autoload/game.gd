extends "res://source/autoload/game.gd"

var players:Dictionary[int,Dictionary]={}
var player_info = {
	name="Client",
	character="lexicographer",
	steam_id=0
}
var upnp:UPNP
var sync_start:=false
signal player_connected(peer_id:int,player_info)
signal player_disconnected(peer_id:int)

func _ready() -> void:
	super()
	multiplayer.peer_connected.connect(_on_other_connected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if Bridge.own_user_id!=null:
		player_info.steam_id=Bridge.own_user_id
	Steam.screenshot_ready.connect(tag_screenshot)

	
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
	get_tree().change_scene_to_file("res://source/main.tscn")
	#start_run(player_info.character,run_seed)

@rpc
func load_joining_game(host_save:Dictionary)->void:
	var save=SaveManager.get_save().get_saved_run()
	loading_run_save=merge_saves(host_save,save)
	if loading_run_save==null:
		multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
		if main_menu!=null and main_menu.menu_controller!=null:
			if main_menu.menu_controller.currently_processing:
				await main_menu.menu_controller.done_processing
			main_menu.menu_controller.back()
		return
	if loading_run_save.metadata.character!=player_info.character:
		player_info.character=loading_run_save.metadata.character
		register_player.rpc(player_info)
	DailyManager.set_process(false)
	AudioManager.fade_music()
	AudioManager.fade_sounds()
	get_tree().change_scene_to_file("res://source/main.tscn")

func merge_saves(host_save:Dictionary,local_save:Dictionary):
	if host_save.metadata.seed==local_save.metadata.seed:
		host_save.metadata.character=local_save.metadata.character
		local_save.metadata=host_save.metadata
		local_save.data.enemy=host_save.data.enemy
		local_save.data.act_events=host_save.data.act_events
		return local_save

func _on_connected()->void:
	var peer_id=multiplayer.get_unique_id()
	players[peer_id]=player_info
	player_connected.emit(peer_id,player_info)

func _on_other_connected(id:int)->void:
	print(id, " connected")
	register_player.rpc_id(id,player_info)
	if main!=null and multiplayer.is_server():
		if enemy!=null and enemy.id=="nobody":
			multiplayer.disconnect_peer(id)
		else:
			load_joining_game.rpc_id(id,{metadata=main.get_save_metadata(),data=main.get_save_data()})

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

func tag_screenshot(screenshot_handle:int,result:Steam.Result):
	if result==Steam.Result.RESULT_OK and multiplayer.has_multiplayer_peer():
		for player_id in players:
			if player_id!=multiplayer.get_unique_id() and players[player_id].steam_id!=0:
				Steam.tagUser(screenshot_handle,players[player_id].steam_id)

func is_in_run():
	return super() and main!=null
