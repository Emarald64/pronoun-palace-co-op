extends MenuPanel

@export var lobby:MenuPanel
var continuing_game:=false
var steam_networking:=false
var created_icons:=false
#var upnp:UPNP
const lobby_type_order=[
	Steam.LOBBY_TYPE_PRIVATE,
	Steam.LOBBY_TYPE_FRIENDS_ONLY,
	Steam.LOBBY_TYPE_PUBLIC,
]
const lobby_type_key:Dictionary[Steam.LobbyType,String]={
	Steam.LOBBY_TYPE_PRIVATE:"private",
	Steam.LOBBY_TYPE_FRIENDS_ONLY:"friends_only",
	Steam.LOBBY_TYPE_PUBLIC:"public",
}

var visibility_selector_icon_scene:PackedScene=load("res://mods/co-op/source/ui/menu/host/visibility_selector_icon.tscn")

func _ready() -> void:
	start_appearing.connect(_on_start_appearing)

func _on_start_appearing():
	%Steam.disabled=not Bridge.steam_initialized
	if Bridge.steam_initialized and not created_icons:
		var icons:Array[SelectorIcon]=[]
		for lobby_type in lobby_type_order:
			var icon=visibility_selector_icon_scene.instantiate()
			icon.set_lobby_type(lobby_type)
			icons.append(icon)
		%VisibilitySelector.set_icons(icons)
		%VisibilitySelector.selected_index=1
		created_icons=true

func host_pressed():
	AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
	if steam_networking:
		Steam.createLobby(%VisibilitySelector.get_selected_icon().lobby_type,%MaxPlayers.value)
		var responce=await Steam.lobby_created
		if responce[0]==Steam.Result.RESULT_OK:
			Game.steam_lobby_id=responce[1]
			Steam.setLobbyData(Game.steam_lobby_id,"co-op_version",CoOp.COOP_VERSION)
			Steam.setLobbyData(Game.steam_lobby_id,"difficulty",str(Game.difficulty))
			Steam.setLobbyData(Game.steam_lobby_id,"seed"," ")
			print("sucessfully created lobby with id ",Game.steam_lobby_id)
			var peer=SteamMultiplayerPeer.new()
			peer.server_relay=true
			peer.host_with_lobby(Game.steam_lobby_id)
			multiplayer.multiplayer_peer=peer
			go_to_lobby()
		else:
			push_error("Lobby creation error: ",responce[0])
			%Header.text="Lobby creation error, code: "+str(responce[0])
	else:
		print("starting enet hosting")
		var peer=ENetMultiplayerPeer.new()
		var server_error=peer.create_server(%Port.value,%MaxPlayers.value)
		if server_error==Error.OK:
			print("server created ok")
			if %ForwardPort.button_pressed:
				var upnp_error=Game.upnp.add_port_mapping(%Port.value,0,"Pronoun Palace coop")
				if upnp_error!=UPNP.UPNPResult.UPNP_RESULT_SUCCESS:
					push_error("UPnP port map failure: ",upnp_error)
				else:
					print("upnp port map success")
			multiplayer.multiplayer_peer=peer
			go_to_lobby()
		else:
			push_error("server creation error:", server_error)
			%Header.text=error_string(server_error)

func go_to_lobby():
	AudioManager.play_sound(Sounds.UI.FORWARD_PAPER)
	if %Name.text.is_empty():
		if Bridge.steam_initialized:
			Game.player_info.name=Bridge.get_username(Bridge.own_user_id)
		else:
			Game.player_info.name="Host"
	else:
		Game.player_info.name=%Name.text
	if steam_networking:
		Steam.setLobbyData(Game.steam_lobby_id,"name",Game.player_info.name)
	Game.players[1]=Game.player_info
	Game.all_player_names[1]=Game.player_info.name
	Game.player_connected.emit(1,Game.player_info)
	AudioManager.play_sound(Sounds.UI.FORWARD_PAPER)
	if continuing_game:
		#screen_wipe.wipe_in()
		#await screen_wipe.screen_covered
		Game.load_run(SaveManager.get_save().get_saved_run(true))
	else:
		menu_controller.set_menu(lobby)

func enable_upnp():
	Game.upnp=UPNP.new()
	var err=Game.upnp.discover()
	if err==UPNP.UPNP_RESULT_SUCCESS:
		print("UPnP discovery ok")
		%"UPnP Option".hide()
		%"UPnP Stuff".show()
	else:
		push_error("UPnP discovery error ",err)

func show_ip():
	%IP.text=Game.upnp.query_external_address()
	%ShowIPButton.hide()
	%IP.show()

func select_steam():
	steam_networking=true
	%IPSettings.hide()
	%SteamSettings.show()
	
func select_ip():
	steam_networking=false
	%IPSettings.show()
	%SteamSettings.hide()

func _on_visibility_selector_selected(icon:SelectorIcon):
	select_lobby_type(icon.lobby_type)

func select_lobby_type(type:Steam.LobbyType):
	%LobbyTypeHeader.key="/mod/co-op/menu/lobby_type/%s/name"%lobby_type_key[type]
	%LobbyTypeDescription.key="/mod/co-op/menu/lobby_type/%s/description"%lobby_type_key[type]
